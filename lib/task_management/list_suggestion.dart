import 'package:flutter/material.dart';
import 'package:smart_gebere/Loading/fetch_loading.dart';
import 'package:smart_gebere/geo_Location/location.dart';

class CropListPage extends StatefulWidget {
  @override
  _CropListPageState createState() => _CropListPageState();
}

class _CropListPageState extends State<CropListPage> {
  final LocationService locationService = LocationService();
  List<Map<String, dynamic>> crops = [];
  bool isLoading = false;

  Future<void> fetchCropSuggestions() async {
    if (!mounted) return; // Prevent any updates if the widget is disposed

    setState(() => isLoading = true);

    try {
      locationService.initializeModel();
      Map<String, dynamic> locationData = await locationService.getCurrentLocation();
      List<Map<String, dynamic>> suggestions = await locationService.generateCropSuggestions(locationData);

      if (mounted) {
        setState(() {
          crops = suggestions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          crops = []; // Handle the error accordingly
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCropSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? LoadingPage() // Show Loading Page while data is loading
        : Scaffold(
            appBar: AppBar(
              title: const Text(
                'Agriculture Innovation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              centerTitle: true,
              backgroundColor: Colors.green,
              elevation: 5,
            ),
            body: crops.isEmpty
                ? const Center(child: Text("No crop data available."))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: crops.length,
                    itemBuilder: (context, index) {
                      return CropCard(
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
  final String name;
  final String description;
  final int suitability;
  final String details;

  const CropCard({
    super.key,
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
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
        ],
        color: Colors.white,
        border: Border.all(color: Colors.green.shade400, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Circular Suitability Indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${widget.suitability}%',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Crop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // Expand/Collapse Button
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.green,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.details,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  // Added button below detailed description
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green.shade400, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 3,
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Plantify",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
