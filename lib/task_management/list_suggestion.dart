import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_gebere/Loading/loading.dart';
import 'package:smart_gebere/geo_Location/location.dart';
import 'package:smart_gebere/scheduling/schedule.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class CropListPage extends StatefulWidget {
  @override
  _CropListPageState createState() => _CropListPageState();
}

class _CropListPageState extends State<CropListPage> {
  final LocationService locationService = LocationService();
  List<Map<String, dynamic>> crops = [];
  bool isLoading = false;

  String _asString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    // If AI returns nested JSON (Map/List), keep it readable instead of crashing.
    try {
      if (v is Map || v is List) return jsonEncode(v);
    } catch (_) {}
    return v.toString();
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> _normalizeCrop(Map<String, dynamic> raw) {
    // Ensure the fields used by `CropCard` are the expected types.
    return {
      'name': _asString(raw['name']),
      'description': _asString(raw['description']),
      'suitability': _asInt(raw['suitability']),
      'details': _asString(raw['details']),
    };
  }

  Future<void> fetchCropSuggestions() async {
    if (!mounted) return; 

    setState(() => isLoading = true);

    try {
      locationService.initializeModel();
      Map<String, dynamic> locationData =
          await locationService.getCurrentLocation();
      List<Map<String, dynamic>> suggestions =
          await locationService.generateCropSuggestions(locationData);

      if (mounted) {
        setState(() {
          crops = suggestions.map(_normalizeCrop).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          crops = [];
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
    final l10n = AppLocalizations.of(context);
    return isLoading
        ? LoadingPage() 
        : Scaffold(
            appBar: AppBar(
              title: Text(
                l10n.appName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              centerTitle: true,
              backgroundColor: Colors.green,
              elevation: 5,
            ),
            body: crops.isEmpty
                ? Center(child: Text(l10n.noCropData))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: crops.length,
                    itemBuilder: (context, index) {
                      final crop = crops[index];
                      return CropCard(
                        name: crop['name'] as String,
                        description: crop['description'] as String,
                        suitability: crop['suitability'] as int,
                        details: crop['details'] as String,
                        crop: crop['name'] as String,
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
  final String crop;

  const CropCard({
    super.key,
    required this.name,
    required this.description,
    required this.suitability,
    required this.details,
     required this.crop,
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
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        side:
                            BorderSide(color: Colors.green.shade400, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 3,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CropPlantingScreen(
                                    crop: widget.crop,
                                  )),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context).lookSchedule,
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
