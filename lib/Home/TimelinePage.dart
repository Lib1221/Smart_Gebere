import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.1,
            isFirst: true,
            indicatorStyle: IndicatorStyle(
              width: 40,
              height: 40,
              indicator: GestureDetector(
                onTap: () {
                  setState(() {
                    isCompleted = !isCompleted;
                  });
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.done, color: Colors.white)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.white),
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
                children: const [
                  Text(
                    'Wen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Feb 13',
                    style: TextStyle(fontSize: 14),
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
              child: const Text(
                'This is a description of the task. Tap the circle to mark it as done.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          // You can add more TimelineTile widgets here for additional tasks.
        ],
      ),
    );
  }
}
