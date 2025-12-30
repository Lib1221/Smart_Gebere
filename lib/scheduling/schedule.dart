import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<bool> taskCompletion;

  WeekTask({
    required this.week,
    required this.dateRange,
    required this.stage,
    required this.tasks,
    required this.createdAt,
    List<bool>? taskCompletion,
  }) : taskCompletion = taskCompletion ?? List.filled(tasks.length, false);

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

    final tasks = toStringList(json['tasks']);
    List<bool>? completion;
    if (json['task_completion'] is List) {
      completion = (json['task_completion'] as List)
          .map((e) => e == true)
          .toList();
    }

    return WeekTask(
      week: toInt(json['week']),
      dateRange: toStringList(json['date_range']),
      stage: (json['stage'] ?? '').toString(),
      tasks: tasks,
      createdAt: toDateTime(json['created_at']),
      taskCompletion: completion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week': week,
      'date_range': dateRange,
      'stage': stage,
      'tasks': tasks,
      'task_completion': taskCompletion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0;
    final completed = taskCompletion.where((c) => c).length;
    return completed / tasks.length;
  }

  bool get isCompleted => completionPercentage == 1.0;
  bool get hasStarted => taskCompletion.any((c) => c);
}

class CropPlantingScreen extends StatefulWidget {
  final String crop;
  final Map<String, dynamic>? fieldData;

  const CropPlantingScreen({super.key, required this.crop, this.fieldData});

  @override
  State<CropPlantingScreen> createState() => _CropPlantingScreenState();
}

