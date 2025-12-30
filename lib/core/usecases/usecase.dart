import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base class for all use cases.
/// Use cases represent application-specific business rules.
/// They orchestrate the flow of data to and from entities,
/// and direct those entities to use their enterprise-wide business rules.
abstract class UseCase<Type, Params> {
  /// Execute the use case with given parameters.
  /// Returns Either<Failure, Type> for functional error handling.
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this when the use case doesn't require any parameters.
class NoParams {
  const NoParams();
}

/// Base class for stream-based use cases (real-time data).
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Base class for synchronous use cases.
abstract class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

