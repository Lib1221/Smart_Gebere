import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class SlideableExpectedEvents extends StatefulWidget {
  const SlideableExpectedEvents({super.key});

  @override
  State<SlideableExpectedEvents> createState() => _SlideableExpectedEventsState();
}

class _SlideableExpectedEventsState extends State<SlideableExpectedEvents> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  // Color palette for events
  final List<List<Color>> _gradients = [
    [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
    [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
    [const Color(0xFF00695C), const Color(0xFF4DB6AC)],
    [const Color(0xFFD32F2F), const Color(0xFFEF5350)],
  ];

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final String userId = user.uid;
      final DocumentSnapshot userDoc =
          await _firestore.collection('Farmers').doc(userId).get();

      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>?;
      final List<dynamic> crops = data?['crops'] ?? [];
      final DateTime today = DateTime.now();
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

      List<Map<String, dynamic>> filteredEvents = [];

      for (int cropIndex = 0; cropIndex < crops.length; cropIndex++) {
        final crop = crops[cropIndex];
        final weeks = crop['weeks'] as List<dynamic>? ?? [];
        
        for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
          final week = weeks[weekIndex];
          final List<dynamic> dateRangeRaw = week['date_range'] ?? [];
          if (dateRangeRaw.length < 2) continue;

          final List<String> dateRange = dateRangeRaw.map((e) => e.toString()).toList();
          final DateTime? startDate = DateTime.tryParse(dateRange[0]);
          final DateTime? endDate = DateTime.tryParse(dateRange[1]);

          if (startDate == null || endDate == null) continue;

          // Include events within 7 days window
          if (today.isAfter(startDate.subtract(const Duration(days: 7))) &&
              today.isBefore(endDate.add(const Duration(days: 7)))) {
            
            final tasks = (week['tasks'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ?? [];
            
            // Get completed tasks from Firebase
            final completedTasks = (week['completedTasks'] as List<dynamic>?)
                ?.map((t) => t as int)
                .toSet() ?? <int>{};

            filteredEvents.add({
              'cropId': crop['id']?.toString() ?? '',
              'cropIndex': cropIndex,
              'weekIndex': weekIndex,
              'name': crop['name']?.toString() ?? 'Unknown',
              'stage': week['stage']?.toString() ?? '',
              'tasks': tasks,
              'completedTasks': completedTasks,
              'start_date': dateFormat.format(startDate),
              'end_date': dateFormat.format(endDate),
              'daysLeft': endDate.difference(today).inDays,
              'isOngoing': today.isAfter(startDate) && today.isBefore(endDate),
            });
          }
        }
      }

      // Sort by closest date first
      filteredEvents.sort((a, b) {
        final aDate = DateTime.tryParse(a['start_date']) ?? DateTime.now();
        final bDate = DateTime.tryParse(b['start_date']) ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      return filteredEvents;
    } catch (e) {
      debugPrint('[ExpectedEvents] Error fetching events: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF57C00)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading events',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          );
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: events.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildEventCard(events[index], index);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                events.length > 5 ? 5 : events.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFFF57C00)
                        : const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              size: 40,
              color: Color(0xFFF57C00),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming events',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    final gradient = _gradients[index % _gradients.length];
    final daysLeft = event['daysLeft'] as int? ?? 0;
    final isOngoing = event['isOngoing'] as bool? ?? false;
    final tasks = event['tasks'] as List<dynamic>? ?? [];
    final completedTasks = event['completedTasks'] as Set<int>? ?? <int>{};
    final completedCount = completedTasks.length;
    final totalTasks = tasks.length;

    return GestureDetector(
      onTap: () => _showTaskDialog(event, gradient),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.event,
                size: 120,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOngoing
                                    ? Colors.greenAccent.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOngoing
                                    ? '🔥 Ongoing'
                                    : daysLeft > 0
                                        ? '📅 In $daysLeft days'
                                        : '✅ Completed',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Task progress indicator
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: totalTasks > 0 ? completedCount / totalTasks : 0,
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$completedCount/$totalTasks',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'done',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Stage info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 18,
                          color: gradient[0],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap to manage tasks',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: gradient[0],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDialog(Map<String, dynamic> event, List<Color> gradient) {
    final tasks = List<String>.from(event['tasks'] ?? []);
    Set<int> completedTasks = Set<int>.from(event['completedTasks'] ?? <int>{});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final completedCount = completedTasks.length;
          final totalTasks = tasks.length;
          final progress = totalTasks > 0 ? completedCount / totalTasks : 0.0;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['name'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event['stage'] ?? '',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Date range
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.date_range, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "${event['start_date']} - ${event['end_date']}",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tasks list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final isCompleted = completedTasks.contains(index);
                      
                      return GestureDetector(
                        onTap: () async {
                          // Toggle completion
                          setModalState(() {
                            if (isCompleted) {
                              completedTasks.remove(index);
                            } else {
                              completedTasks.add(index);
                            }
                          });
                          
                          // Save to Firebase
                          await _updateTaskCompletion(
                            event['cropIndex'] as int,
                            event['weekIndex'] as int,
                            completedTasks.toList(),
                          );
                          
                          // Refresh the main list
                          setState(() {
                            _eventsFuture = _fetchEvents();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? gradient[0].withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted
                                  ? gradient[0].withOpacity(0.3)
                                  : Colors.grey[200]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted ? gradient[0] : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted ? gradient[0] : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  boxShadow: isCompleted
                                      ? [
                                          BoxShadow(
                                            color: gradient[0].withOpacity(0.4),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              // Task text
                              Expanded(
                                child: Text(
                                  tasks[index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isCompleted ? Colors.grey[500] : Colors.grey[800],
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              // Task number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            // Mark all as complete
                            setModalState(() {
                              completedTasks = Set<int>.from(
                                List.generate(tasks.length, (i) => i),
                              );
                            });
                            await _updateTaskCompletion(
                              event['cropIndex'] as int,
                              event['weekIndex'] as int,
                              completedTasks.toList(),
                            );
                            setState(() {
                              _eventsFuture = _fetchEvents();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: gradient[0]),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Complete All',
                            style: GoogleFonts.poppins(
                              color: gradient[0],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gradient[0],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Done',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateTaskCompletion(
    int cropIndex,
    int weekIndex,
    List<int> completedTasks,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = _firestore.collection('Farmers').doc(user.uid);
      final doc = await docRef.get();
      
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final crops = List<Map<String, dynamic>>.from(
        (data['crops'] as List<dynamic>).map((c) => Map<String, dynamic>.from(c)),
      );

      if (cropIndex >= crops.length) return;

      final weeks = List<Map<String, dynamic>>.from(
        (crops[cropIndex]['weeks'] as List<dynamic>).map((w) => Map<String, dynamic>.from(w)),
      );

      if (weekIndex >= weeks.length) return;

      // Update completed tasks
      weeks[weekIndex]['completedTasks'] = completedTasks;
      crops[cropIndex]['weeks'] = weeks;

      // Recalculate overall progress
      int totalTasks = 0;
      int completedTotal = 0;
      for (var week in weeks) {
        final tasks = week['tasks'] as List<dynamic>? ?? [];
        final completed = week['completedTasks'] as List<dynamic>? ?? [];
        totalTasks += tasks.length;
        completedTotal += completed.length;
      }
      
      final progressPercentage = totalTasks > 0 
          ? ((completedTotal / totalTasks) * 100).round()
          : 0;
      crops[cropIndex]['progressPercentage'] = progressPercentage;

      await docRef.update({'crops': crops});
      
      debugPrint('[ExpectedEvents] Updated progress: $progressPercentage%');
    } catch (e) {
      debugPrint('[ExpectedEvents] Error updating task completion: $e');
    }
  }
}
