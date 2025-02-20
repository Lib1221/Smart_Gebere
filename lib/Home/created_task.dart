
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/Home/cropdetailpage.dart';

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
              .map((crop) => {
                    'cropName': crop['name'],
                    'id': crop['id'],
                    'plantingDate': crop['planting_date'],
                    'weeks': crop['weeks']
                        .map((week) => {
                              'week': week['week'],
                              'dateRange': week['date_range'],
                              'tasks': week['tasks'],
                            })
                        .toList(),
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

  int _calculateDaysSincePlanted(Timestamp? plantingDate) {
    if (plantingDate == null) return 0;
    DateTime plantDate = plantingDate.toDate();
    return DateTime.now().difference(plantDate).inDays;
  }

  double _calculateProgress(int daysSincePlanted, int totalDays) {
    return (daysSincePlanted / totalDays).clamp(0.0, 1.0);
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
                color: _currentPage == index ? Colors.green.shade600 : Colors.green.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No crops found. Please add crops.',
        style: TextStyle(fontSize: 18, color: Colors.green.shade700),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> event) {
    int daysSincePlanted = _calculateDaysSincePlanted(event['plantingDate']);
    int totalDays = 120; // Example total days, adjust accordingly based on crop

    double progress = _calculateProgress(daysSincePlanted, totalDays);
    String progressPercentage = (progress * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropDetailPage(cropData: event),
          ),
        );
      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['cropName'],
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
                    'Days: $daysSincePlanted',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.green.shade200,
                    color: Colors.white,
                    strokeWidth: 10,
                  ),
                  Text(
                    '$progressPercentage%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

}
