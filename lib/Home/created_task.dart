import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/Home/cropdetailpage.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class SlideableCreatedTasks extends StatefulWidget {
  const SlideableCreatedTasks({super.key});

  @override
  State<SlideableCreatedTasks> createState() => _SlideableCreatedTasksState();
}

class _SlideableCreatedTasksState extends State<SlideableCreatedTasks> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  List<Map<String, dynamic>> cropsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCropsData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchCropsData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      DocumentSnapshot docSnapshot = await userDocRef.get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>?;
        var crops = data?['crops'] as List<dynamic>? ?? [];
        
        setState(() {
          cropsData = crops.map((crop) {
            var firstWeek = crop['weeks'] != null && (crop['weeks'] as List).isNotEmpty
                ? crop['weeks'][0]
                : null;

            var firstDate = firstWeek != null &&
                    firstWeek['date_range'] != null &&
                    (firstWeek['date_range'] as List).isNotEmpty
                ? DateTime.tryParse(firstWeek['date_range'][0])
                : null;

            int differenceInDays = 0;
            int progressPercentage = 0;
            if (firstDate != null) {
              differenceInDays = (DateTime.now().difference(firstDate).inDays).abs();
              progressPercentage = _calculateProgressPercentage(
                  crop['weeks'] as List<dynamic>? ?? [], differenceInDays);
            }

            return {
              'cropName': crop['name']?.toString() ?? 'Unknown Crop',
              'id': crop['id']?.toString() ?? '',
              'firstWeekDateRange': firstWeek != null ? firstWeek['date_range'] : [],
              'weeks': crop['weeks'] != null
                  ? (crop['weeks'] as List).map((week) => {
                        'week': week['week'],
                        'dateRange': week['date_range'],
                        'tasks': week['tasks'],
                        'stage': week['stage'],
                      }).toList()
                  : [],
              'daysSinceFirstPlanting': differenceInDays,
              'progressPercentage': progressPercentage,
            };
          }).toList().reversed.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          cropsData = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CreatedTasks] Error fetching crops: $e');
      setState(() => _isLoading = false);
    }
  }

  int _calculateProgressPercentage(List<dynamic> weeks, int differenceDate) {
    if (weeks.isEmpty) return 0;
    int totalDays = weeks.length * 7;
    double percentage = (differenceDate / totalDays) * 100;
    return percentage.clamp(0, 100).toInt();
  }

  Color _getProgressColor(int progress) {
    if (progress < 30) return const Color(0xFF4CAF50);
    if (progress < 70) return const Color(0xFF2196F3);
    return const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (cropsData.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: cropsData.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: _buildCropCard(cropsData[index]),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            cropsData.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grass,
              size: 40,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noCropsFound,
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

  Widget _buildCropCard(Map<String, dynamic> crop) {
    int daysSincePlanted = crop['daysSinceFirstPlanting'] ?? 0;
    int progressPercentage = crop['progressPercentage'] ?? 0;
    final progressColor = _getProgressColor(progressPercentage);
    final weeks = crop['weeks'] as List? ?? [];
    final currentStage = _getCurrentStage(weeks);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropDetailPage(event: crop),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B5E20),
              const Color(0xFF43A047),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.35),
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
              right: -30,
              top: -30,
              child: Icon(
                Icons.eco,
                size: 140,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Left side - Crop info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Crop name
                        Text(
                          crop['cropName'] ?? 'Crop',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Current stage badge
                        if (currentStage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentStage,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 10),
                        // Days info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$daysSincePlanted days',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right side - Progress
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: progressColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // Background circle
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              strokeWidth: 8,
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: progressPercentage / 100,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Percentage text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$progressPercentage%',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tap indicator
            Positioned(
              bottom: 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentStage(List weeks) {
    if (weeks.isEmpty) return '';
    final now = DateTime.now();
    for (var week in weeks) {
      final dateRange = week['dateRange'] as List<dynamic>?;
      if (dateRange != null && dateRange.length >= 2) {
        final start = DateTime.tryParse(dateRange[0].toString());
        final end = DateTime.tryParse(dateRange[1].toString());
        if (start != null && end != null) {
          if (now.isAfter(start.subtract(const Duration(days: 1))) &&
              now.isBefore(end.add(const Duration(days: 1)))) {
            return week['stage']?.toString() ?? '';
          }
        }
      }
    }
    return weeks.isNotEmpty ? (weeks.first['stage']?.toString() ?? '') : '';
  }
}