class _CropPlantingScreenState extends State<CropPlantingScreen>
    with SingleTickerProviderStateMixin {
  List<WeekTask> weekTasks = [];
  bool isLoading = true;
  String errorMessage = '';
  late GenerativeModel model;
  int _selectedTab = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int? _expandedWeek;

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
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    initializeModel();
    fetchWeekTasks(widget.crop);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void initializeModel() {
    String apiKey = dotenv.env['API_KEY'] ?? '';
    final preferredModel = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception("API Key is missing. Please set it in the .env file.");
    }

    model = GenerativeModel(
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

  Future<void> _saveTaskProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'crop_progress_${widget.crop}';
      final data = weekTasks.map((w) => w.toMap()).toList();
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _loadTaskProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'crop_progress_${widget.crop}';
      final saved = prefs.getString(key);
      if (saved != null) {
        final List<dynamic> data = jsonDecode(saved);
        for (var savedTask in data) {
          final week = savedTask['week'];
          final completion = savedTask['task_completion'];
          if (week != null && completion != null) {
            final idx = weekTasks.indexWhere((w) => w.week == week);
            if (idx >= 0 && completion is List) {
              weekTasks[idx].taskCompletion = completion
                  .map((e) => e == true)
                  .toList();
            }
          }
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> fetchWeekTasks(String crop) async {
    try {
      final apiKey = dotenv.env['API_KEY'] ?? "";
      if (apiKey.isEmpty) throw Exception("API Key is missing!");

      DateTime now = DateTime.now();
      final language = await _aiLanguageName();
      
      // Build field info if available
      String fieldInfo = '';
      if (widget.fieldData != null) {
        final fd = widget.fieldData!;
        fieldInfo = '''
      **Field Information:**
      - Field Name: ${fd['name'] ?? 'Unnamed'}
      - Field Size: ${(fd['areaHectares'] as num?)?.toStringAsFixed(2) ?? 'Unknown'} hectares
      - Soil Type: ${fd['soilType'] ?? 'Unknown'}
      
      Please tailor the planting guide to this specific field size and soil type.
      ''';
      }
      
      String prompt = """
      You are an advanced agricultural assistant. Provide a week-by-week planting guide for **$crop** based on today's date **$now**. 
      $fieldInfo
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
        _animController.forward();
        await _loadTaskProgress();
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

  void _toggleTaskCompletion(int weekIndex, int taskIndex) {
    setState(() {
      weekTasks[weekIndex].taskCompletion[taskIndex] =
          !weekTasks[weekIndex].taskCompletion[taskIndex];
    });
    _saveTaskProgress();
  }

  double get _overallProgress {
    if (weekTasks.isEmpty) return 0;
    int totalTasks = 0;
    int completedTasks = 0;
    for (var week in weekTasks) {
      totalTasks += week.tasks.length;
      completedTasks += week.taskCompletion.where((c) => c).length;
    }
    return totalTasks > 0 ? completedTasks / totalTasks : 0;
  }

  int get _currentWeekIndex {
    final now = DateTime.now();
    for (int i = 0; i < weekTasks.length; i++) {
      final week = weekTasks[i];
      if (week.dateRange.length >= 2) {
        final start = DateTime.tryParse(week.dateRange[0]);
        final end = DateTime.tryParse(week.dateRange[1]);
        if (start != null && end != null) {
          if (now.isAfter(start.subtract(const Duration(days: 1))) &&
              now.isBefore(end.add(const Duration(days: 1)))) {
            return i;
          }
        }
      }
    }
    return 0;
  }

  Color _getStageColor(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('preparation') || lower.contains('ዝግጅት')) {
      return Colors.brown;
    } else if (lower.contains('planting') || lower.contains('sowing') || lower.contains('መዝራት')) {
      return Colors.green;
    } else if (lower.contains('growth') || lower.contains('vegetative') || lower.contains('እድገት')) {
      return Colors.lightGreen;
    } else if (lower.contains('flower') || lower.contains('አበባ')) {
      return Colors.pink;
    } else if (lower.contains('harvest') || lower.contains('ምርት')) {
      return Colors.orange;
    } else if (lower.contains('care') || lower.contains('maintenance')) {
      return Colors.blue;
    }
    return Colors.teal;
  }

  IconData _getStageIcon(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('preparation')) return Icons.construction;
    if (lower.contains('planting') || lower.contains('sowing')) return Icons.grass;
    if (lower.contains('growth') || lower.contains('vegetative')) return Icons.trending_up;
    if (lower.contains('flower')) return Icons.local_florist;
    if (lower.contains('harvest')) return Icons.agriculture;
    if (lower.contains('care') || lower.contains('maintenance')) return Icons.eco;
    return Icons.check_circle_outline;
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
        'progressPercentage': 0,
        'daysSinceFirstPlanting': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Include field data if available
      if (widget.fieldData != null) {
        cropDataMap['fieldId'] = widget.fieldData!['id'];
        cropDataMap['fieldName'] = widget.fieldData!['name'];
        cropDataMap['fieldAreaHectares'] = widget.fieldData!['areaHectares'];
        cropDataMap['soilType'] = widget.fieldData!['soilType'];
      }

      await userDocRef.set({
        'crops': FieldValue.arrayUnion([cropDataMap]),
      }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context);
      _showSuccessPopup(l10n.planSaved, l10n.uploadSuccessTitle);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSuccessPopup(
          "Failed to store data due to an error. Please try again later.\nError: $e",
          l10n.uploadFailedTitle);
    }
  }

  void _showSuccessPopup(String message, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.plantItQuestionTitle),
        content: Text(l10n.plantItQuestionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.disagree),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              storeFarmingGuideForUser(weekTasks, widget.crop);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.agree),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(AppLocalizations l10n) {
    final progress = _overallProgress;
    final totalTasks = weekTasks.fold<int>(0, (sum, w) => sum + w.tasks.length);
    final completedTasks = weekTasks.fold<int>(
        0, (sum, w) => sum + w.taskCompletion.where((c) => c).length);
    final currentWeek = _currentWeekIndex;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.crop,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.plantingProgress,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.calendar_today,
                label: l10n.currentWeek,
                value: '${currentWeek + 1}/${weekTasks.length}',
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.check_circle,
                label: l10n.completedTasks,
                value: '$completedTasks/$totalTasks',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab(AppLocalizations l10n) {
    final currentWeek = _currentWeekIndex;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: weekTasks.length,
        itemBuilder: (context, index) {
          final task = weekTasks[index];
          final isExpanded = _expandedWeek == index;
          final isCurrent = index == currentWeek;
          final stageColor = _getStageColor(task.stage);

          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.1,
            isFirst: index == 0,
            isLast: index == weekTasks.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 40,
              height: 40,
              indicator: Container(
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? Colors.green
                      : (isCurrent ? stageColor : Colors.grey[400]),
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: stageColor, width: 3)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: stageColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '${task.week}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            beforeLineStyle: LineStyle(
              color: index <= currentWeek ? Colors.green : Colors.grey[300]!,
              thickness: 3,
            ),
            afterLineStyle: LineStyle(
              color: index < currentWeek ? Colors.green : Colors.grey[300]!,
              thickness: 3,
            ),
            endChild: GestureDetector(
              onTap: () {
                setState(() {
                  _expandedWeek = isExpanded ? null : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrent
                      ? Border.all(color: stageColor, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: stageColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: stageColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStageIcon(task.stage),
                              color: stageColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.week} ${task.week}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  task.stage,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: stageColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Progress indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(task.completionPercentage * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: task.isCompleted
                                    ? Colors.green
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    // Date range
                    if (task.dateRange.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.dateRange.join(' - '),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.completionPercentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            task.isCompleted ? Colors.green : stageColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    // Expanded tasks
                    if (isExpanded) ...[
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tasksForWeek,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...task.tasks.asMap().entries.map((entry) {
                              final i = entry.key;
                              final t = entry.value;
                              final isCompleted = task.taskCompletion[i];

                              return InkWell(
                                onTap: () => _toggleTaskCompletion(index, i),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isCompleted
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCompleted
                                              ? Colors.green
                                              : Colors.white,
                                          border: Border.all(
                                            color: isCompleted
                                                ? Colors.green
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: isCompleted
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          t,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: isCompleted
                                                ? Colors.grey[600]
                                                : Colors.grey[800],
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ] else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarTab(AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.cropCalendar,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...weekTasks.map((week) {
            final stageColor = _getStageColor(week.stage);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: stageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'W${week.week}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: stageColor,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  week.stage,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      week.dateRange.join(' → '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: week.completionPercentage,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(stageColor),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${week.taskCompletion.where((c) => c).length}/${week.tasks.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: week.isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.circle_outlined, color: Colors.grey[400]),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.crop} ${l10n.plantingGuide}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          if (!isLoading && weekTasks.isNotEmpty)
            IconButton(
              onPressed: _showConfirmationDialog,
              icon: const Icon(Icons.save_rounded),
              tooltip: l10n.savePlan,
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    l10n.generatePlan,
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = '';
                            });
                            fetchWeekTasks(widget.crop);
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.regeneratePlan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildProgressOverview(l10n),
                    // Tab buttons
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(
                            label: l10n.timeline,
                            icon: Icons.timeline,
                            isSelected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                          _buildTabButton(
                            label: l10n.cropCalendar,
                            icon: Icons.calendar_month,
                            isSelected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedTab == 0
                            ? _buildTimelineTab(l10n)
                            : _buildCalendarTab(l10n),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: !isLoading && weekTasks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showConfirmationDialog,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.agriculture, color: Colors.white),
              label: Text(
                l10n.plantIt,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.green : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
