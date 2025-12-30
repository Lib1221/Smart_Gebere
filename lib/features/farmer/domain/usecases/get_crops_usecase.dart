import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_entity.dart';
import '../repositories/farmer_repository.dart';

/// Use case for getting all crops.
class GetCropsUseCase implements UseCase<List<CropEntity>, GetCropsParams> {
  final FarmerRepository repository;

  GetCropsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<CropEntity>>> call(GetCropsParams params) async {
    return await repository.getCrops(params.farmerId);
  }
}

/// Parameters for get crops use case
class GetCropsParams {
  final String? farmerId;

  const GetCropsParams({this.farmerId});
}

