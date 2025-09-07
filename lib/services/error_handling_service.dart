import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_error.dart';
import '../utils/retry_mechanism.dart';
import 'offline_manager.dart';

/// Enhanced service wrapper that adds comprehensive error handling
class ErrorHandlingService {
  final OfflineManager _offlineManager;
  final Map<String, CircuitBreaker> _circuitBreakers = {};

  ErrorHandlingService({required OfflineManager offlineManager})
    : _offlineManager = offlineManager;

  /// Execute operation with comprehensive error handling
  Future<T> execute<T>({
    required Future<T> Function() operation,
    required String operationName,
    RetryConfig? retryConfig,
    bool enableCircuitBreaker = true,
    OfflineAction? offlineAction,
    T? fallbackValue,
  }) async {
    try {
      // Check if we're offline and have an offline action
      if (!_offlineManager.isOnline && offlineAction != null) {
        await _offlineManager.queueOfflineAction(offlineAction);

        if (fallbackValue != null) {
          return fallbackValue;
        } else {
          throw NetworkError.noConnection();
        }
      }

      // Get or create circuit breaker for this operation
      CircuitBreaker? circuitBreaker;
      if (enableCircuitBreaker) {
        circuitBreaker = _getCircuitBreaker(operationName);
      }

      // Execute with circuit breaker if enabled
      if (circuitBreaker != null) {
        return await circuitBreaker.execute(() async {
          return await _executeWithRetry(
            operation: operation,
            operationName: operationName,
            retryConfig: retryConfig ?? RetryConfig.network,
          );
        });
      } else {
        return await _executeWithRetry(
          operation: operation,
          operationName: operationName,
          retryConfig: retryConfig ?? RetryConfig.network,
        );
      }
    } catch (e, stackTrace) {
      final appError = _convertToAppError(e, stackTrace);

      // Log error if needed
      if (appError.shouldLog) {
        _logError(operationName, appError);
      }

      // If we have a fallback value and this is a network error, use it
      if (fallbackValue != null && appError.type == ErrorType.network) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  /// Execute operation with retry logic
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    required RetryConfig retryConfig,
  }) async {
    return await RetryMechanism.execute(
      operation,
      config: retryConfig,
      operationName: operationName,
    );
  }

  /// Get or create circuit breaker for operation
  CircuitBreaker _getCircuitBreaker(String operationName) {
    if (!_circuitBreakers.containsKey(operationName)) {
      _circuitBreakers[operationName] = CircuitBreaker(
        name: operationName,
        failureThreshold: 5,
        timeout: const Duration(seconds: 60),
        resetTimeout: const Duration(seconds: 30),
      );
    }
    return _circuitBreakers[operationName]!;
  }

  /// Convert any error to AppError
  AppError _convertToAppError(dynamic error, StackTrace stackTrace) {
    if (error is AppError) {
      return error;
    }

    // Convert Firebase/Firestore specific errors
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('unavailable') ||
        errorString.contains('timeout')) {
      return NetworkError(message: error.toString(), stackTrace: stackTrace);
    }

    if (errorString.contains('permission-denied') ||
        errorString.contains('access denied')) {
      return PermissionError(message: error.toString(), stackTrace: stackTrace);
    }

    if (errorString.contains('not-found') ||
        errorString.contains('document does not exist')) {
      return NotFoundError(message: error.toString(), stackTrace: stackTrace);
    }

    if (errorString.contains('unauthenticated') ||
        errorString.contains('authentication')) {
      return AuthenticationError(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('already-exists') ||
        errorString.contains('duplicate')) {
      return ConflictError(message: error.toString(), stackTrace: stackTrace);
    }

    // Check for validation errors
    if (error is ArgumentError || error is FormatException) {
      return ValidationError(message: error.toString(), stackTrace: stackTrace);
    }

    // Default to unknown error
    return UnknownError(message: error.toString(), stackTrace: stackTrace);
  }

  /// Log error (replace with proper logging in production)
  void _logError(String operationName, AppError error) {
    if (kDebugMode) {
      print('ERROR in $operationName: ${error.toJson()}');
    }

    // In production, send to logging service
    // await _loggingService.logError(operationName, error);
  }

  /// Get circuit breaker status for monitoring
  Map<String, CircuitBreakerState> getCircuitBreakerStatus() {
    return _circuitBreakers.map(
      (name, breaker) => MapEntry(name, breaker.state),
    );
  }

  /// Reset all circuit breakers
  void resetCircuitBreakers() {
    _circuitBreakers.clear();
  }

  /// Dispose resources
  void dispose() {
    _circuitBreakers.clear();
  }
}

/// Mixin for services to add error handling capabilities
mixin ErrorHandlingMixin {
  ErrorHandlingService? _errorHandlingService;

  /// Initialize error handling
  void initializeErrorHandling(ErrorHandlingService errorHandlingService) {
    _errorHandlingService = errorHandlingService;
  }

  /// Execute operation with error handling
  Future<T> executeWithErrorHandling<T>({
    required Future<T> Function() operation,
    required String operationName,
    RetryConfig? retryConfig,
    bool enableCircuitBreaker = true,
    OfflineAction? offlineAction,
    T? fallbackValue,
  }) async {
    if (_errorHandlingService == null) {
      throw StateError('Error handling service not initialized');
    }

    return await _errorHandlingService!.execute<T>(
      operation: operation,
      operationName: operationName,
      retryConfig: retryConfig,
      enableCircuitBreaker: enableCircuitBreaker,
      offlineAction: offlineAction,
      fallbackValue: fallbackValue,
    );
  }
}

/// Global error handler for uncaught errors
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();

  /// Stream of global errors
  Stream<AppError> get errorStream => _errorController.stream;

  /// Initialize global error handling
  void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      final error = UnknownError(
        message: details.exception.toString(),
        stackTrace: details.stack,
        context: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
      _errorController.add(error);
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      final appError = UnknownError(
        message: error.toString(),
        stackTrace: stack,
      );
      _errorController.add(appError);
      return true;
    };
  }

  /// Manually report an error
  void reportError(AppError error) {
    _errorController.add(error);
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}
