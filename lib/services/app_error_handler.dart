import 'package:flutter/material.dart';
import '../models/app_error.dart';
import '../services/error_handling_service.dart';
import '../services/offline_manager.dart';
import '../widgets/error_handling_widgets.dart';

/// Centralized error handling for the entire application
class AppErrorHandler {
  static final AppErrorHandler _instance = AppErrorHandler._internal();
  factory AppErrorHandler() => _instance;
  AppErrorHandler._internal();

  late final OfflineManager _offlineManager;
  late final ErrorHandlingService _errorHandlingService;
  late final GlobalErrorHandler _globalErrorHandler;

  bool _initialized = false;

  /// Initialize the error handling system
  Future<void> initialize() async {
    if (_initialized) return;

    _offlineManager = OfflineManager();
    await _offlineManager.initialize();

    _errorHandlingService = ErrorHandlingService(
      offlineManager: _offlineManager,
    );

    _globalErrorHandler = GlobalErrorHandler();
    _globalErrorHandler.initialize();

    _initialized = true;
  }

  /// Get the offline manager instance
  OfflineManager get offlineManager {
    _ensureInitialized();
    return _offlineManager;
  }

  /// Get the error handling service instance
  ErrorHandlingService get errorHandlingService {
    _ensureInitialized();
    return _errorHandlingService;
  }

  /// Get the global error handler instance
  GlobalErrorHandler get globalErrorHandler {
    _ensureInitialized();
    return _globalErrorHandler;
  }

  /// Show error in UI
  void showError(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    // Determine how to show the error based on severity
    switch (error.severity) {
      case ErrorSeverity.low:
        // Show as snackbar for low severity errors
        ErrorSnackBar.show(context, error, onRetry: onRetry);
        break;

      case ErrorSeverity.medium:
      case ErrorSeverity.high:
        // Show as dialog for medium/high severity errors
        _showErrorDialog(context, error, onRetry);
        break;

      case ErrorSeverity.critical:
        // Show as full-screen error for critical errors
        _showCriticalErrorScreen(context, error, onRetry);
        break;
    }
  }

  /// Show error dialog
  void _showErrorDialog(
    BuildContext context,
    AppError error,
    VoidCallback? onRetry,
  ) {
    showDialog(
      context: context,
      barrierDismissible: error.severity != ErrorSeverity.critical,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: _getErrorColor(error.severity),
            ),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.displayMessage),
            if (error.code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error Code: ${error.code}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          if (error.isRetryable && onRetry != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show critical error screen
  void _showCriticalErrorScreen(
    BuildContext context,
    AppError error,
    VoidCallback? onRetry,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: _getErrorColor(error.severity),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Critical Error',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _getErrorColor(error.severity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error.displayMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (error.code != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Error Code: ${error.code}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (error.isRetryable && onRetry != null) ...[
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to home or restart app
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  /// Listen to global errors and handle them
  void startGlobalErrorHandling(BuildContext context) {
    _globalErrorHandler.errorStream.listen((error) {
      if (context.mounted) {
        showError(context, error);
      }
    });
  }

  /// Dispose resources
  void dispose() {
    if (_initialized) {
      _offlineManager.dispose();
      _errorHandlingService.dispose();
      _globalErrorHandler.dispose();
      _initialized = false;
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'AppErrorHandler not initialized. Call initialize() first.',
      );
    }
  }

  Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.red;
      case ErrorSeverity.high:
        return Colors.red.shade700;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.conflict:
        return Icons.warning;
      case ErrorType.server:
        return Icons.dns;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }
}

/// Mixin for widgets that need error handling
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  AppErrorHandler get errorHandler => AppErrorHandler();

  @override
  void initState() {
    super.initState();
    // Start listening to global errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      errorHandler.startGlobalErrorHandling(context);
    });
  }

  /// Show error with automatic handling based on severity
  void showError(AppError error, {VoidCallback? onRetry}) {
    errorHandler.showError(context, error, onRetry: onRetry);
  }

  /// Handle error from async operations
  void handleAsyncError(
    dynamic error,
    StackTrace stackTrace, {
    VoidCallback? onRetry,
  }) {
    final appError = error is AppError
        ? error
        : UnknownError(message: error.toString(), stackTrace: stackTrace);
    showError(appError, onRetry: onRetry);
  }
}
