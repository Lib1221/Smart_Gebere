import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeline_tile/timeline_tile.dart';

class WeekTask {
  final int week;
  final List<String> dateRange;
  final String stage;
  final List<String> tasks;
  final DateTime createdAt; // Manually handle created_at field

  WeekTask({
    required this.week,
    required this.dateRange,
    required this.stage,
    required this.tasks,
    required this.createdAt, // Ensure it's initialized
  });

  factory WeekTask.fromJson(Map<String, dynamic> json) {
    return WeekTask(
      week: json['week'],
      dateRange: List<String>.from(json['date_range']),
      stage: json['stage'],
      tasks: List<String>.from(json['tasks']),
      createdAt: (json['created_at'] != null)
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(), // Set to now if not available
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week': week,
      'date_range': dateRange,
      'stage': stage,
      'tasks': tasks,
      'created_at': createdAt.toIso8601String(), // Store as ISO string or other format
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

  @override
  void initState() {
    super.initState();
    fetchWeekTasks(widget.crop);
  }

  Future<void> fetchWeekTasks(String crop) async {
    try {
      final apiKey = dotenv.env['API_KEY'] ?? "";
      if (apiKey.isEmpty) throw Exception("API Key is missing!");

      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
      DateTime now = DateTime.now();
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
      Return a pure list of dictionaries.
      don't add before and after from it only return the list and dictionaries
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final List<dynamic> data = jsonDecode(response.text!);
        setState(() {
          weekTasks = data.map((task) => WeekTask.fromJson(task)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Empty response from AI model");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: ${e.toString()}";
        isLoading = false;
      });
    }
  }


Future<void> storeFarmingGuideForUser(List<WeekTask> farmingGuide, String cropName) async {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Uploading data... Please wait"),
          ],
        ),
      );
    },
  );

  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context); 
      _showSuccessPopup(
        "No authenticated user found. Please log in and try again.",
        "Authentication Error"
      );
      return;
    }

    String uid = user.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Get reference to the user's document in Firestore
    DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

    // Create a unique ID for the crop
    String cropId = FirebaseFirestore.instance.collection('Farmers').doc().id; // Unique ID for each crop

    // Prepare the crop data
    Map<String, dynamic> cropDataMap = {
      'id': cropId,  // Unique ID for the crop
      'name': cropName,
      'weeks': farmingGuide.map((week) => week.toMap()).toList(),
    };

    // Set the crops array directly to the document, whether it exists or not
    await userDocRef.set({
      'crops': FieldValue.arrayUnion([cropDataMap]), // Add new crop data to the array
    }, SetOptions(merge: true));

    Navigator.pop(context); 
    _showSuccessPopup(
      "You successfully uploaded your data for $cropName.",
      "Success ✅"
    );
  } catch (e) {
    Navigator.pop(context);
    _showSuccessPopup(
      "Failed to store data due to an error. Please try again later.\nError: $e",
      "Upload Failed ❌"
    );
  }
}

void _showSuccessPopup(String message, String title) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context); 
            },
          ),
        ],
      );
    },
  );
}


 
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plant It?'),
        content: const Text('Do you agree to proceed with planting this crop?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Disagree'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              storeFarmingGuideForUser(weekTasks, widget.crop);
              
            },
            child: const Text('Agree'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.crop} Planting Guide'),
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
                          'Plant It',
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
                                      'Week ${task.week}: ${task.stage}',
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
