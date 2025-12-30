import 'package:flutter_test/flutter_test.dart';
import 'package:smart_gebere/features/farmer/domain/entities/crop_entity.dart';
import 'package:smart_gebere/features/farmer/domain/entities/week_entity.dart';

void main() {
  group('CropEntity', () {
    late CropEntity crop;
    late List<WeekEntity> weeks;

    setUp(() {
      final now = DateTime.now();
      weeks = [
        WeekEntity(
          weekNumber: 1,
          startDate: now.subtract(const Duration(days: 14)),
          endDate: now.subtract(const Duration(days: 8)),
          stage: 'Land Preparation',
          tasks: ['Plow field', 'Add compost', 'Test soil'],
          completedTasks: {0, 1, 2}, // All complete
        ),
        WeekEntity(
          weekNumber: 2,
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 0)),
          stage: 'Planting',
          tasks: ['Sow seeds', 'Water field', 'Apply fertilizer'],
          completedTasks: {0}, // 1 complete
        ),
        WeekEntity(
          weekNumber: 3,
          startDate: now.add(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 7)),
          stage: 'Growth',
          tasks: ['Weed field', 'Check pests', 'Water regularly'],
          completedTasks: {}, // None complete
        ),
      ];

      crop = CropEntity(
        id: 'crop-1',
        name: 'Teff',
        weeks: weeks,
        progressPercentage: 44,
        daysSinceFirstPlanting: 14,
        createdAt: now.subtract(const Duration(days: 14)),
        fieldId: 'field-1',
        fieldName: 'North Plot',
        fieldAreaHectares: 2.5,
        soilType: 'Loam',
      );
    });

    test('should calculate totalTasks correctly', () {
      expect(crop.totalTasks, 9); // 3 + 3 + 3
    });

    test('should calculate completedTasks correctly', () {
      expect(crop.completedTasks, 4); // 3 + 1 + 0
    });

    test('should calculate progress percentage correctly', () {
      final progress = crop.calculatedProgress;
      expect(progress.round(), 44); // 4/9 * 100 ≈ 44%
    });

    test('should return correct currentWeek', () {
      expect(crop.currentWeek, 2); // Week 2 is current based on dates
    });

    test('should return correct currentStage', () {
      expect(crop.currentStage, 'Planting');
    });

    test('should calculate weeksRemaining correctly', () {
      expect(crop.weeksRemaining, 1); // 3 - 2 = 1
    });

    test('should return false for isComplete when not 100%', () {
      expect(crop.isComplete, isFalse);
    });

    test('should return true for isComplete when 100%', () {
      final completeCrop = crop.copyWith(progressPercentage: 100);
      expect(completeCrop.isComplete, isTrue);
    });

    test('copyWith should create new instance with updated values', () {
      final updated = crop.copyWith(
        name: 'Wheat',
        progressPercentage: 50,
      );

      expect(updated.name, 'Wheat');
      expect(updated.progressPercentage, 50);
      expect(updated.id, crop.id); // Unchanged
      expect(updated.fieldId, crop.fieldId); // Unchanged
    });

    test('equality should be based on id', () {
      final sameCrop = CropEntity(
        id: 'crop-1',
        name: 'Different Name',
        weeks: [],
        createdAt: DateTime.now(),
      );

      expect(crop, equals(sameCrop));
    });

    test('should have correct hashCode based on id', () {
      expect(crop.hashCode, 'crop-1'.hashCode);
    });
  });

  group('WeekEntity', () {
    late WeekEntity week;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      week = WeekEntity(
        weekNumber: 1,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        stage: 'Planting',
        tasks: ['Task 1', 'Task 2', 'Task 3', 'Task 4'],
        completedTasks: {0, 2},
      );
    });

    test('should return correct taskCount', () {
      expect(week.taskCount, 4);
    });

    test('should return correct completedCount', () {
      expect(week.completedCount, 2);
    });

    test('should calculate progress correctly', () {
      expect(week.progress, 50.0); // 2/4 * 100
    });

    test('should return false for isComplete when not all done', () {
      expect(week.isComplete, isFalse);
    });

    test('should return true for isComplete when all done', () {
      final completeWeek = week.copyWith(completedTasks: {0, 1, 2, 3});
      expect(completeWeek.isComplete, isTrue);
    });

    test('isTaskCompleted should return correct value', () {
      expect(week.isTaskCompleted(0), isTrue);
      expect(week.isTaskCompleted(1), isFalse);
      expect(week.isTaskCompleted(2), isTrue);
      expect(week.isTaskCompleted(3), isFalse);
    });

    test('isCurrentWeek should return true for current week', () {
      expect(week.isCurrentWeek(now), isTrue);
    });

    test('isCurrentWeek should return false for past date', () {
      final pastDate = now.subtract(const Duration(days: 10));
      expect(week.isCurrentWeek(pastDate), isFalse);
    });

    test('isPast should return true for completed week', () {
      final futureDate = now.add(const Duration(days: 10));
      expect(week.isPast(futureDate), isTrue);
    });

    test('isFuture should return true for upcoming week', () {
      final pastDate = now.subtract(const Duration(days: 10));
      expect(week.isFuture(pastDate), isTrue);
    });

    test('toggleTask should add task to completed', () {
      final toggled = week.toggleTask(1);
      expect(toggled.isTaskCompleted(1), isTrue);
    });

    test('toggleTask should remove task from completed', () {
      final toggled = week.toggleTask(0);
      expect(toggled.isTaskCompleted(0), isFalse);
    });

    test('dateRangeFormatted should return correct format', () {
      final formatted = week.dateRangeFormatted;
      expect(formatted, contains('/'));
      expect(formatted, contains(' - '));
    });
  });
}

