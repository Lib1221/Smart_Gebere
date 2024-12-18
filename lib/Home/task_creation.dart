
import 'package:flutter/material.dart';

class TaskCreationSection extends StatelessWidget {
  const TaskCreationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TaskCard(
          title: 'Create Task',
          subtitle: 'Let AI Guide You',
          icon: Icons.add_circle_outline,
          color: Colors.deepPurple.shade200,
        ),
        TaskCard(
          title: 'Detect & Discover',
          subtitle: 'Add Image',
          icon: Icons.image,
          color: Colors.deepPurple.shade300,
        ),
      ],
    );
  }
}

// Task Card
class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const TaskCard({super.key, 
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160,
        height: 140,
        color: color,
        padding: const EdgeInsets.all(8),
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

