/// Market price model for crop price tracking
class MarketPrice {
  final String id;
  final String cropName;
  final double price;
  final String unit;
  final String currency;
  final String market;
  final String region;
  final PriceTrend trend;
  final double? changePercent;
  final DateTime recordedAt;
  final DateTime? previousRecordedAt;
  final double? previousPrice;
  
  // Quality grades
  final String? grade; // Grade 1, 2, 3 or A, B, C
  
  // Source
  final String source; // ECX, local, survey, etc.

  MarketPrice({
    required this.id,
    required this.cropName,
    required this.price,
    required this.unit,
    this.currency = 'ETB',
    required this.market,
    required this.region,
    required this.trend,
    this.changePercent,
    required this.recordedAt,
    this.previousRecordedAt,
    this.previousPrice,
    this.grade,
    this.source = 'Local Market',
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: _asString(json['id'], ''),
      cropName: _asString(json['cropName'] ?? json['crop'], ''),
      price: _asDouble(json['price'], 0.0),
      unit: _asString(json['unit'], 'kg'),
      currency: _asString(json['currency'], 'ETB'),
      market: _asString(json['market'], ''),
      region: _asString(json['region'], ''),
      trend: PriceTrend.fromString(_asString(json['trend'], 'stable')),
      changePercent: _asDoubleNullable(json['changePercent']),
      recordedAt: _asDateTime(json['recordedAt'] ?? json['lastUpdated']),
      previousRecordedAt: _asDateTimeNullable(json['previousRecordedAt']),
      previousPrice: _asDoubleNullable(json['previousPrice']),
      grade: json['grade'] as String?,
      source: _asString(json['source'], 'Local Market'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'price': price,
      'unit': unit,
      'currency': currency,
      'market': market,
      'region': region,
      'trend': trend.name,
      'changePercent': changePercent,
      'recordedAt': recordedAt.toIso8601String(),
      'previousRecordedAt': previousRecordedAt?.toIso8601String(),
      'previousPrice': previousPrice,
      'grade': grade,
      'source': source,
    };
  }

  /// Get formatted price string
  String get formattedPrice => '$currency ${price.toStringAsFixed(2)}/$unit';

  /// Get trend icon
  String get trendIcon {
    switch (trend) {
      case PriceTrend.up:
        return '↑';
      case PriceTrend.down:
        return '↓';
      case PriceTrend.stable:
        return '→';
    }
  }

  /// Get trend color hex
  int get trendColorHex {
    switch (trend) {
      case PriceTrend.up:
        return 0xFF4CAF50; // Green
      case PriceTrend.down:
        return 0xFFF44336; // Red
      case PriceTrend.stable:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Helper converters
  static String _asString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _asDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _asDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

enum PriceTrend {
  up('Up'),
  down('Down'),
  stable('Stable');

  final String displayName;
  const PriceTrend(this.displayName);

  static PriceTrend fromString(String value) {
    return PriceTrend.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PriceTrend.stable,
    );
  }
}

/// Price history for charting
class PriceHistory {
  final String cropName;
  final List<PricePoint> points;

  PriceHistory({required this.cropName, required this.points});

  factory PriceHistory.fromPrices(String cropName, List<MarketPrice> prices) {
    final sorted = List<MarketPrice>.from(prices)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    
    return PriceHistory(
      cropName: cropName,
      points: sorted.map((p) => PricePoint(date: p.recordedAt, price: p.price)).toList(),
    );
  }

  double get averagePrice {
    if (points.isEmpty) return 0;
    return points.map((p) => p.price).reduce((a, b) => a + b) / points.length;
  }

  double get minPrice {
    if (points.isEmpty) return 0;
    return points.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (points.isEmpty) return 0;
    return points.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  double get volatility {
    if (points.length < 2) return 0;
    final avg = averagePrice;
    final variance = points.map((p) => (p.price - avg) * (p.price - avg)).reduce((a, b) => a + b) / points.length;
    return variance > 0 ? (variance * 100 / (avg * avg)) : 0; // Coefficient of variation
  }
}

class PricePoint {
  final DateTime date;
  final double price;

  PricePoint({required this.date, required this.price});
}

/// Selling recommendation
class SellRecommendation {
  final String cropName;
  final String recommendation; // sell_now, hold, wait
  final String reason;
  final double confidenceScore;
  final DateTime generatedAt;

  SellRecommendation({
    required this.cropName,
    required this.recommendation,
    required this.reason,
    required this.confidenceScore,
    required this.generatedAt,
  });

  String get displayRecommendation {
    switch (recommendation) {
      case 'sell_now':
        return 'Sell Now';
      case 'hold':
        return 'Hold';
      case 'wait':
        return 'Wait for Better Price';
      default:
        return 'Unknown';
    }
  }

  int get colorHex {
    switch (recommendation) {
      case 'sell_now':
        return 0xFF4CAF50; // Green
      case 'hold':
        return 0xFFFFC107; // Amber
      case 'wait':
        return 0xFF2196F3; // Blue
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}

