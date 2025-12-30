import 'package:flutter/foundation.dart';
import 'crop_entity.dart';
import 'field_entity.dart';

/// Farmer entity representing a farmer's profile and data.
@immutable
class FarmerEntity {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? region;
  final List<CropEntity> crops;
  final List<FieldEntity> fields;
  final DateTime? createdAt;

  const FarmerEntity({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.region,
    this.crops = const [],
    this.fields = const [],
    this.createdAt,
  });

  /// Total number of active crops
  int get activeCropsCount => crops.length;

  /// Total number of mapped fields
  int get fieldsCount => fields.length;

  /// Total area of all fields in hectares
  double get totalAreaHectares =>
      fields.fold(0.0, (sum, field) => sum + field.areaHectares);

  /// Get total tasks across all crops
  int get totalTasks => crops.fold(
      0, (sum, crop) => sum + crop.weeks.fold(0, (s, w) => s + w.tasks.length));

  /// Get completed tasks across all crops
  int get completedTasks => crops.fold(
      0,
      (sum, crop) =>
          sum + crop.weeks.fold(0, (s, w) => s + w.completedTasks.length));

  /// Overall progress percentage
  double get overallProgress =>
      totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  FarmerEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? region,
    List<CropEntity>? crops,
    List<FieldEntity>? fields,
    DateTime? createdAt,
  }) {
    return FarmerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      crops: crops ?? this.crops,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmerEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

