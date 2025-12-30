import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  List<Map<String, dynamic>> savedFields = [];
  Map<String, dynamic>? selectedField;
  bool isLoading = false;
  bool isLoadingFields = true;
  bool showFieldSelection = true;

  String _asString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
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
    return {
      'name': _asString(raw['name']),
      'description': _asString(raw['description']),
      'suitability': _asInt(raw['suitability']),
      'details': _asString(raw['details']),
    };
  }

  @override
  void initState() {
    super.initState();
    _loadSavedFields();
  }

  Future<void> _loadSavedFields() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoadingFields = false);
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
          savedFields = fields.map((f) => Map<String, dynamic>.from(f)).toList();
          isLoadingFields = false;
        });
      } else {
        setState(() => isLoadingFields = false);
      }
    } catch (e) {
      debugPrint('[CropListPage] Error loading fields: $e');
      setState(() => isLoadingFields = false);
    }
  }

  Future<void> fetchCropSuggestions() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      showFieldSelection = false;
    });

    try {
      locationService.initializeModel();
      Map<String, dynamic> locationData =
          await locationService.getCurrentLocation();
      List<Map<String, dynamic>> suggestions =
          await locationService.generateCropSuggestions(
        locationData,
        fieldData: selectedField,
      );

      if (mounted) {
        setState(() {
          crops = suggestions.map(_normalizeCrop).toList();
        });
      }
    } catch (e) {
      debugPrint('[CropListPage] Error: $e');
      if (mounted) {
        setState(() {
          crops = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return LoadingPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: showFieldSelection
          ? _buildFieldSelectionScreen(l10n)
          : _buildCropList(l10n),
    );
  }

  Widget _buildFieldSelectionScreen(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Crop Recommendations',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Powered by AI & GPS',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a mapped field for more accurate recommendations, or use your current GPS location.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // My Fields section
          Text(
            'Select a Field (Optional)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          if (isLoadingFields)
            const Center(child: CircularProgressIndicator())
          else if (savedFields.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Map your fields in Field Mapping for better recommendations',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...savedFields.map((field) => _buildFieldOption(field)),

          const SizedBox(height: 24),

          // Use current location option
          GestureDetector(
            onTap: () {
              setState(() => selectedField = null);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedField == null
                    ? const Color(0xFF2E7D32).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedField == null
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Current GPS Location',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Get recommendations based on your current location',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedField == null)
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: fetchCropSuggestions,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                'Get AI Recommendations',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
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

  Widget _buildFieldOption(Map<String, dynamic> field) {
    final isSelected = selectedField?['id'] == field['id'];
    final area = (field['areaHectares'] as num?)?.toStringAsFixed(2) ?? '0';

    return GestureDetector(
      onTap: () {
        setState(() => selectedField = field);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2E7D32)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.terrain, color: Color(0xFF00695C)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field['name'] ?? 'Unnamed Field',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$area ha',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          field['soilType'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.brown[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCropList(AppLocalizations l10n) {
    return crops.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  l10n.noCropData,
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => showFieldSelection = true);
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Selected field info banner
              if (selectedField != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terrain, color: Color(0xFF00695C)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recommendations for: ${selectedField!['name']}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00695C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: crops.length,
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    return CropCard(
                      name: crop['name'] as String,
                      description: crop['description'] as String,
                      suitability: crop['suitability'] as int,
                      details: crop['details'] as String,
                      crop: crop['name'] as String,
                      selectedField: selectedField,
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class CropCard extends StatefulWidget {
  final String name;
  final String description;
  final int suitability;
  final String details;
  final String crop;
  final Map<String, dynamic>? selectedField;

  const CropCard({
    super.key,
    required this.name,
    required this.description,
    required this.suitability,
    required this.details,
    required this.crop,
    this.selectedField,
  });

  @override
  _CropCardState createState() => _CropCardState();
}

class _CropCardState extends State<CropCard> {
  bool _isExpanded = false;

  Color _getSuitabilityColor() {
    if (widget.suitability >= 80) return const Color(0xFF4CAF50);
    if (widget.suitability >= 60) return const Color(0xFF8BC34A);
    if (widget.suitability >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSuitabilityColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Main card content
          Container(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Suitability circle
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.suitability}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '%',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: color,
                      size: 30,
                    ),
                  ),
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                ),
              ],
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    widget.details,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CropPlantingScreen(
                              crop: widget.crop,
                              fieldData: widget.selectedField,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        AppLocalizations.of(context).lookSchedule,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
