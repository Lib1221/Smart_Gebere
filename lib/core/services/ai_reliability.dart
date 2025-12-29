import 'dart:convert';
import 'package:flutter/foundation.dart';

/// AI Reliability Layer
/// Provides JSON repair, validation, confidence scoring, and fallback templates.
class AIReliability {
  // ─────────────────────────────────────────────────────────────────────────
  // JSON Repair
  // ─────────────────────────────────────────────────────────────────────────

  /// Attempts to extract and repair JSON from AI response
  static Map<String, dynamic>? extractJson(String response) {
    // Try direct parse first
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (_) {}

    // Try to find JSON object in response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch != null) {
      try {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Try to repair common issues
    String cleaned = response;
    
    // Remove markdown code blocks
    cleaned = cleaned.replaceAll(RegExp(r'```json?\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');
    cleaned = cleaned.trim();
    
    // Fix trailing commas
    cleaned = cleaned.replaceAll(RegExp(r',(\s*[\}\]])'), r'$1');
    
    // Fix missing quotes on keys
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\{|\,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
      (m) => '${m.group(1)}"${m.group(2)}":',
    );
    
    // Try parsing repaired JSON
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {}

    debugPrint('[AIReliability] Failed to extract JSON from response');
    return null;
  }

  /// Extracts JSON array from response
  static List<dynamic>? extractJsonArray(String response) {
    // Try direct parse first
    try {
      return jsonDecode(response) as List<dynamic>;
    } catch (_) {}

    // Try to find JSON array in response
    final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
    if (arrayMatch != null) {
      try {
        return jsonDecode(arrayMatch.group(0)!) as List<dynamic>;
      } catch (_) {}
    }

    // Try to repair common issues
    String cleaned = response;
    cleaned = cleaned.replaceAll(RegExp(r'```json?\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');
    cleaned = cleaned.trim();
    cleaned = cleaned.replaceAll(RegExp(r',(\s*[\]\}])'), r'$1');

    try {
      return jsonDecode(cleaned) as List<dynamic>;
    } catch (_) {}

    debugPrint('[AIReliability] Failed to extract JSON array from response');
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────

  /// Validates crop suggestion data
  static Map<String, dynamic> validateCropSuggestion(Map<String, dynamic> raw) {
    return {
      'name': _asString(raw['name'], 'Unknown Crop'),
      'description': _asString(raw['description'], 'No description available'),
      'planting_season': _asString(raw['planting_season'] ?? raw['plantingSeason'], 'Year-round'),
      'growing_period': _asString(raw['growing_period'] ?? raw['growingPeriod'], '90-120 days'),
      'water_requirement': _asString(raw['water_requirement'] ?? raw['waterRequirement'], 'Moderate'),
      'soil_type': _asString(raw['soil_type'] ?? raw['soilType'], 'Well-drained'),
      'confidence': _asDouble(raw['confidence'], 0.7),
      'tips': _asList(raw['tips'], []),
      'warnings': _asList(raw['warnings'], []),
    };
  }

  /// Validates disease detection result
  static Map<String, dynamic> validateDiseaseResult(Map<String, dynamic> raw) {
    return {
      'disease_name': _asString(raw['disease_name'] ?? raw['diseaseName'] ?? raw['name'], 'Unknown'),
      'confidence': _asDouble(raw['confidence'], 0.5),
      'description': _asString(raw['description'], 'No description available'),
      'symptoms': _asList(raw['symptoms'], []),
      'treatment': _asString(raw['treatment'], 'Consult local agricultural expert'),
      'prevention': _asList(raw['prevention'], []),
      'severity': _asString(raw['severity'], 'Unknown'),
      'is_healthy': _asBool(raw['is_healthy'] ?? raw['isHealthy'], false),
    };
  }

  /// Validates week task data
  static Map<String, dynamic> validateWeekTask(Map<String, dynamic> raw) {
    return {
      'week': _asInt(raw['week'], 1),
      'title': _asString(raw['title'], 'Week Task'),
      'description': _asString(raw['description'], 'No description'),
      'tasks': _asList(raw['tasks'], []),
      'startDate': _asString(raw['startDate'], DateTime.now().toIso8601String()),
      'endDate': _asString(raw['endDate'], DateTime.now().add(const Duration(days: 7)).toIso8601String()),
    };
  }

  /// Validates market price data
  static Map<String, dynamic> validateMarketPrice(Map<String, dynamic> raw) {
    return {
      'crop': _asString(raw['crop'], 'Unknown'),
      'price': _asDouble(raw['price'], 0.0),
      'unit': _asString(raw['unit'], 'kg'),
      'currency': _asString(raw['currency'], 'ETB'),
      'market': _asString(raw['market'], 'Local'),
      'trend': _asString(raw['trend'], 'stable'), // up, down, stable
      'lastUpdated': _asString(raw['lastUpdated'], DateTime.now().toIso8601String()),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Confidence Scoring
  // ─────────────────────────────────────────────────────────────────────────

  /// Calculates confidence score based on response quality
  static double calculateConfidence(Map<String, dynamic> data, List<String> requiredFields) {
    if (data.isEmpty) return 0.0;
    
    int filledFields = 0;
    for (final field in requiredFields) {
      if (data[field] != null && data[field].toString().isNotEmpty) {
        filledFields++;
      }
    }
    
    return filledFields / requiredFields.length;
  }

  /// Returns confidence level label
  static String confidenceLabel(double confidence) {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Medium';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }

  /// Returns confidence color hex
  static int confidenceColorHex(double confidence) {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.6) return 0xFF8BC34A; // Light Green
    if (confidence >= 0.4) return 0xFFFFC107; // Amber
    if (confidence >= 0.2) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fallback Templates
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns fallback crop suggestions for Ethiopia
  static List<Map<String, dynamic>> fallbackCropSuggestions(String region) {
    return [
      {
        'name': 'Teff',
        'description': 'Ethiopia\'s staple grain, rich in nutrients and gluten-free.',
        'planting_season': 'June - August',
        'growing_period': '90-120 days',
        'water_requirement': 'Moderate',
        'soil_type': 'Clay loam',
        'confidence': 0.9,
        'tips': ['Plant after first heavy rains', 'Avoid waterlogged areas'],
        'warnings': ['Susceptible to lodging if over-fertilized'],
      },
      {
        'name': 'Wheat',
        'description': 'Major cereal crop grown in highland areas.',
        'planting_season': 'June - July',
        'growing_period': '100-130 days',
        'water_requirement': 'Moderate',
        'soil_type': 'Well-drained loam',
        'confidence': 0.85,
        'tips': ['Rotate with legumes', 'Apply nitrogen fertilizer at tillering'],
        'warnings': ['Watch for rust diseases'],
      },
      {
        'name': 'Maize',
        'description': 'Versatile crop for food and livestock feed.',
        'planting_season': 'March - May',
        'growing_period': '90-150 days',
        'water_requirement': 'High',
        'soil_type': 'Fertile, well-drained',
        'confidence': 0.85,
        'tips': ['Space rows 75cm apart', 'Apply manure before planting'],
        'warnings': ['Prone to fall armyworm'],
      },
      {
        'name': 'Coffee',
        'description': 'Ethiopia\'s most valuable export crop.',
        'planting_season': 'May - June',
        'growing_period': '3-4 years to first harvest',
        'water_requirement': 'Moderate',
        'soil_type': 'Deep, fertile, acidic',
        'confidence': 0.8,
        'tips': ['Plant under shade trees', 'Prune regularly'],
        'warnings': ['Coffee berry disease risk'],
      },
    ];
  }

  /// Returns fallback disease result
  static Map<String, dynamic> fallbackDiseaseResult() {
    return {
      'disease_name': 'Analysis Unavailable',
      'confidence': 0.0,
      'description': 'Unable to analyze the image. Please ensure good lighting and a clear view of the affected area.',
      'symptoms': [],
      'treatment': 'Consult your local agricultural extension officer.',
      'prevention': ['Regular field monitoring', 'Maintain crop hygiene'],
      'severity': 'Unknown',
      'is_healthy': false,
    };
  }

  /// Returns fallback market prices
  static List<Map<String, dynamic>> fallbackMarketPrices() {
    return [
      {'crop': 'Teff', 'price': 65.0, 'unit': 'kg', 'currency': 'ETB', 'market': 'Addis Ababa', 'trend': 'stable'},
      {'crop': 'Wheat', 'price': 40.0, 'unit': 'kg', 'currency': 'ETB', 'market': 'Addis Ababa', 'trend': 'up'},
      {'crop': 'Maize', 'price': 30.0, 'unit': 'kg', 'currency': 'ETB', 'market': 'Addis Ababa', 'trend': 'down'},
      {'crop': 'Sorghum', 'price': 35.0, 'unit': 'kg', 'currency': 'ETB', 'market': 'Addis Ababa', 'trend': 'stable'},
      {'crop': 'Coffee (Grade 1)', 'price': 350.0, 'unit': 'kg', 'currency': 'ETB', 'market': 'Addis Ababa', 'trend': 'up'},
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Type Converters
  // ─────────────────────────────────────────────────────────────────────────

  static String _asString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty ? fallback : value;
    return value.toString();
  }

  static int _asInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static List<dynamic> _asList(dynamic value, List<dynamic> fallback) {
    if (value == null) return fallback;
    if (value is List) return value;
    return fallback;
  }
}

