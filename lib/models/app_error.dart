/// Comprehensive error handling models for the expense sharing system
///
/// This file defines various error types and their handling mechanisms
/// to provide user-friendly error messages and recovery options.

enum ErrorType {
  network,
  authentication,
  validation,
  permission,
  notFound,
  conflict,
  server,
  unknown,
}

enum ErrorSeverity { low, medium, high, critical }

/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? userMessage;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? code;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    this.userMessage,
    required this.type,
    this.severity = ErrorSeverity.medium,
    this.code,
    this.context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       stackTrace = stackTrace;

  /// User-friendly message to display in UI
  String get displayMessage => userMessage ?? message;

  /// Whether this error should be retried automatically
  bool get isRetryable => false;

  /// Whether this error should be logged
  bool get shouldLog => severity != ErrorSeverity.low;

  @override
  String toString() => 'AppError: $message';

  /// Convert error to JSON for logging
  Map<String, dynamic> toJson() => {
    'message': message,
    'userMessage': userMessage,
    'type': type.name,
    'severity': severity.name,
    'code': code,
    'context': context,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Network-related errors
class NetworkError extends AppError {
  final bool isConnected;
  final int? statusCode;

  NetworkError({
    required String message,
    String? userMessage,
    this.isConnected = true,
    this.statusCode,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage:
             userMessage ?? 'Network connection problem. Please try again.',
         type: ErrorType.network,
         severity: ErrorSeverity.medium,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  @override
  bool get isRetryable => true;

  factory NetworkError.noConnection() => NetworkError(
    message: 'No internet connection',
    userMessage: 'Please check your internet connection and try again.',
    isConnected: false,
    code: 'NO_CONNECTION',
  );

  factory NetworkError.timeout() => NetworkError(
    message: 'Request timeout',
    userMessage: 'The request took too long. Please try again.',
    code: 'TIMEOUT',
  );

  factory NetworkError.serverError(int statusCode) => NetworkError(
    message: 'Server error: $statusCode',
    userMessage: 'Server is temporarily unavailable. Please try again later.',
    statusCode: statusCode,
    code: 'SERVER_ERROR',
  );
}

/// Authentication-related errors
class AuthenticationError extends AppError {
  AuthenticationError({
    required String message,
    String? userMessage,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage: userMessage ?? 'Authentication required. Please sign in.',
         type: ErrorType.authentication,
         severity: ErrorSeverity.high,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  factory AuthenticationError.notSignedIn() => AuthenticationError(
    message: 'User not authenticated',
    userMessage: 'Please sign in to continue.',
    code: 'NOT_SIGNED_IN',
  );

  factory AuthenticationError.tokenExpired() => AuthenticationError(
    message: 'Authentication token expired',
    userMessage: 'Your session has expired. Please sign in again.',
    code: 'TOKEN_EXPIRED',
  );
}

/// Validation-related errors
class ValidationError extends AppError {
  final Map<String, List<String>>? fieldErrors;

  ValidationError({
    required String message,
    String? userMessage,
    this.fieldErrors,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage: userMessage ?? 'Please check your input and try again.',
         type: ErrorType.validation,
         severity: ErrorSeverity.low,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  factory ValidationError.required(String field) => ValidationError(
    message: '$field is required',
    userMessage: 'Please fill in all required fields.',
    fieldErrors: {
      field: ['This field is required'],
    },
    code: 'REQUIRED_FIELD',
  );

  factory ValidationError.invalidFormat(String field, String format) =>
      ValidationError(
        message: 'Invalid $field format',
        userMessage: 'Please enter a valid $format.',
        fieldErrors: {
          field: ['Invalid format'],
        },
        code: 'INVALID_FORMAT',
      );

  factory ValidationError.outOfRange(String field, String range) =>
      ValidationError(
        message: '$field is out of range',
        userMessage: 'Please enter a value within the valid range ($range).',
        fieldErrors: {
          field: ['Value out of range'],
        },
        code: 'OUT_OF_RANGE',
      );
}

/// Permission-related errors
class PermissionError extends AppError {
  final String? requiredPermission;

  PermissionError({
    required String message,
    String? userMessage,
    this.requiredPermission,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage:
             userMessage ??
             'You don\'t have permission to perform this action.',
         type: ErrorType.permission,
         severity: ErrorSeverity.medium,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  factory PermissionError.accessDenied(String resource) => PermissionError(
    message: 'Access denied to $resource',
    userMessage: 'You don\'t have access to this $resource.',
    code: 'ACCESS_DENIED',
  );

  factory PermissionError.notGroupMember() => PermissionError(
    message: 'User is not a group member',
    userMessage: 'You must be a group member to perform this action.',
    code: 'NOT_GROUP_MEMBER',
  );
}

/// Resource not found errors
class NotFoundError extends AppError {
  final String? resourceType;
  final String? resourceId;

  NotFoundError({
    required String message,
    String? userMessage,
    this.resourceType,
    this.resourceId,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage: userMessage ?? 'The requested item was not found.',
         type: ErrorType.notFound,
         severity: ErrorSeverity.medium,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  factory NotFoundError.resource(String type, String id) => NotFoundError(
    message: '$type not found: $id',
    userMessage: 'The $type you\'re looking for doesn\'t exist.',
    resourceType: type,
    resourceId: id,
    code: 'RESOURCE_NOT_FOUND',
  );
}

/// Conflict errors (e.g., duplicate data)
class ConflictError extends AppError {
  ConflictError({
    required String message,
    String? userMessage,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage:
             userMessage ?? 'This action conflicts with existing data.',
         type: ErrorType.conflict,
         severity: ErrorSeverity.medium,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  factory ConflictError.duplicate(String resource) => ConflictError(
    message: 'Duplicate $resource',
    userMessage: 'This $resource already exists.',
    code: 'DUPLICATE_RESOURCE',
  );
}

/// Unknown/unexpected errors
class UnknownError extends AppError {
  UnknownError({
    required String message,
    String? userMessage,
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) : super(
         message: message,
         userMessage:
             userMessage ?? 'An unexpected error occurred. Please try again.',
         type: ErrorType.unknown,
         severity: ErrorSeverity.high,
         code: code,
         context: context,
         stackTrace: stackTrace,
         timestamp: timestamp,
       );

  factory UnknownError.fromException(Exception e, [StackTrace? stackTrace]) =>
      UnknownError(
        message: e.toString(),
        code: 'UNKNOWN_EXCEPTION',
        context: {'originalException': e.runtimeType.toString()},
        stackTrace: stackTrace,
      );
}
