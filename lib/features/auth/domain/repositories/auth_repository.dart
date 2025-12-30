import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations.
/// The domain layer depends on this abstraction, not the implementation.
abstract class AuthRepository {
  /// Get the currently authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;

  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get current user ID (null if not authenticated)
  String? get currentUserId;
}

