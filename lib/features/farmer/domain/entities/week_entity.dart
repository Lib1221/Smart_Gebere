import 'package:flutter/foundation.dart';

/// Week entity representing a week in a crop's schedule.
@immutable
class WeekEntity {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String stage;
  final List<String> tasks;
  final Set<int> completedTasks;

  const WeekEntity({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.stage,
    required this.tasks,
    this.completedTasks = const {},
  });

  /// Number of tasks in this week
  int get taskCount => tasks.length;

  /// Number of completed tasks
  int get completedCount => completedTasks.length;

  /// Progress percentage for this week
  double get progress => taskCount > 0 ? (completedCount / taskCount) * 100 : 0;

  /// Whether all tasks are complete
  bool get isComplete => completedCount == taskCount && taskCount > 0;

  /// Check if a specific task is completed
  bool isTaskCompleted(int index) => completedTasks.contains(index);

  /// Check if this is the current week
  bool isCurrentWeek(DateTime now) {
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Check if this week is in the past
  bool isPast(DateTime now) => now.isAfter(endDate);

  /// Check if this week is in the future
  bool isFuture(DateTime now) => now.isBefore(startDate);

  /// Get date range as formatted string
  String get dateRangeFormatted {
    final startStr = '${startDate.day}/${startDate.month}';
    final endStr = '${endDate.day}/${endDate.month}';
    return '$startStr - $endStr';
  }

  WeekEntity copyWith({
    int? weekNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? stage,
    List<String>? tasks,
    Set<int>? completedTasks,
  }) {
    return WeekEntity(
      weekNumber: weekNumber ?? this.weekNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stage: stage ?? this.stage,
      tasks: tasks ?? this.tasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  /// Create a copy with a task marked as complete/incomplete
  WeekEntity toggleTask(int taskIndex) {
    final newCompleted = Set<int>.from(completedTasks);
    if (newCompleted.contains(taskIndex)) {
      newCompleted.remove(taskIndex);
    } else {
      newCompleted.add(taskIndex);
    }
    return copyWith(completedTasks: newCompleted);
  }
}

