
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class SlideableExpectedEvents extends StatefulWidget {
  @override
  _SlideableExpectedEventsState createState() => _SlideableExpectedEventsState();
}

class _SlideableExpectedEventsState extends State<SlideableExpectedEvents> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  final List<Map<String, String>> events = [
    {'event': 'Event 1', 'time': '10:00 AM'},
    {'event': 'Event 2', 'time': '12:00 PM'},
    {'event': 'Event 3', 'time': '02:00 PM'},
    {'event': 'Event 4', 'time': '04:00 PM'},
    {'event': 'Event 5', 'time': '06:00 PM'},
    {'event': 'Event 6', 'time': '08:00 PM'},
    {'event': 'Adugna', 'time': '06:00 PM'},
    {'event': 'Liben', 'time': '08:00 PM'},
    
    
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: (events.length / 2).ceil(), 
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final int firstEventIndex = pageIndex * 2;
              final int secondEventIndex = firstEventIndex + 1;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First Card
                  Expanded(
                    child: _buildCard(
                      events[firstEventIndex]['event']!,
                      events[firstEventIndex]['time']!,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Second Card (check if exists)
                  if (secondEventIndex < events.length)
                    Expanded(
                      child: _buildCard(
                        events[secondEventIndex]['event']!,
                        events[secondEventIndex]['time']!,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            (events.length / 2).ceil(),
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildCard(String event, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            time,
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

class ExpectedEventCard extends StatelessWidget {
  final String eventName;

  const ExpectedEventCard({super.key, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.amber.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            eventName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
