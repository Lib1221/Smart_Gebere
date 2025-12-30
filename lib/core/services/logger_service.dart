import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for the application.
/// Provides structured logging with different levels and optional crash reporting.
class LoggerService {
  late final Logger _logger;
  
  // Singleton pattern
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  
  LoggerService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );
  }

  /// Log debug message (only in debug mode)
  void debug(String message, {String? tag, dynamic data}) {
    if (kDebugMode) {
      _logger.d(_formatMessage(message, tag, data));
    }
  }

  /// Log info message
  void info(String message, {String? tag, dynamic data}) {
    _logger.i(_formatMessage(message, tag, data));
  }

  /// Log warning message
  void warning(String message, {String? tag, dynamic data}) {
    _logger.w(_formatMessage(message, tag, data));
  }

  /// Log error message with optional exception and stack trace
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _formatMessage(message, tag, null),
      error: error,
      stackTrace: stackTrace,
    );
    
    // In production, send to crash reporting
    if (!kDebugMode && error != null) {
      _reportToCrashlytics(error, stackTrace);
    }
  }

  /// Log fatal error (will be reported to crash analytics)
  void fatal(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.f(
      _formatMessage(message, tag, null),
      error: error,
      stackTrace: stackTrace,
    );
    
    // Always report fatal errors
    _reportToCrashlytics(error ?? Exception(message), stackTrace, fatal: true);
  }

  /// Log API call
  void apiCall({
    required String method,
    required String endpoint,
    int? statusCode,
    int? durationMs,
    bool isSuccess = true,
  }) {
    final emoji = isSuccess ? '✅' : '❌';
    final status = statusCode != null ? ' [$statusCode]' : '';
    final duration = durationMs != null ? ' (${durationMs}ms)' : '';
    
    if (isSuccess) {
      debug('$emoji $method $endpoint$status$duration', tag: 'API');
    } else {
      warning('$emoji $method $endpoint$status$duration', tag: 'API');
    }
  }

  /// Log user action for analytics
  void userAction(String action, {Map<String, dynamic>? parameters}) {
    debug('👤 User Action: $action', tag: 'ANALYTICS', data: parameters);
  }

  /// Log performance metric
  void performance(String operation, int durationMs) {
    debug('⏱️ $operation completed in ${durationMs}ms', tag: 'PERF');
  }

  /// Log navigation event
  void navigation(String from, String to) {
    debug('🧭 Navigation: $from → $to', tag: 'NAV');
  }

  /// Log AI interaction
  void ai({
    required String feature,
    required int durationMs,
    required bool isSuccess,
    String? model,
    int? tokenCount,
  }) {
    final emoji = isSuccess ? '🤖' : '🔴';
    final modelInfo = model != null ? ' ($model)' : '';
    final tokens = tokenCount != null ? ', ${tokenCount} tokens' : '';
    
    if (isSuccess) {
      debug('$emoji AI $feature$modelInfo: ${durationMs}ms$tokens', tag: 'AI');
    } else {
      warning('$emoji AI $feature failed$modelInfo: ${durationMs}ms', tag: 'AI');
    }
  }

  String _formatMessage(String message, String? tag, dynamic data) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final dataStr = data != null ? '\n$data' : '';
    return '$tagPrefix$message$dataStr';
  }

  void _reportToCrashlytics(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) {
    // TODO: Integrate with Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: fatal);
    if (kDebugMode) {
      debugPrint('[CRASHLYTICS] Would report: $error (fatal: $fatal)');
    }
  }
}

/// Extension for easy logging from any class
extension LoggerExtension on Object {
  LoggerService get logger => LoggerService();
  
  void logDebug(String message, {dynamic data}) {
    logger.debug(message, tag: runtimeType.toString(), data: data);
  }
  
  void logInfo(String message, {dynamic data}) {
    logger.info(message, tag: runtimeType.toString(), data: data);
  }
  
  void logWarning(String message, {dynamic data}) {
    logger.warning(message, tag: runtimeType.toString(), data: data);
  }
  
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    logger.error(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
}

