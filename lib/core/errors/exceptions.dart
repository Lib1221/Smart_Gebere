/// Base exception class for application-specific exceptions.
/// These are converted to Failures at the repository layer.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

// ═══════════════════════════════════════════════════════════════════════════
// Server Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalException,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
    super.originalException,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.code = 'TIMEOUT',
    super.originalException,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException({
    super.message = 'Session expired',
    super.code = 'SESSION_EXPIRED',
  });
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException({
    super.message = 'Unauthorized access',
    super.code = 'UNAUTHORIZED',
    super.originalException,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Database Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
    super.originalException,
  });
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    super.message = 'Permission denied',
    super.code = 'PERMISSION_DENIED',
    super.originalException,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AI Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class AIException extends AppException {
  const AIException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class AIModelNotFoundException extends AIException {
  const AIModelNotFoundException({
    super.message = 'AI model not found',
    super.code = 'AI_MODEL_NOT_FOUND',
    super.originalException,
  });
}

class AIResponseParseException extends AIException {
  const AIResponseParseException({
    super.message = 'Failed to parse AI response',
    super.code = 'AI_PARSE_ERROR',
    super.originalException,
  });
}

class AIRateLimitException extends AIException {
  const AIRateLimitException({
    super.message = 'AI rate limit exceeded',
    super.code = 'AI_RATE_LIMIT',
    super.originalException,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Location Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class LocationException extends AppException {
  const LocationException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException({
    super.message = 'Location permission denied',
    super.code = 'LOCATION_PERMISSION_DENIED',
  });
}

class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException({
    super.message = 'Location services disabled',
    super.code = 'LOCATION_SERVICE_DISABLED',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Validation Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalException,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache Exceptions
// ═══════════════════════════════════════════════════════════════════════════

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalException,
  });
}

class CacheExpiredException extends CacheException {
  const CacheExpiredException({
    super.message = 'Cache expired',
    super.code = 'CACHE_EXPIRED',
  });
}

