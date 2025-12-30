import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login with email and password.
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // Validate inputs
    if (params.email.isEmpty) {
      return const Left(ValidationFailure(message: 'Email is required'));
    }
    if (params.password.isEmpty) {
      return const Left(ValidationFailure(message: 'Password is required'));
    }

    return await repository.signInWithEmail(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

/// Parameters for login use case
class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
}

