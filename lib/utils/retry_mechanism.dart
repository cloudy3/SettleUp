import 'dart:async';
import 'dart:math';
import '../models/app_error.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(AppError error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.shouldRetry,
  });

  /// Default retry config for network operations
  static const network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
  );

  /// Aggressive retry config for critical operations
  static const critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 5),
    backoffMultiplier: 1.5,
  );

  /// Conservative retry config for non-critical operations
  static const conservative = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 15),
    backoffMultiplier: 3.0,
  );
}

/// Retry mechanism with exponential backoff
class RetryMechanism {
  static final Random _random = Random();

  /// Executes a function with retry logic
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt < config.maxAttempts) {
      attempt++;

      try {
        return await operation();
      } catch (e, stackTrace) {
        final appError = _convertToAppError(e, stackTrace);

        // Check if we should retry this error
        final shouldRetry =
            config.shouldRetry?.call(appError) ?? _defaultShouldRetry(appError);

        // If this is the last attempt or we shouldn't retry, throw the error
        if (attempt >= config.maxAttempts || !shouldRetry) {
          throw appError;
        }

        // Add jitter to prevent thundering herd
        final jitteredDelay = _addJitter(delay);

        // Log retry attempt (in production, use proper logging)
        _logRetryAttempt(
          operationName,
          attempt,
          config.maxAttempts,
          jitteredDelay,
          appError,
        );

        // Wait before retrying
        await Future.delayed(jitteredDelay);

        // Calculate next delay with exponential backoff
        final nextDelayMs = min(
          (delay.inMilliseconds * config.backoffMultiplier).round(),
          config.maxDelay.inMilliseconds,
        );
        delay = Duration(
          milliseconds: nextDelayMs.clamp(1, config.maxDelay.inMilliseconds),
        );
      }
    }

    // This should never be reached, but just in case
    throw UnknownError(
      message: 'Retry mechanism failed unexpectedly',
      code: 'RETRY_MECHANISM_FAILURE',
    );
  }

  /// Converts any exception to AppError
  static AppError _convertToAppError(dynamic error, StackTrace stackTrace) {
    if (error is AppError) {
      return error;
    }

    // Convert common Firebase/Firestore errors
    if (error.toString().contains('network-request-failed') ||
        error.toString().contains('unavailable')) {
      return NetworkError(message: error.toString(), stackTrace: stackTrace);
    }

    if (error.toString().contains('permission-denied')) {
      return PermissionError(message: error.toString(), stackTrace: stackTrace);
    }

    if (error.toString().contains('not-found')) {
      return NotFoundError(message: error.toString(), stackTrace: stackTrace);
    }

    if (error.toString().contains('unauthenticated')) {
      return AuthenticationError(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }

    // Default to unknown error
    return UnknownError(message: error.toString(), stackTrace: stackTrace);
  }

  /// Default logic for determining if an error should be retried
  static bool _defaultShouldRetry(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return true;
      case ErrorType.server:
        return true;
      case ErrorType.authentication:
        // Only retry token expiration, not invalid credentials
        return error.code == 'TOKEN_EXPIRED';
      case ErrorType.validation:
      case ErrorType.permission:
      case ErrorType.notFound:
      case ErrorType.conflict:
        return false;
      case ErrorType.unknown:
        return true; // Conservative approach for unknown errors
    }
  }

  /// Adds jitter to delay to prevent thundering herd problem
  static Duration _addJitter(Duration delay) {
    final baseMs = delay.inMilliseconds.clamp(1, 60000); // Ensure at least 1ms
    final jitterMs = _random.nextInt((baseMs ~/ 4).clamp(1, 1000));
    return Duration(milliseconds: baseMs + jitterMs);
  }

  /// Logs retry attempts (replace with proper logging in production)
  static void _logRetryAttempt(
    String? operationName,
    int attempt,
    int maxAttempts,
    Duration delay,
    AppError error,
  ) {
    final operation = operationName ?? 'operation';
    print(
      'Retry $attempt/$maxAttempts for $operation after ${delay.inMilliseconds}ms: ${error.message}',
    );
  }
}

/// Utility class for circuit breaker pattern
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.resetTimeout = const Duration(seconds: 30),
  });

  /// Executes operation through circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
      } else {
        throw NetworkError(
          message: 'Circuit breaker is open for $name',
          userMessage:
              'Service is temporarily unavailable. Please try again later.',
          code: 'CIRCUIT_BREAKER_OPEN',
        );
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;
}

enum CircuitBreakerState { closed, open, halfOpen }
