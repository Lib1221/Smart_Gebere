import 'dart:convert';
import 'dart:typed_data';

/// Represents a single disease detection result stored in history.
class DetectionEntry {
  final String id;
  final DateTime timestamp;
  final String result;
  final String? diseaseName;
  final double confidence; // 0.0 to 1.0
  final Uint8List? imageBytes;
  final bool isHealthy;

  DetectionEntry({
    required this.id,
    required this.timestamp,
    required this.result,
    this.diseaseName,
    required this.confidence,
    this.imageBytes,
    required this.isHealthy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'result': result,
        'diseaseName': diseaseName,
        'confidence': confidence,
        'imageBase64': imageBytes != null ? base64Encode(imageBytes!) : null,
        'isHealthy': isHealthy,
      };

  factory DetectionEntry.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['imageBase64'] != null) {
      try {
        bytes = base64Decode(json['imageBase64'] as String);
      } catch (_) {
        bytes = null;
      }
    }
    return DetectionEntry(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      result: json['result'] as String? ?? '',
      diseaseName: json['diseaseName'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      imageBytes: bytes,
      isHealthy: json['isHealthy'] as bool? ?? false,
    );
  }

  /// Extracts disease name from AI response text
  static String? extractDiseaseName(String text) {
    // Look for common patterns in AI response
    final patterns = [
      RegExp(r'\*\*Disease Name:\*\*\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'Disease Name:\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'Disease:\s*(.+?)(?:\n|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.toLowerCase() != 'none' && name.toLowerCase() != 'n/a') {
          return name;
        }
      }
    }
    return null;
  }

  /// Estimates confidence from AI response text
  static double estimateConfidence(String text) {
    final lowerText = text.toLowerCase();
    
    // High confidence indicators
    if (lowerText.contains('clearly') ||
        lowerText.contains('definitely') ||
        lowerText.contains('certainly') ||
        lowerText.contains('evident') ||
        lowerText.contains('obvious')) {
      return 0.9;
    }
    
    // Medium confidence indicators
    if (lowerText.contains('likely') ||
        lowerText.contains('appears to') ||
        lowerText.contains('seems to') ||
        lowerText.contains('probably')) {
      return 0.7;
    }
    
    // Low confidence indicators
    if (lowerText.contains('possibly') ||
        lowerText.contains('might') ||
        lowerText.contains('could be') ||
        lowerText.contains('unclear') ||
        lowerText.contains('uncertain')) {
      return 0.4;
    }
    
    // Check for healthy plant
    if (lowerText.contains('healthy') ||
        lowerText.contains('no disease') ||
        lowerText.contains('no signs')) {
      return 0.85;
    }
    
    // Default medium confidence
    return 0.6;
  }

  /// Checks if the result indicates a healthy plant
  static bool checkIfHealthy(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('healthy') ||
        lowerText.contains('no disease') ||
        lowerText.contains('no signs of disease') ||
        lowerText.contains('appears healthy') ||
        lowerText.contains('no visible symptoms');
  }
}

