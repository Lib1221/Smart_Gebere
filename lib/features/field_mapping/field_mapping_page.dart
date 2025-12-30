import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FieldMappingPage extends StatefulWidget {
  const FieldMappingPage({super.key});

  @override
  State<FieldMappingPage> createState() => _FieldMappingPageState();
}

class _FieldMappingPageState extends State<FieldMappingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<LatLng> _fieldPoints = [];
  List<Map<String, dynamic>> _savedFields = [];
  bool _isRecording = false;
  bool _isLoading = true;
  Position? _currentPosition;
  double? _calculatedArea;
  String _fieldName = '';
  String _soilType = 'Loam';

  final List<String> _soilTypes = [
    'Loam',
    'Clay',
    'Sandy',
    'Silt',
    'Vertisol (Black Cotton)',
    'Nitosol (Red)',
    'Andosol',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadSavedFields();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint('[FieldMapping] Location error: $e');
    }
  }

  Future<void> _loadSavedFields() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('Farmers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final fields = data?['fields'] as List<dynamic>? ?? [];
        setState(() {
          _savedFields = fields.map((f) => Map<String, dynamic>.from(f)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[FieldMapping] Error loading fields: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCurrentPoint() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    // Get fresh position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _fieldPoints.add(LatLng(position.latitude, position.longitude));
        _currentPosition = position;
        if (_fieldPoints.length >= 3) {
          _calculatedArea = _calculatePolygonArea(_fieldPoints);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Point ${_fieldPoints.length} added'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    // Shoelace formula for polygon area
    double area = 0;
    int n = points.length;

    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      // Convert to meters using approximate conversion
      double x1 = points[i].longitude * 111320 * math.cos(points[i].latitude * math.pi / 180);
      double y1 = points[i].latitude * 110540;
      double x2 = points[j].longitude * 111320 * math.cos(points[j].latitude * math.pi / 180);
      double y2 = points[j].latitude * 110540;
      
      area += x1 * y2;
      area -= x2 * y1;
    }

    return (area.abs() / 2) / 10000; // Convert to hectares
  }

  Future<void> _saveField() async {
    if (_fieldPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 3 points to create a field')),
      );
      return;
    }

    if (_fieldName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a field name')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final field = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _fieldName,
        'soilType': _soilType,
        'areaHectares': _calculatedArea ?? 0,
        'points': _fieldPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('Farmers')
          .doc(user.uid)
          .set({
        'fields': FieldValue.arrayUnion([field]),
      }, SetOptions(merge: true));

      setState(() {
        _savedFields.add(field);
        _fieldPoints.clear();
        _fieldName = '';
        _calculatedArea = null;
        _isRecording = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field saved successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving field: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🗺️', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Text(
              'Field Mapping',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Location Card
                  _buildCurrentLocationCard(),
                  const SizedBox(height: 16),

                  // Recording Section
                  if (_isRecording) _buildRecordingSection(),

                  // Start Recording Button
                  if (!_isRecording)
                    _buildStartRecordingCard(),

                  const SizedBox(height: 24),

                  // Saved Fields
                  Text(
                    'My Fields',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_savedFields.isEmpty)
                    _buildEmptyFieldsCard()
                  else
                    ..._savedFields.map((field) => _buildFieldCard(field)),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5 + 0.5 * math.sin(_animController.value * 2 * math.pi)),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.my_location, color: Colors.white, size: 28),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (_currentPosition != null)
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Fetching location...',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.height, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Altitude: ${_currentPosition!.altitude.toStringAsFixed(0)}m',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStartRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_location_alt,
              color: Color(0xFF00695C),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Map Your Field',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Walk around your field boundaries and mark corner points to calculate the exact area',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isRecording = true),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Start Mapping',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Column(
      children: [
        // Field details input
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Field Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Field Name',
                  hintText: 'e.g., North Plot, Teff Field',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => _fieldName = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _soilType,
                decoration: InputDecoration(
                  labelText: 'Soil Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _soilTypes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _soilType = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Points & Area Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.place,
                    value: '${_fieldPoints.length}',
                    label: 'Points',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white30,
                  ),
                  _buildStatItem(
                    icon: Icons.square_foot,
                    value: _calculatedArea != null
                        ? '${_calculatedArea!.toStringAsFixed(2)}'
                        : '--',
                    label: 'Hectares',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white30,
                  ),
                  _buildStatItem(
                    icon: Icons.crop_square,
                    value: _calculatedArea != null
                        ? '${(_calculatedArea! * 2.471).toStringAsFixed(2)}'
                        : '--',
                    label: 'Acres',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Points list
        if (_fieldPoints.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boundary Points',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fieldPoints.asMap().entries.map((e) {
                    return Chip(
                      label: Text('P${e.key + 1}'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _fieldPoints.removeAt(e.key);
                          if (_fieldPoints.length >= 3) {
                            _calculatedArea = _calculatePolygonArea(_fieldPoints);
                          } else {
                            _calculatedArea = null;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addCurrentPoint,
                icon: const Icon(Icons.add_location),
                label: Text(
                  'Add Point',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _fieldPoints.length >= 3 ? _saveField : null,
                icon: const Icon(Icons.save),
                label: Text(
                  'Save Field',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _isRecording = false;
              _fieldPoints.clear();
              _calculatedArea = null;
              _fieldName = '';
            });
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFieldsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.map, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No fields mapped yet',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final area = field['areaHectares'] ?? 0.0;
    final points = field['points'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.terrain, color: Color(0xFF00695C), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field['name'] ?? 'Unnamed Field',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.grass, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      field['soilType'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.place, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${points.length} points',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(area as num).toStringAsFixed(2)} ha',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF00695C),
                ),
              ),
              Text(
                '${(area * 2.471).toStringAsFixed(2)} acres',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

