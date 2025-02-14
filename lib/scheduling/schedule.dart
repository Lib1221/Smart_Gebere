import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CropPlantingScreen extends StatefulWidget {
  final String crop;

  CropPlantingScreen({required this.crop});

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
      print(now);
      String Prompt = """
      You are a highly advanced agricultural assistant, specializing in providing real-time, data-driven farming guides for growing **$crop**. Your task is to generate a **detailed, structured, step-by-step week-by-week farming guide** that includes all necessary stages, actions, and conditions for a successful harvest. 

- **Date Context:** Consider the current date **$now and adjust the planting calendar accordingly. Align each week's tasks with real-world farming timelines, reflecting seasonal changes and climatic conditions based on the current agricultural calendar.
  
- **Climatic and Environmental Considerations:** Account for real-time **weather patterns, soil types**, and **temperature ranges** to determine optimal planting, watering, and fertilization times.

- **Farming Stages:** Provide precise guidance for each week, covering essential farming stages such as:
  - **Land Preparation:** Including soil testing, plowing, and nutrient analysis.
  - **Sowing:** Seed selection, depth, and spacing.
  - **Watering & Irrigation:** Water needs, frequency, and best practices.
  - **Fertilization:** Type and quantity of fertilizers.
  - **Pest and Disease Control:** Recommended treatments and monitoring.
  - **Harvesting:** Timing, techniques, and equipment.
  - **Post-Harvest Handling:** Storage and processing guidelines.
  
- **Output Format:** The response should be in **error-free, structured JSON format** (no markdown or extra text) with the following fields for each week:
  - `week`: The specific week number.
  - `date_range`: The date range for that week based on the current date.
  - `stage`: The farming stage for that week.
  - `tasks`: A list of actionable tasks to complete during that week (in a clear, concise format).
  
Example of the JSON format:
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
-don't add at first these thing also ```json 
only return a list of dictionary no other thing 
notthing is only 
- **Real-Time Data Integration:** Consider and align your response with any dynamic conditions, like temperature forecasts, rainfall data, and soil moisture content, to enhance the guide's accuracy.
  
Ensure the output is in **valid JSON format**, error-free, and ready for easy parsing by other systems. Avoid using markdown text. Your goal is to provide an intuitive, actionable farming guide that can be implemented in real-world conditions with precision.

""";
      final content = [Content.text(Prompt)];

      final response = await model.generateContent(content);

      if (response.text != null) {
        print(response.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.crop} Planting Guide')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: weekTasks.length,
                  itemBuilder: (context, index) {
                    final task = weekTasks[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week ${task.week}: ${task.stage}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...task.tasks
                                .map((t) => Text('• $t',
                                    style: const TextStyle(fontSize: 16)))
                                .toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Model for parsing JSON response
class WeekTask {
  final int week;
  final String stage;
  final List<String> tasks;

  WeekTask({required this.week, required this.stage, required this.tasks});

  factory WeekTask.fromJson(Map<String, dynamic> json) {
    return WeekTask(
      week: json['week'],
      stage: json['stage'],
      tasks: List<String>.from(json['tasks']),
    );
  }
}
