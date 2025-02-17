import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_gebere/scheduling/schedule.dart';

class FarmingGuidePage extends StatefulWidget {
  @override
  _FarmingGuidePageState createState() => _FarmingGuidePageState();
}

class _FarmingGuidePageState extends State<FarmingGuidePage> {
  bool isLoading = false;
  List<WeekTask> farmingGuide = [];

  Future<void> retrieveFarmingGuideForUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        _showMessage("No authenticated user found. Please log in and try again.", "Authentication Error");
        return;
      }

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get reference to the user's document in Firestore
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      // Retrieve the user's document data
      DocumentSnapshot userDoc = await userDocRef.get();
      if (userDoc.exists) {
        // Retrieve the crops data
        List<dynamic> crops = userDoc['crops'] ?? [];

        // Convert each crop and its weeks to WeekTask objects
        List<WeekTask> allFarmingGuides = [];
        for (var crop in crops) {
          for (var week in crop['weeks']) {
            WeekTask weekTask = WeekTask.fromJson(week);
            // Check if the date range is within 7 days from today
            if (_isWithinRange(weekTask.dateRange)) {
              allFarmingGuides.add(weekTask);
            }
          }
        }

        setState(() {
          farmingGuide = allFarmingGuides;
        });
      }

      setState(() {
        isLoading = false;
      });
      _showMessage("Successfully retrieved farming guide.", "Success ✅");
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showMessage("Failed to retrieve data due to an error. Please try again later.\nError: $e", "Retrieval Failed ❌");
    }
  }

  // Function to check if the date range is within 7 days from now
  bool _isWithinRange(List<String> dateRange) {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime.parse(dateRange[0]);
    DateTime endDate = DateTime.parse(dateRange[1]);

    // Check if the current date is within ±7 days of the date range
    DateTime rangeStart = now.subtract(const Duration(days: 7));
    DateTime rangeEnd = now.add(const Duration(days: 7));

    return (startDate.isBefore(rangeEnd) && endDate.isAfter(rangeStart));
  }

  void _showMessage(String message, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farming Guide"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator() // Show loading indicator while retrieving
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: retrieveFarmingGuideForUser,
                    child: const Text("Retrieve Farming Guide"),
                  ),
                  if (farmingGuide.isNotEmpty) ...[
                    const Text("Farming Guide", style: TextStyle(fontSize: 20)),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: farmingGuide.length,
                        itemBuilder: (context, index) {
                          WeekTask weekTask = farmingGuide[index];
                          return ListTile(
                            title: Text("Week ${weekTask.week} - ${weekTask.stage}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date Range: ${weekTask.dateRange.join(' - ')}"),
                                Text("Tasks: ${weekTask.tasks.join(', ')}"),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

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
    return WeekTask(
      week: json['week'],
      dateRange: List<String>.from(json['date_range']),
      stage: json['stage'],
      tasks: List<String>.from(json['tasks']),
      createdAt: DateTime.parse(json['created_at']), // Parsing the string to DateTime
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week': week,
      'date_range': dateRange,
      'stage': stage,
      'tasks': tasks,
      'created_at': createdAt.toIso8601String(), // Convert DateTime to string when saving
    };
  }
}
