import 'package:flutter/material.dart';

class SlideableCreatedTasks extends StatefulWidget {
  @override
  _SlideableCreatedTasksState createState() => _SlideableCreatedTasksState();
}

class _SlideableCreatedTasksState extends State<SlideableCreatedTasks> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  final List<Map<String, String>> tasks = [
    {'task': 'Task 1', 'progress': '20%'},
    {'task': 'Task 2', 'progress': '40%'},
    {'task': 'Task 3', 'progress': '60%'},
    {'task': 'Task 4', 'progress': '80%'},
    {'task': 'Task 5', 'progress': '100%'},
    {'task': 'Task 6', 'progress': '50%'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: (tasks.length / 2).ceil(), // Divide list into pages of 2
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final int firstTaskIndex = pageIndex * 2;
              final int secondTaskIndex = firstTaskIndex + 1;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First Card
                  Expanded(
                    child: _buildCard(
                      tasks[firstTaskIndex]['task']!,
                      tasks[firstTaskIndex]['progress']!,
                    ),
                  ),
                  SizedBox(width: 10),
                  // Second Card (check if exists)
                  if (secondTaskIndex < tasks.length)
                    Expanded(
                      child: _buildCard(
                        tasks[secondTaskIndex]['task']!,
                        tasks[secondTaskIndex]['progress']!,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 10),
        // Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            (tasks.length / 2).ceil(),
            (index) => AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 10,
              width: _currentPage == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Colors.teal.shade600
                    : Colors.teal.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper to build cards
  Widget _buildCard(String task, String progress) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            task,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            progress,
            style: TextStyle(
              fontSize: 18,
              color: Colors.teal.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}




// Created Task Card
class CreatedTaskCard extends StatelessWidget {
  final String progress;
  final String description;

  const CreatedTaskCard({super.key, required this.progress, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.teal.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              progress,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

