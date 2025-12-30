import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/farmer_entity.dart';
import '../repositories/farmer_repository.dart';

/// Use case for getting farmer data.
class GetFarmerUseCase implements UseCase<FarmerEntity, GetFarmerParams> {
  final FarmerRepository repository;

  GetFarmerUseCase({required this.repository});

  @override
  Future<Either<Failure, FarmerEntity>> call(GetFarmerParams params) async {
    return await repository.getFarmer(params.farmerId);
  }
}

/// Parameters for get farmer use case
class GetFarmerParams {
  final String? farmerId;

  const GetFarmerParams({this.farmerId});
}

