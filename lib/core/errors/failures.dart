import 'package:dartz/dartz.dart';

/// Base Failure class for all application failures.
/// Used with Either<Failure, Success> pattern for error handling.
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

/// Type alias for Either with Failure
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid = ResultFuture<void>;

// ═══════════════════════════════════════════════════════════════════════════
// Server Failures
// ═══════════════════════════════════════════════════════════════════════════

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
    super.code = 'TIMEOUT',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Failures
// ═══════════════════════════════════════════════════════════════════════════

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory AuthFailure.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthFailure(
          message: 'No account found with this email. Please sign up first.',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthFailure(
          message: 'Incorrect password. Please try again or reset your password.',
          code: 'wrong-password',
        );
      case 'invalid-email':
        return const AuthFailure(
          message: 'Please enter a valid email address.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthFailure(
          message: 'This account has been disabled. Contact support for help.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Too many failed attempts. Please wait a moment and try again.',
          code: 'too-many-requests',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          message: 'An account already exists with this email.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthFailure(
          message: 'Password is too weak. Use at least 6 characters.',
          code: 'weak-password',
        );
      case 'invalid-credential':
        return const AuthFailure(
          message: 'Invalid email or password. Please check your credentials.',
          code: 'invalid-credential',
        );
      default:
        return AuthFailure(
          message: 'Authentication failed. Please try again.',
          code: code,
        );
    }
  }
}

class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure({
    super.message = 'Your session has expired. Please log in again.',
    super.code = 'SESSION_EXPIRED',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Database Failures
// ═══════════════════════════════════════════════════════════════════════════

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested data was not found.',
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({
    super.message = 'You do not have permission to access this data.',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AI/ML Failures
// ═══════════════════════════════════════════════════════════════════════════

class AIFailure extends Failure {
  const AIFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

class AIModelNotAvailableFailure extends AIFailure {
  const AIModelNotAvailableFailure({
    super.message = 'AI model is currently unavailable. Please try again later.',
    super.code = 'AI_MODEL_UNAVAILABLE',
    super.originalError,
  });
}

class AIResponseParseFailure extends AIFailure {
  const AIResponseParseFailure({
    super.message = 'Failed to parse AI response. Please try again.',
    super.code = 'AI_PARSE_ERROR',
    super.originalError,
  });
}

class AIRateLimitFailure extends AIFailure {
  const AIRateLimitFailure({
    super.message = 'AI service rate limit reached. Please wait a moment.',
    super.code = 'AI_RATE_LIMIT',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Location Failures
// ═══════════════════════════════════════════════════════════════════════════

class LocationFailure extends Failure {
  const LocationFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure({
    super.message = 'Location permission denied. Please enable location access.',
    super.code = 'LOCATION_PERMISSION_DENIED',
  });
}

class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure({
    super.message = 'Location services are disabled. Please enable GPS.',
    super.code = 'LOCATION_SERVICE_DISABLED',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Validation Failures
// ═══════════════════════════════════════════════════════════════════════════

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache Failures
// ═══════════════════════════════════════════════════════════════════════════

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

class CacheExpiredFailure extends CacheFailure {
  const CacheExpiredFailure({
    super.message = 'Cached data has expired.',
    super.code = 'CACHE_EXPIRED',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Unknown/Generic Failures
// ═══════════════════════════════════════════════════════════════════════════

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNKNOWN',
    super.originalError,
  });
}

