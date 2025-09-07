import 'package:flutter/material.dart';
import '../models/app_error.dart';
import '../utils/loading_state.dart';

/// Widget that displays error messages with retry options
class ErrorDisplay extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDisplay({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getErrorColor(error.severity),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_getErrorIcon(error.type), color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error.displayMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            if (showDetails && error.code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error Code: ${error.code}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (error.isRetryable && onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _getErrorColor(error.severity),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

/// Widget that handles loading states with error display
class LoadingStateBuilder<T> extends StatelessWidget {
  final LoadingState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, AppError error)? errorBuilder;
  final Widget Function(BuildContext context)? idleBuilder;
  final VoidCallback? onRetry;

  const LoadingStateBuilder({
    Key? key,
    required this.state,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.idleBuilder,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case LoadingStatus.idle:
        return idleBuilder?.call(context) ?? const SizedBox.shrink();

      case LoadingStatus.loading:
        return loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator());

      case LoadingStatus.success:
        if (state.data != null) {
          return builder(context, state.data!);
        }
        return const Center(child: Text('No data available'));

      case LoadingStatus.error:
        if (errorBuilder != null) {
          return errorBuilder!(context, state.error!);
        }
        return Center(
          child: ErrorDisplay(error: state.error!, onRetry: onRetry),
        );
    }
  }
}

/// Snackbar for displaying errors
class ErrorSnackBar {
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error.displayMessage)),
          ],
        ),
        backgroundColor: _getErrorColor(error.severity),
        action: error.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: Duration(
          seconds: error.severity == ErrorSeverity.critical ? 10 : 4,
        ),
      ),
    );
  }

  static Color _getErrorColor(ErrorSeverity severity) {
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

  static IconData _getErrorIcon(ErrorType type) {
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

/// Form field with validation error display
class ValidatedFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final List<String>? fieldErrors;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final TextEditingController? controller;

  const ValidatedFormField({
    Key? key,
    this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
    this.fieldErrors,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasErrors = fieldErrors?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? value : null,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasErrors ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasErrors ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasErrors ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
        if (hasErrors) ...[
          const SizedBox(height: 4),
          ...fieldErrors!.map(
            (error) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Offline indicator widget
class OfflineIndicator extends StatelessWidget {
  final bool isOffline;

  const OfflineIndicator({Key? key, required this.isOffline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'You are offline. Changes will sync when connection is restored.',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Retry button widget
class RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final String? label;
  final bool isLoading;

  const RetryButton({
    Key? key,
    required this.onRetry,
    this.label,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onRetry,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: Text(label ?? 'Retry'),
    );
  }
}
