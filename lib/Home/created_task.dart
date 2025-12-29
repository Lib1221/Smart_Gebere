import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_gebere/Home/cropdetailpage.dart';
import 'package:smart_gebere/geo_Location/wetherdata.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class SlideableCreatedTasks extends StatefulWidget {
  @override
  _SlideableCreatedTasksState createState() => _SlideableCreatedTasksState();
}

class _SlideableCreatedTasksState extends State<SlideableCreatedTasks> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  List<Map<String, dynamic>> cropsData = [];


  @override
  void initState() {
    super.initState();
    _fetchCropsData();
  }

  int calculateTotalWeeks(List<dynamic> weeks) {
    return weeks.length;
  }

  Future<void> _fetchCropsData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      DocumentSnapshot docSnapshot = await userDocRef.get();
      if (docSnapshot.exists) {
        var crops = docSnapshot['crops'] as List<dynamic>;
        setState(() {
          cropsData = crops
              .map((crop) {
                var firstWeek =
                    crop['weeks'] != null && crop['weeks'].isNotEmpty
                        ? crop['weeks'][0]
                        : null;

                var firstDate = firstWeek != null &&
                        firstWeek['date_range'] != null &&
                        firstWeek['date_range'].isNotEmpty
                    ? DateTime.parse(firstWeek['date_range'][0])
                    : null;

                int differenceInDays = 0;
                int progressPercentage = 0;
                if (firstDate != null) {
                  differenceInDays =
                      (DateTime.now().difference(firstDate).inDays).abs();
                  progressPercentage = calculateProgressPercentage(
                      crop['weeks'], differenceInDays);
                }

                return {
                  'cropName': crop['name'],
                  'id': crop['id'],
                  'firstWeekDateRange':
                      firstWeek != null ? firstWeek['date_range'] : [],
                  'weeks': crop['weeks'] != null
                      ? crop['weeks']
                          .map((week) => {
                                'week': week['week'],
                                'dateRange': week['date_range'],
                                'tasks': week['tasks'],
                              })
                          .toList()
                      : [],
                  'daysSinceFirstPlanting': differenceInDays,
                  'progressPercentage': progressPercentage, // Pass progress
                };
              })
              .toList()
              .reversed
              .toList();
        });
      } else {
        setState(() {
          cropsData = [];
        });
      }
    } catch (e) {}
  }

  int calculateProgressPercentage(List<dynamic> weeks, int differenceDate) {
    if (weeks.isEmpty || differenceDate == null) return 0;

    int totalDays = weeks.length * 7; // Total expected days based on weeks
    double percentage = (differenceDate / totalDays) * 100;
    percentage = percentage.clamp(0, 100); // Ensures it stays between 0 and 100

    return percentage.toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (cropsData.isEmpty) _buildEmptyState(),
        if (cropsData.isNotEmpty)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: cropsData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                var crop = cropsData[pageIndex];
                return _buildCard(crop);
              },
            ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            cropsData.length,
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
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Text(
        l10n.noCropsFound,
        style: TextStyle(fontSize: 18, color: Colors.green.shade700),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> event) {
    int daysSincePlanted = event['daysSinceFirstPlanting'];
    int progressPercentage = event['progressPercentage'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropDetailPage(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['cropName'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${AppLocalizations.of(context).days}: $daysSincePlanted',
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
            Expanded(
              flex: 2,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.6,
                      child: CircularProgressIndicator(
                        value: progressPercentage / 100,
                        backgroundColor: Colors.green.shade200,
                        color: Colors.white,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '$progressPercentage%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
