import 'package:flutter/material.dart';

class CropDetailPage extends StatelessWidget {
  final Map<String, dynamic> cropData;

  const CropDetailPage({Key? key, required this.cropData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text(cropData['cropName'], style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCropInfo(cropData),
              const SizedBox(height: 20),
              _buildTimeline(cropData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropInfo(Map<String, dynamic> cropData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cropData['cropName'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cropData['stage'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> cropData) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cropData['weeks'].length,
      itemBuilder: (context, index) {
        var week = cropData['weeks'][index];
        bool isFirst = index == 0;
        bool isLast = index == cropData['weeks'].length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            transform: Matrix4.rotationX(0.05),
            decoration: BoxDecoration(
              color: isFirst || isLast
                  ? Colors.green.shade700
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: isFirst || isLast
                      ? Colors.white
                      : Colors.green.shade600,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Week ${week['week']}: ${week['stage']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFirst || isLast
                              ? Colors.white
                              : Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tasks: ${week['tasks'].join(', ')}",
                        style: TextStyle(
                          fontSize: 14,
                          color: isFirst || isLast
                              ? Colors.white
                              : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
