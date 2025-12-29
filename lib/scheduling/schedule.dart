import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:smart_gebere/settings/locale_store.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class WeekTask {
  final int week;
  final List<String> dateRange;
  final String stage;
  final List<String> tasks;
  final DateTime createdAt;

  WeekTask({
    required this.week,
    required this.dateRange,
    required this.stage,
    required this.tasks,
    required this.createdAt,
  });

  factory WeekTask.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime toDateTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return WeekTask(
      week: toInt(json['week']),
      dateRange: toStringList(json['date_range']),
      stage: (json['stage'] ?? '').toString(),
      tasks: toStringList(json['tasks']),
      createdAt: toDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week': week,
      'date_range': dateRange,
      'stage': stage,
      'tasks': tasks,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CropPlantingScreen extends StatefulWidget {
  final String crop;

  const CropPlantingScreen({required this.crop});

  @override
  _CropPlantingScreenState createState() => _CropPlantingScreenState();
}

class _CropPlantingScreenState extends State<CropPlantingScreen> {
  List<WeekTask> weekTasks = [];
  bool isLoading = true;
  String errorMessage = '';
  late GenerativeModel model;

  void _debugPrintAiResponse(String feature, String? text) {
    if (!kDebugMode) return;
    final safeText = (text ?? '').trim();
    final preview =
        safeText.length > 1200 ? '${safeText.substring(0, 1200)}…' : safeText;
    debugPrint('[$feature] AI response (${safeText.length} chars):\n$preview');
  }

  @override
  void initState() {
    super.initState();
    initializeModel();
    fetchWeekTasks(widget.crop);
  }

  void initializeModel() {
    String apiKey = dotenv.env['API_KEY'] ?? '';
    final preferredModel = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception("API Key is missing. Please set it in the .env file.");
    }

    model = GenerativeModel(
      // Prefer the newest model if available; can be overridden via .env (GEMINI_MODEL).
      model: preferredModel,
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<String> _aiLanguageName() async {
    final code = normalizeLocaleCode(await getLocaleStore().readLocaleCode());
    switch (code) {
      case 'am':
        return 'Amharic';
      case 'om':
        return 'Afaan Oromo';
      default:
        return 'English';
    }
  }

  Future<void> fetchWeekTasks(String crop) async {
    try {
      final apiKey = dotenv.env['API_KEY'] ?? "";
      if (apiKey.isEmpty) throw Exception("API Key is missing!");

      DateTime now = DateTime.now();
      final language = await _aiLanguageName();
      String prompt = """
      You are an advanced agricultural assistant. Provide a week-by-week planting guide for **$crop** based on today's date **$now**. 
      Ensure the output is **valid JSON format**, free from errors, markdown, or extra text. 
      Each week's data should include:
      - `week`: Week number.
      - `date_range`: Start and end date.
      - `stage`: Farming stage.
      - `tasks`: List of tasks for the week.

      Example JSON output:
      [
        {
          "week": 1,
          "date_range": ["2025-02-14", "2025-02-20"],
          "stage": "Land Preparation",
          "tasks": [
            "Test soil pH and adjust as necessary",
            "Plow the field to a depth of 15 cm",
            "Add organic compost to improve soil fertility"
          ]
        }
      ]

      **Output:**
      Remove any markdown formatting (e.g., triple backticks ``` and JSON syntax) from the given text while keeping the content structure intact. Output the result in plain text without any formatting symbols
don't make it markdown text

Return the list of dictionaries only. Do not include any additional text or information before or after the list.
      Return a pure list of dictionaries.
      also don't include any markdown text
      don't add before and after from it only return the list and dictionaries

Respond in $language.
      """;

      final content = [Content.text(prompt)];
      GenerateContentResponse response;
      try {
        response = await model.generateContent(content);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('is not found') || msg.contains('not supported')) {
          debugPrint('[CropPlan] Preferred model unavailable; falling back to gemini-1.5-flash. Error: $e');
          final apiKey = dotenv.env['API_KEY'] ?? '';
          model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: apiKey,
            safetySettings: [
              SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
              SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
            ],
          );
          response = await model.generateContent(content);
        } else {
          rethrow;
        }
      }
      _debugPrintAiResponse('CropPlan', response.text);

      if (response.text != null) {
        final List<dynamic> data = jsonDecode(response.text!);
        if (!mounted) return;
        setState(() {
          weekTasks = data
              .whereType<Map>()
              .map((task) => WeekTask.fromJson(Map<String, dynamic>.from(task)))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Empty response from AI model");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Error fetching data: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Future<void> storeFarmingGuideForUser(
      List<WeekTask> farmingGuide, String cropName) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(l10n.uploadingPleaseWait),
            ],
          ),
        );
      },
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pop(context);
        _showSuccessPopup(
            "No authenticated user found. Please log in and try again.",
            "Authentication Error");
        return;
      }

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      String cropId = FirebaseFirestore.instance.collection('Farmers').doc().id;

      Map<String, dynamic> cropDataMap = {
        'id': cropId,
        'name': cropName,
        'weeks': farmingGuide.map((week) => week.toMap()).toList(),
      };

      await userDocRef.set({
        'crops': FieldValue.arrayUnion([cropDataMap]),
      }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context);
      _showSuccessPopup(
          "You successfully uploaded your data for $cropName.", "Success ✅");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSuccessPopup(
          "Failed to store data due to an error. Please try again later.\nError: $e",
          "Upload Failed ❌");
    }
  }

  void _showSuccessPopup(String message, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.ok),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home_Screen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.plantItQuestionTitle),
        content: Text(l10n.plantItQuestionBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(l10n.disagree),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              storeFarmingGuideForUser(weekTasks, widget.crop);
            },
            child: Text(l10n.agree),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.crop} ${l10n.plantingGuide}'),
        backgroundColor: Colors.green[600],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      child: ElevatedButton(
                        onPressed: _showConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.plantIt,
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        itemCount: weekTasks.length,
                        itemBuilder: (context, index) {
                          final task = weekTasks[index];
                          return TimelineTile(
                            alignment: TimelineAlign.start,
                            isFirst: index == 0,
                            isLast: index == weekTasks.length - 1,
                            indicatorStyle: IndicatorStyle(
                              width: 24,
                              color: Colors.green.shade700,
                              indicatorXY: 0.5,
                            ),
                            beforeLineStyle: LineStyle(
                              color: Colors.green.shade400,
                              thickness: 4,
                            ),
                            endChild: Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l10n.week} ${task.week}: ${task.stage}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...task.tasks.map((t) => Padding(
                                          padding: const EdgeInsets.only(
                                              left: 10, top: 4),
                                          child: Text(
                                            '• $t',
                                            style: GoogleFonts.poppins(
                                                fontSize: 16),
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
