import 'package:flutter/foundation.dart';
import 'week_entity.dart';

/// Crop entity representing a planted crop with its schedule.
@immutable
class CropEntity {
  final String id;
  final String name;
  final List<WeekEntity> weeks;
  final int progressPercentage;
  final int daysSinceFirstPlanting;
  final DateTime createdAt;
  final String? fieldId;
  final String? fieldName;
  final double? fieldAreaHectares;
  final String? soilType;

  const CropEntity({
    required this.id,
    required this.name,
    required this.weeks,
    this.progressPercentage = 0,
    this.daysSinceFirstPlanting = 0,
    required this.createdAt,
    this.fieldId,
    this.fieldName,
    this.fieldAreaHectares,
    this.soilType,
  });

  /// Total number of weeks in the plan
  int get totalWeeks => weeks.length;

  /// Current week number (1-indexed)
  int get currentWeek {
    final now = DateTime.now();
    for (int i = 0; i < weeks.length; i++) {
      if (weeks[i].isCurrentWeek(now)) {
        return i + 1;
      }
    }
    // If past all weeks, return last week
    return weeks.length;
  }

  /// Total tasks across all weeks
  int get totalTasks =>
      weeks.fold(0, (sum, week) => sum + week.tasks.length);

  /// Completed tasks across all weeks
  int get completedTasks =>
      weeks.fold(0, (sum, week) => sum + week.completedTasks.length);

  /// Calculated progress percentage
  double get calculatedProgress =>
      totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  /// Current stage name
  String get currentStage {
    if (weeks.isEmpty) return 'Not started';
    final now = DateTime.now();
    for (final week in weeks) {
      if (week.isCurrentWeek(now)) {
        return week.stage;
      }
    }
    return weeks.last.stage;
  }

  /// Whether the crop plan is complete
  bool get isComplete => progressPercentage >= 100;

  /// Weeks remaining in the plan
  int get weeksRemaining => totalWeeks - currentWeek;

  CropEntity copyWith({
    String? id,
    String? name,
    List<WeekEntity>? weeks,
    int? progressPercentage,
    int? daysSinceFirstPlanting,
    DateTime? createdAt,
    String? fieldId,
    String? fieldName,
    double? fieldAreaHectares,
    String? soilType,
  }) {
    return CropEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      weeks: weeks ?? this.weeks,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      daysSinceFirstPlanting:
          daysSinceFirstPlanting ?? this.daysSinceFirstPlanting,
      createdAt: createdAt ?? this.createdAt,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      fieldAreaHectares: fieldAreaHectares ?? this.fieldAreaHectares,
      soilType: soilType ?? this.soilType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

