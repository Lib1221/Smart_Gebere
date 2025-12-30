import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/settings/app_settings.dart';

class YieldPredictionPage extends StatefulWidget {
  const YieldPredictionPage({super.key});

  @override
  State<YieldPredictionPage> createState() => _YieldPredictionPageState();
}

class _YieldPredictionPageState extends State<YieldPredictionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _crops = [];
  Map<String, dynamic>? _selectedCrop;
  bool _isLoading = true;
  bool _isPredicting = false;
  Map<String, dynamic>? _prediction;

  // Form controllers for manual entry
  final _landSizeController = TextEditingController(text: '1.0');
  String _landUnit = 'hectare';
  final _seedAmountController = TextEditingController();
  final _fertilizerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCrops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _landSizeController.dispose();
    _seedAmountController.dispose();
    _fertilizerController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
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
        final crops = data?['crops'] as List<dynamic>? ?? [];
        setState(() {
          _crops = crops.map((c) => Map<String, dynamic>.from(c)).toList();
          if (_crops.isNotEmpty) _selectedCrop = _crops.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[YieldPrediction] Error loading crops: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePrediction() async {
    if (_selectedCrop == null) return;

    setState(() => _isPredicting = true);

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('No API key');
      }

      final model = GenerativeModel(
        model: dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final cropName = _selectedCrop!['name'] ?? 'Unknown';
      final weeks = _selectedCrop!['weeks'] as List<dynamic>? ?? [];
      final landSize = double.tryParse(_landSizeController.text) ?? 1.0;

      final prompt = '''
You are an agricultural expert. Predict the yield for this Ethiopian crop:

Crop: $cropName
Land Size: $landSize $_landUnit
Growing Period: ${weeks.length} weeks
Seed Amount: ${_seedAmountController.text.isNotEmpty ? _seedAmountController.text : 'Standard amount'}
Fertilizer: ${_fertilizerController.text.isNotEmpty ? _fertilizerController.text : 'Standard application'}

Provide a JSON response with these exact fields:
{
  "estimated_yield_min": <number in kg>,
  "estimated_yield_max": <number in kg>,
  "yield_per_hectare": <number in kg>,
  "confidence_percentage": <number 0-100>,
  "factors_affecting_yield": ["factor1", "factor2", "factor3"],
  "recommendations": ["recommendation1", "recommendation2", "recommendation3"],
  "market_value_estimate_min": <number in ETB>,
  "market_value_estimate_max": <number in ETB>,
  "harvest_quality_prediction": "excellent/good/average/below_average",
  "optimal_harvest_timing": "description of when to harvest"
}

Base your predictions on typical Ethiopian agricultural conditions and $cropName characteristics.
Consider altitude, climate, and common practices.
Respond ONLY with valid JSON, no additional text.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Parse JSON from response
      final jsonStr = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      try {
        // Simple JSON parsing
        final Map<String, dynamic> parsed = {};
        
        // Extract values using regex
        final yieldMinMatch = RegExp(r'"estimated_yield_min"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(jsonStr);
        final yieldMaxMatch = RegExp(r'"estimated_yield_max"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(jsonStr);
        final yieldPerHaMatch = RegExp(r'"yield_per_hectare"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(jsonStr);
        final confidenceMatch = RegExp(r'"confidence_percentage"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(jsonStr);
        final valueMinMatch = RegExp(r'"market_value_estimate_min"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(jsonStr);
        final valueMaxMatch = RegExp(r'"market_value_estimate_max"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(jsonStr);
        final qualityMatch = RegExp(r'"harvest_quality_prediction"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
        final timingMatch = RegExp(r'"optimal_harvest_timing"\s*:\s*"([^"]+)"').firstMatch(jsonStr);

        parsed['estimated_yield_min'] = double.tryParse(yieldMinMatch?.group(1) ?? '0') ?? 0;
        parsed['estimated_yield_max'] = double.tryParse(yieldMaxMatch?.group(1) ?? '0') ?? 0;
        parsed['yield_per_hectare'] = double.tryParse(yieldPerHaMatch?.group(1) ?? '0') ?? 0;
        parsed['confidence_percentage'] = double.tryParse(confidenceMatch?.group(1) ?? '70') ?? 70;
        parsed['market_value_estimate_min'] = double.tryParse(valueMinMatch?.group(1) ?? '0') ?? 0;
        parsed['market_value_estimate_max'] = double.tryParse(valueMaxMatch?.group(1) ?? '0') ?? 0;
        parsed['harvest_quality_prediction'] = qualityMatch?.group(1) ?? 'good';
        parsed['optimal_harvest_timing'] = timingMatch?.group(1) ?? 'At maturity';

        // Extract arrays
        final factorsMatch = RegExp(r'"factors_affecting_yield"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(jsonStr);
        final recsMatch = RegExp(r'"recommendations"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(jsonStr);

        parsed['factors_affecting_yield'] = _extractStringArray(factorsMatch?.group(1));
        parsed['recommendations'] = _extractStringArray(recsMatch?.group(1));

        setState(() {
          _prediction = parsed;
          _isPredicting = false;
        });
      } catch (parseError) {
        // Fallback prediction
        setState(() {
          _prediction = {
            'estimated_yield_min': landSize * 1500,
            'estimated_yield_max': landSize * 2500,
            'yield_per_hectare': 2000,
            'confidence_percentage': 65,
            'market_value_estimate_min': landSize * 45000,
            'market_value_estimate_max': landSize * 75000,
            'harvest_quality_prediction': 'good',
            'optimal_harvest_timing': 'When crop reaches full maturity',
            'factors_affecting_yield': [
              'Weather conditions',
              'Soil quality',
              'Pest management',
            ],
            'recommendations': [
              'Monitor weather forecasts',
              'Apply fertilizer as scheduled',
              'Check for pests regularly',
            ],
          };
          _isPredicting = false;
        });
      }
    } catch (e) {
      debugPrint('[YieldPrediction] Error: $e');
      setState(() => _isPredicting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating prediction: $e')),
        );
      }
    }
  }

  List<String> _extractStringArray(String? content) {
    if (content == null) return [];
    final matches = RegExp(r'"([^"]+)"').allMatches(content);
    return matches.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
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
              child: const Text('📊', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Text(
              'Yield Prediction',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Predict'),
            Tab(text: 'Analytics'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPredictTab(),
          _buildAnalyticsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPredictTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Selection
          _buildSectionCard(
            title: 'Select Crop',
            icon: Icons.grass,
            color: const Color(0xFF4CAF50),
            child: _crops.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No crops found. Create a crop plan first.',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _crops.map((crop) {
                      final isSelected = _selectedCrop?['id'] == crop['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCrop = crop),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco,
                                size: 18,
                                color: isSelected ? Colors.white : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                crop['name'] ?? 'Crop',
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Land Size Input
          _buildSectionCard(
            title: 'Farm Details',
            icon: Icons.terrain,
            color: const Color(0xFF795548),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _landSizeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Land Size',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _landUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['hectare', 'acre', 'timad']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _landUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _seedAmountController,
                  decoration: InputDecoration(
                    labelText: 'Seed Amount (kg) - Optional',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fertilizerController,
                  decoration: InputDecoration(
                    labelText: 'Fertilizer Used - Optional',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Predict Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _crops.isEmpty || _isPredicting ? null : _generatePrediction,
              icon: _isPredicting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_graph),
              label: Text(
                _isPredicting ? 'Analyzing...' : 'Generate Prediction',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Prediction Results
          if (_prediction != null) ...[
            _buildPredictionResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionResults() {
    final yieldMin = _prediction!['estimated_yield_min'] ?? 0;
    final yieldMax = _prediction!['estimated_yield_max'] ?? 0;
    final confidence = _prediction!['confidence_percentage'] ?? 70;
    final valueMin = _prediction!['market_value_estimate_min'] ?? 0;
    final valueMax = _prediction!['market_value_estimate_max'] ?? 0;
    final quality = _prediction!['harvest_quality_prediction'] ?? 'good';
    final timing = _prediction!['optimal_harvest_timing'] ?? '';
    final factors = _prediction!['factors_affecting_yield'] as List<dynamic>? ?? [];
    final recommendations = _prediction!['recommendations'] as List<dynamic>? ?? [];

    Color qualityColor;
    switch (quality.toString().toLowerCase()) {
      case 'excellent':
        qualityColor = const Color(0xFF4CAF50);
        break;
      case 'good':
        qualityColor = const Color(0xFF8BC34A);
        break;
      case 'average':
        qualityColor = const Color(0xFFFF9800);
        break;
      default:
        qualityColor = const Color(0xFFF44336);
    }

    return Column(
      children: [
        // Main yield card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicted Yield',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_formatNumber(yieldMin)} - ${_formatNumber(yieldMax)} kg',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildResultStat(
                      label: 'Market Value',
                      value: '${_formatNumber(valueMin)} - ${_formatNumber(valueMax)} ETB',
                      icon: Icons.monetization_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Confidence meter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prediction Confidence',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${confidence.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (confidence as num) / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quality & Timing
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: qualityColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.star, color: qualityColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quality',
                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      quality.toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: qualityColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Optimal Harvest',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timing.toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Factors
        if (factors.isNotEmpty)
          _buildSectionCard(
            title: 'Factors Affecting Yield',
            icon: Icons.info_outline,
            color: const Color(0xFF9C27B0),
            child: Column(
              children: factors
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.purple[300]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                f.toString(),
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),

        // Recommendations
        if (recommendations.isNotEmpty)
          _buildSectionCard(
            title: 'Recommendations',
            icon: Icons.lightbulb_outline,
            color: const Color(0xFFFF9800),
            child: Column(
              children: recommendations.asMap().entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value.toString(),
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildResultStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    if (_crops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No crop data available',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Crop progress chart
          _buildSectionCard(
            title: 'Crop Progress Overview',
            icon: Icons.pie_chart,
            color: const Color(0xFF4CAF50),
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _crops.asMap().entries.map((e) {
                    final progress = e.value['progressPercentage'] ?? 50;
                    final colors = [
                      const Color(0xFF4CAF50),
                      const Color(0xFF2196F3),
                      const Color(0xFFFF9800),
                      const Color(0xFF9C27B0),
                      const Color(0xFFE91E63),
                    ];
                    return PieChartSectionData(
                      value: (progress as num).toDouble(),
                      title: '${e.value['name'] ?? 'Crop'}',
                      color: colors[e.key % colors.length],
                      radius: 80,
                      titleStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Crop list with progress
          ...(_crops.map((crop) {
            final progress = crop['progressPercentage'] ?? 0;
            final weeks = crop['weeks'] as List<dynamic>? ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.eco, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop['name'] ?? 'Crop',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${weeks.length} weeks planned',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (progress as num) / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Prediction History',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your past predictions will appear here',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.add),
            label: const Text('Make First Prediction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _formatNumber(dynamic num) {
    if (num == null) return '0';
    final n = num is int ? num.toDouble() : (num as double);
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toStringAsFixed(0);
  }
}

