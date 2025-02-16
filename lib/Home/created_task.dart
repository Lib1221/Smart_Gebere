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
          cropsData = crops.map((crop) => {
            'cropName': crop['name'],
            'id': crop['id'],
            'weeks': crop['weeks'].map((week) => {
              'week': week['week'],
              'dateRange': week['date_range'],
              'stage': week['stage'],
              'tasks': week['tasks'],
              'progress': 50, // Set default progress to 50%
            }).toList(),
          }).toList();
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
      print("Error fetching crops data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (cropsData.isEmpty)
          _buildEmptyState(),  // Show empty state if no crops
        if (cropsData.isNotEmpty)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: (cropsData.length / 2).ceil(), // Divide by 2 to show 2 cards per page
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                var startIndex = pageIndex * 2;
                var crop1 = cropsData.length > startIndex ? cropsData[startIndex] : null;
                var crop2 = cropsData.length > startIndex + 1 ? cropsData[startIndex + 1] : null;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (crop1 != null)
                      Expanded(
                        child: _buildCropCard(
                          crop1['cropName'],
                        ),
                      ),
                    if (crop2 != null)
                      Expanded(
                        child: _buildCropCard(
                          crop2['cropName'],
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
            (cropsData.length / 2).ceil(), // Divide by 2 to show the correct number of dots
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 10,
              width: _currentPage == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Colors.blue.shade600  // Changed to blue color
                    : Colors.blue.shade200, // Changed to lighter blue
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
        style: TextStyle(fontSize: 18, color: Colors.blue.shade700), // Changed to blue color
      ),
    );
  }

  // Helper to build crop cards with crop name and progress
  Widget _buildCropCard(String cropName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100, // Changed to blue color
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
            cropName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900, // Changed to blue color
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Circular progress indicator with dynamic progress value
          CircularProgressIndicator(
            value: 0.5,
            strokeWidth: 8,
            backgroundColor: Colors.blue.shade200, // Changed to blue color
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600), // Changed to blue color
          ),
          const SizedBox(height: 10),
          // Display the progress value inside the circular indicator
          Text(
            'Progress: ${(50).ceil()}%',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade800, // Changed to blue color
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
