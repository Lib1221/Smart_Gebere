import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/farmer_entity.dart';
import '../entities/crop_entity.dart';
import '../entities/field_entity.dart';

/// Abstract repository interface for farmer data operations.
abstract class FarmerRepository {
  /// Get farmer profile by ID (or current user if null)
  Future<Either<Failure, FarmerEntity>> getFarmer([String? farmerId]);

  /// Stream of farmer data changes
  Stream<Either<Failure, FarmerEntity>> watchFarmer([String? farmerId]);

  /// Update farmer profile
  Future<Either<Failure, FarmerEntity>> updateFarmer(FarmerEntity farmer);

  // ═══════════════════════════════════════════════════════════════════════════
  // Crop Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all crops for the farmer
  Future<Either<Failure, List<CropEntity>>> getCrops([String? farmerId]);

  /// Stream of crops changes
  Stream<Either<Failure, List<CropEntity>>> watchCrops([String? farmerId]);

  /// Get a single crop by ID
  Future<Either<Failure, CropEntity>> getCrop(String cropId);

  /// Save a new crop
  Future<Either<Failure, CropEntity>> saveCrop(CropEntity crop);

  /// Update an existing crop
  Future<Either<Failure, CropEntity>> updateCrop(CropEntity crop);

  /// Delete a crop
  Future<Either<Failure, void>> deleteCrop(String cropId);

  /// Update task completion for a crop
  Future<Either<Failure, CropEntity>> updateTaskCompletion({
    required String cropId,
    required int weekIndex,
    required int taskIndex,
    required bool isCompleted,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Field Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all fields for the farmer
  Future<Either<Failure, List<FieldEntity>>> getFields([String? farmerId]);

  /// Save a new field
  Future<Either<Failure, FieldEntity>> saveField(FieldEntity field);

  /// Delete a field
  Future<Either<Failure, void>> deleteField(String fieldId);
}

