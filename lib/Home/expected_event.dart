import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class SlideableExpectedEvents extends StatefulWidget {
  const SlideableExpectedEvents({super.key});

  @override
  _SlideableExpectedEventsState createState() =>
      _SlideableExpectedEventsState();
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

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final String userId = user.uid;
      final DocumentSnapshot userDoc =
          await _firestore.collection('Farmers').doc(userId).get();

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

          if (today.isAfter(startDate.subtract(const Duration(days: 7))) &&
              today.isBefore(endDate.add(const Duration(days: 7)))) {
            filteredEvents.add({
              'name': crop['name'],
              'stage': week['stage'],
              'tasks': List<String>.from(week['tasks'] ?? []),
              'start_date': dateFormat.format(startDate), // Store start date
              'end_date': dateFormat.format(endDate), // Store end date
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
                        ? Colors.green.shade600
                        : Colors.green.shade200,
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

  Widget _buildCard(Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () => _showEventDialog(event),
      child: Container(
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
              child: Text(
                event['stage'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDialog(Map<String, dynamic> event) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.infoReverse,
      animType: AnimType.scale,
      title: event['name'],
      headerAnimationLoop: false,
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌿 Stage Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade400, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event['stage'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 📆 Date Range
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade400, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    "${event['start_date']} - ${event['end_date']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 📝 Task List (Uncompleted)
            const Text(
              "Tasks to Complete:",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: event['tasks'].map<Widget>((task) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.radio_button_unchecked,
                        color: Colors.green),
                    title: Text(
                      task,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      btnOkColor: Colors.green.shade700,
      btnOkText: "Close",
      btnOkOnPress: () {},
    ).show();
  }
}
