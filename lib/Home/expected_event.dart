import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlideableExpectedEvents extends StatefulWidget {
  const SlideableExpectedEvents({super.key});

  @override
  _SlideableExpectedEventsState createState() => _SlideableExpectedEventsState();
}

class _SlideableExpectedEventsState extends State<SlideableExpectedEvents> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchEvents();
  }

  // 🔹 Fetches and filters crop events within ±7 days.
  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // No authenticated user, return an empty list or show an error.
        return [];
      }

      final String userId = user.uid;
      final DocumentSnapshot userDoc = await _firestore.collection('Farmers').doc(userId).get();

      if (!userDoc.exists) return [];

      final List<dynamic> crops = userDoc['crops'] ?? [];
      final DateTime today = DateTime.now();
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

      List<Map<String, dynamic>> filteredEvents = [];

      for (var crop in crops) {
        for (var week in crop['weeks']) {
          final List<String> dateRange = List<String>.from(week['date_range']);
          final DateTime startDate = dateFormat.parse(dateRange[0]);
          final DateTime endDate = dateFormat.parse(dateRange[1]);

          // 🔍 Check if the event falls within ±7 days of today
          if (today.isAfter(startDate.subtract(const Duration(days: 7))) &&
              today.isBefore(endDate.add(const Duration(days: 7)))) {
            filteredEvents.add({
              'name': crop['name'],
              'stage': week['stage'],
            });
          }
        }
      }

      return filteredEvents;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>( 
      future: _eventsFuture, 
      builder: (context, snapshot) { 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(child: Text("No Events Available"));
        }

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
                      Expanded(
                        child: _buildCard(events[firstEventIndex]),
                      ),
                      const SizedBox(width: 10),
                      if (secondEventIndex < events.length)
                        Expanded(
                          child: _buildCard(events[secondEventIndex]),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
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
      },
    );
  }

  // 🎨 Card UI to display event details without the tasks
Widget _buildCard(Map<String, dynamic> event) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green.shade600, Colors.green.shade300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.3),
          offset: const Offset(0, 6),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          event['name'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: double.infinity, // Ensures text takes available space
            child: Text(
              event['stage'],
              maxLines: 1, // Allows wrapping to next line
              overflow: TextOverflow.ellipsis, // Truncates if it exceeds 2 lines
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


}
