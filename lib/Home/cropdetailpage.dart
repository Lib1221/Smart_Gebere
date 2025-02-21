import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:smart_gebere/Home/weeklydetailpage.dart';

class CropDetailPage extends StatelessWidget {
  final Map<String, dynamic> event; // Crop data with ID

  const CropDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: const Text("Crop Forecasting",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCropHeader(),
            const SizedBox(height: 20),
            _buildProgressBar(),
            const SizedBox(height: 20),
            _buildCropDetails(context),
            const SizedBox(height: 40),
            _buildDeleteButton(context), // Delete button
          ],
        ),
      ),
    );
  }

  // Crop Header Section
  Widget _buildCropHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event['cropName'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                "Days since first planting: ${event['daysSinceFirstPlanting']}",
                style: TextStyle(fontSize: 16, color: Colors.green.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Progress Bar Section
  Widget _buildProgressBar() {
    int progressPercentage = event['progressPercentage'];
    return Card(
      color: Colors.green.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Progress: $progressPercentage%',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.green.shade200,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Crop Details with Clickable Weeks
  Widget _buildCropDetails(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Development Stages',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800),
            ),
            const SizedBox(height: 12),
            ...event['weeks'].map<Widget>((week) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeekDetailPage(week: week),
                    ),
                  );
                },
                child: _buildWeekDetails(week),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Week Details Card
  Widget _buildWeekDetails(Map<String, dynamic> week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week ${week['week']} - ${week['dateRange']}',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap for details',
            style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  // Delete Crop Button
  Widget _buildDeleteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _showDeleteConfirmation(context),
        child: const Text("Delete Crop",
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }

  // Delete Crop Logic
  Future<void> _deleteCrop(BuildContext context, String cropId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSuccessPopup(context, "No authenticated user found. Please log in.",
            "Authentication Error");
        return;
      }

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      // Fetch the current crops array
      DocumentSnapshot userDoc = await userDocRef.get();
      if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>).containsKey('crops')) {
        _showSuccessPopup(context, "No crops found to delete.", "Delete Failed ❌");
        return;
      }

      List<dynamic> crops = List.from(userDoc['crops']);

      // Filter out the crop to be deleted
      crops.removeWhere((crop) => crop['id'] == cropId);

      if (crops.length == userDoc['crops'].length) {
        _showSuccessPopup(context, "Crop not found for deletion.", "Delete Failed ❌");
        return;
      }

      // Update the document with the new crops list
      await userDocRef.update({'crops': crops});

      _showSuccessPopup(context, "Crop deleted successfully.", "Success ✅");
    } catch (e) {
      _showSuccessPopup(context, "Failed to delete crop. Error: $e", "Delete Failed ❌");
    }
  }

  // Show confirmation dialog before deleting crop
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text(
              "Are you sure you want to delete this crop? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteCrop(context, event['id']); // Call delete function
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Success Popup function (SnackBar)
  void _showSuccessPopup(BuildContext context, String message, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
