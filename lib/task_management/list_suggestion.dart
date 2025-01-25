
import 'package:flutter/material.dart';

class CropListPage extends StatelessWidget {
  final List<Map<String, dynamic>> crops = [
    {
      'image': 'assets/image_1.jpg', // Replace with your image paths
      'name': 'Wheat',
      'description': 'Ideal for regions with moderate climate.',
      'suitability': 85,
      'details':
          'Wheat thrives in areas with a temperature range of 10°C to 25°C and requires well-drained, fertile soil for optimal growth.',
    },
    {
      'image': 'assets/image_1.jpg',
      'name': 'Corn',
      'description': 'High yield potential in sunny areas.',
      'suitability': 50,
      'details':
          'Corn requires abundant sunlight and well-drained soil with high nitrogen content. Best suited for warm climates.',
    },
   
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crop Suitability List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: crops.length,
        itemBuilder: (context, index) {
          return CropCard(
            image: crops[index]['image'],
            name: crops[index]['name'],
            description: crops[index]['description'],
            suitability: crops[index]['suitability'],
            details: crops[index]['details'],
          );
        },
      ),
    );
  }
}

class CropCard extends StatefulWidget {
  final String image;
  final String name;
  final String description;
  final int suitability;
  final String details;

  const CropCard({
    super.key,
    required this.image,
    required this.name,
    required this.description,
    required this.suitability,
    required this.details,
  });

  @override
  _CropCardState createState() => _CropCardState();
}

class _CropCardState extends State<CropCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Colors.white, Colors.lightGreenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
         
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.image,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Crop details on the right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Linear Progress Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suitability: ${widget.suitability}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: widget.suitability / 100,
                          color: Colors.green,
                          backgroundColor: Colors.green.shade100,
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Expand/Collapse Button
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.details,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
