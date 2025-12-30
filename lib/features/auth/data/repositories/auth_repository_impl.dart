import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository using Firebase Auth.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final LoggerService _logger;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required LoggerService logger,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _logger = logger;

  @override
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapFirebaseUser(user);
    });
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Right(null);
      }
      return Right(_mapFirebaseUser(user));
    } catch (e, stack) {
      _logger.error('Error getting current user', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'Failed to get current user',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting login for: $email', tag: 'AUTH');
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left(AuthFailure(
          message: 'Login failed. Please try again.',
          code: 'USER_NULL',
        ));
      }

      // Update last login timestamp
      await _updateLastLogin(credential.user!.uid);

      _logger.info('Login successful for: $email', tag: 'AUTH');
      return Right(_mapFirebaseUser(credential.user!));
    } on FirebaseAuthException catch (e, stack) {
      _logger.warning('Login failed: ${e.code}', tag: 'AUTH');
      return Left(AuthFailure.fromCode(e.code));
    } catch (e, stack) {
      _logger.error('Unexpected login error', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'An unexpected error occurred during login.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _logger.info('Attempting signup for: $email', tag: 'AUTH');

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left(AuthFailure(
          message: 'Signup failed. Please try again.',
          code: 'USER_NULL',
        ));
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      await _createUserDocument(credential.user!, displayName);

      _logger.info('Signup successful for: $email', tag: 'AUTH');
      return Right(_mapFirebaseUser(credential.user!));
    } on FirebaseAuthException catch (e, stack) {
      _logger.warning('Signup failed: ${e.code}', tag: 'AUTH');
      return Left(AuthFailure.fromCode(e.code));
    } catch (e, stack) {
      _logger.error('Unexpected signup error', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'An unexpected error occurred during signup.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      _logger.info('Signing out user', tag: 'AUTH');
      await _firebaseAuth.signOut();
      _logger.info('Sign out successful', tag: 'AUTH');
      return const Right(null);
    } catch (e, stack) {
      _logger.error('Sign out error', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'Failed to sign out.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      _logger.info('Sending password reset email to: $email', tag: 'AUTH');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.info('Password reset email sent', tag: 'AUTH');
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      _logger.warning('Password reset failed: ${e.code}', tag: 'AUTH');
      return Left(AuthFailure.fromCode(e.code));
    } catch (e, stack) {
      _logger.error('Password reset error', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'Failed to send password reset email.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Reload to get updated data
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser!;

      _logger.info('Profile updated successfully', tag: 'AUTH');
      return Right(_mapFirebaseUser(updatedUser));
    } catch (e, stack) {
      _logger.error('Profile update error', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'Failed to update profile.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      // Delete user data from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();
      await _firestore.collection('Farmers').doc(user.uid).delete();

      // Delete the Firebase Auth account
      await user.delete();

      _logger.info('Account deleted successfully', tag: 'AUTH');
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      _logger.warning('Account deletion failed: ${e.code}', tag: 'AUTH');
      return Left(AuthFailure.fromCode(e.code));
    } catch (e, stack) {
      _logger.error('Account deletion error', error: e, stackTrace: stack);
      return Left(UnknownFailure(
        message: 'Failed to delete account.',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helper Methods
  // ═══════════════════════════════════════════════════════════════════════════

  UserEntity _mapFirebaseUser(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  Future<void> _createUserDocument(User user, String? displayName) async {
    final now = FieldValue.serverTimestamp();

    // Create in users collection
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': displayName,
      'createdAt': now,
      'lastLogin': now,
    });

    // Create in Farmers collection (for farmer-specific data)
    await _firestore.collection('Farmers').doc(user.uid).set({
      'email': user.email,
      'name': displayName,
      'createdAt': now,
      'crops': [],
      'fields': [],
    });
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore errors - last login update is not critical
      _logger.debug('Failed to update last login: $e', tag: 'AUTH');
    }
  }
}

