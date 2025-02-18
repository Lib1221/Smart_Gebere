import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    _fetchCropsData(); // Fetch crops data from Firestore
  }

  Future<void> _fetchCropsData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      // Fetch crop data for this user
      DocumentSnapshot docSnapshot = await userDocRef.get();
      if (docSnapshot.exists) {
        var crops = docSnapshot['crops'] as List<dynamic>;
        setState(() {
          cropsData = crops
              .map((crop) => {
                    'cropName': crop['name'],
                    'id': crop['id'],
                    'weeks': crop['weeks']
                        .map((week) => {
                              'week': week['week'],
                              'dateRange': week['date_range'],
                              'stage': week['stage'],
                              'tasks': week['tasks'],
                            })
                        .toList(),
                  })
              .toList();
          // Reverse the cropsData list
          cropsData = cropsData.reversed.toList();
        });
      } else {
        // Handle case where no crops are found (empty state)
        setState(() {
          cropsData = [];
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (cropsData.isEmpty)
          _buildEmptyState(), // Show empty state if no crops
        if (cropsData.isNotEmpty)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: (cropsData.length / 2)
                  .ceil(), // Divide by 2 to show 2 cards per page
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                var startIndex = pageIndex * 2;
                var crop1 = cropsData.length > startIndex
                    ? cropsData[startIndex]
                    : null;
                var crop2 = cropsData.length > startIndex + 1
                    ? cropsData[startIndex + 1]
                    : null;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (crop1 != null)
                      Expanded(
                        child: _buildCropCard(
                          crop1['cropName'],
                          crop1['weeks'],
                        ),
                      ),
                    if (crop2 != null)
                      Expanded(
                        child: _buildCropCard(
                          crop2['cropName'],
                          crop2['weeks'],
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
            (cropsData.length / 2)
                .ceil(), // Divide by 2 to show the correct number of dots
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 10,
              width: _currentPage == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Colors.green.shade600 // Green color
                    : Colors.green.shade200, // Lighter green
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper to build empty state when no crops are found
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No crops found. Please add crops.',
        style: TextStyle(
            fontSize: 18, color: Colors.green.shade700), // Green color
      ),
    );
  }
Widget _buildCropCard(String cropName, List<dynamic> weeks) {
  // Get the current week and total weeks
  int totalWeeks = weeks.length;
  int currentWeek = weeks.isNotEmpty ? weeks.last['week'] : 0;

  // Calculate the progress as a percentage
  double progress = totalWeeks > 0 ? (currentWeek / totalWeeks) * 100 : 0.0;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.2),
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          cropName,
          style: TextStyle(
            fontSize: 18, // Adjust font size to fit smaller layout
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900, // Green color
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // Circular progress indicator with dynamic progress value
        SizedBox(
          height: 30, // Smaller height for the circular progress
          width: 30,  // Smaller width for the circular progress
          child: CircularProgressIndicator(
            value: progress / 100, // Set the dynamic progress
            strokeWidth: 4, // Thinner stroke for even smaller progress indicator
            backgroundColor: Colors.green.shade200, // Light green background
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600), // Darker green color
          ),
        ),
        const SizedBox(height: 5),
        // Display the progress value inside the circular indicator
        Text(
          'Progress: ${progress.toStringAsFixed(1)}%', // Show progress as percentage
          style: TextStyle(
            fontSize: 14, // Reduced font size for progress text
            color: Colors.green.shade800, // Dark green color
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

 
 }
