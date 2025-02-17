import 'package:flutter/material.dart';
import 'package:smart_gebere/Disease_page/DiseaseDetection.dart';
import 'package:smart_gebere/task_management/descrition.dart';

class TaskCreationSection extends StatelessWidget {
  const TaskCreationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgriculturePage(),
                  ),
                );
              },
              child: const TaskCard(
                title: 'Create Task',
                subtitle: 'Let AI Guide You',
                icon: Icons.add_circle_outline,
                color: Colors.green, // Set to green
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageAnalyzer(),
                  ),
                );
              },
              child: const TaskCard(
                title: 'Detect & Discover',
                subtitle: 'Add Image',
                icon: Icons.image,
                color: Colors.green, // Set to green
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 10, // Increased elevation for 3D effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounder corners
      child: Container(
        color: color,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
