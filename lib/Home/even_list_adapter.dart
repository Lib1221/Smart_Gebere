import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class Task {
  final String day; // e.g., "Wen"
  final String date; // e.g., "Feb 13"
  final String description;
  bool isCompleted;

  Task({
    required this.day,
    required this.date,
    required this.description,
    this.isCompleted = false,
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Create a list of tasks
  final List<Task> _tasks = [
    Task(day: 'Mon', date: 'Feb 11', description: 'Task for Monday just chill and do some stuff you want'),
    Task(day: 'Tue', date: 'Feb 12', description: 'Task for liben'),
    Task(day: 'Wen', date: 'Feb 13', description: 'Task for Wednesday'),
    Task(day: 'Thu', date: 'Feb 14', description: 'Task for Thursday'),
    Task(day: 'Fri', date: 'Feb 15', description: 'Task for Friday'),
    Task(day: 'Fri', date: 'Feb 15', description: 'Task for Friday'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timeline Page")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final Task task = _tasks[index];
          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.15,
            isFirst: index == 0,
            isLast: index == _tasks.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 40,
              height: 40,
              indicator: GestureDetector(
                onTap: () {
                  setState(() {
                    task.isCompleted = !task.isCompleted;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? Colors.green : Colors.white,
                    border: task.isCompleted
                        ? null
                        : Border.all(color: Colors.green, width: 2),
                  ),
                  child: Center(
                    child: task.isCompleted
                        ? const Icon(Icons.done, color: Colors.white)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.green),
                  ),
                ),
              ),
            ),
            beforeLineStyle: const LineStyle(
              color: Colors.green,
              thickness: 2,
            ),
            afterLineStyle: const LineStyle(
              color: Colors.green,
              thickness: 2,
            ),
            startChild: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.day,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    task.date,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            endChild: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}
