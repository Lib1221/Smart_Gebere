import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_gebere/core/errors/failures.dart';
import 'package:smart_gebere/features/auth/domain/entities/user_entity.dart';
import 'package:smart_gebere/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_gebere/features/auth/domain/usecases/login_usecase.dart';

// Mock class
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(repository: mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = UserEntity(
    id: '123',
    email: tEmail,
    displayName: 'Test User',
    emailVerified: true,
  );

  group('LoginUseCase', () {
    test('should return ValidationFailure when email is empty', () async {
      // Arrange
      const params = LoginParams(email: '', password: tPassword);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return Left'),
      );
      verifyNever(() => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('should return ValidationFailure when password is empty', () async {
      // Arrange
      const params = LoginParams(email: tEmail, password: '');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return Left'),
      );
      verifyNever(() => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('should call repository with trimmed email', () async {
      // Arrange
      const params = LoginParams(email: '  $tEmail  ', password: tPassword);
      when(() => mockRepository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => const Right(tUser));

      // Act
      await useCase(params);

      // Assert
      verify(() => mockRepository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });

    test('should return UserEntity on successful login', () async {
      // Arrange
      const params = LoginParams(email: tEmail, password: tPassword);
      when(() => mockRepository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => const Right(tUser));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Right(tUser));
      verify(() => mockRepository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });

    test('should return AuthFailure on invalid credentials', () async {
      // Arrange
      const params = LoginParams(email: tEmail, password: 'wrongpassword');
      const failure = AuthFailure(
        message: 'Incorrect password',
        code: 'wrong-password',
      );
      when(() => mockRepository.signInWithEmail(
            email: tEmail,
            password: 'wrongpassword',
          )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(failure));
    });

    test('should return AuthFailure when user not found', () async {
      // Arrange
      const params = LoginParams(email: 'nonexistent@example.com', password: tPassword);
      const failure = AuthFailure(
        message: 'No account found',
        code: 'user-not-found',
      );
      when(() => mockRepository.signInWithEmail(
            email: 'nonexistent@example.com',
            password: tPassword,
          )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(params);

      // Assert
      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Should return Left'),
      );
    });
  });
}

