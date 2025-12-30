import 'package:flutter/foundation.dart';

/// Field entity representing a mapped farm field.
@immutable
class FieldEntity {
  final String id;
  final String name;
  final String soilType;
  final double areaHectares;
  final List<LatLngPoint> points;
  final DateTime createdAt;

  const FieldEntity({
    required this.id,
    required this.name,
    required this.soilType,
    required this.areaHectares,
    required this.points,
    required this.createdAt,
  });

  /// Area in acres (1 hectare = 2.471 acres)
  double get areaAcres => areaHectares * 2.471;

  /// Area in timad (Ethiopian unit, ~0.25 hectares)
  double get areaTimad => areaHectares * 4;

  /// Number of points/corners in the field boundary
  int get cornerCount => points.length;

  /// Whether the field has a valid boundary
  bool get hasValidBoundary => points.length >= 3;

  /// Get the center point of the field
  LatLngPoint? get centerPoint {
    if (points.isEmpty) return null;
    double sumLat = 0;
    double sumLng = 0;
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    return LatLngPoint(
      latitude: sumLat / points.length,
      longitude: sumLng / points.length,
    );
  }

  FieldEntity copyWith({
    String? id,
    String? name,
    String? soilType,
    double? areaHectares,
    List<LatLngPoint>? points,
    DateTime? createdAt,
  }) {
    return FieldEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      soilType: soilType ?? this.soilType,
      areaHectares: areaHectares ?? this.areaHectares,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Simple lat/lng point class
@immutable
class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
      };

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    return LatLngPoint(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLngPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

