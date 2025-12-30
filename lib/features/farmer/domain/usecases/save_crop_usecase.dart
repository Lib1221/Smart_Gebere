import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_entity.dart';
import '../repositories/farmer_repository.dart';

/// Use case for saving a new crop.
class SaveCropUseCase implements UseCase<CropEntity, SaveCropParams> {
  final FarmerRepository repository;

  SaveCropUseCase({required this.repository});

  @override
  Future<Either<Failure, CropEntity>> call(SaveCropParams params) async {
    // Validate crop data
    if (params.crop.name.isEmpty) {
      return const Left(ValidationFailure(message: 'Crop name is required'));
    }
    if (params.crop.weeks.isEmpty) {
      return const Left(ValidationFailure(message: 'Crop must have at least one week'));
    }

    return await repository.saveCrop(params.crop);
  }
}

/// Parameters for save crop use case
class SaveCropParams {
  final CropEntity crop;

  const SaveCropParams({required this.crop});
}

