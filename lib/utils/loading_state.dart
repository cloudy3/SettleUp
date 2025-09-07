import 'package:flutter/foundation.dart';
import '../models/app_error.dart';

/// Represents different loading states
enum LoadingStatus { idle, loading, success, error }

/// Generic loading state management
class LoadingState<T> {
  final LoadingStatus status;
  final T? data;
  final AppError? error;
  final String? message;

  const LoadingState._({
    required this.status,
    this.data,
    this.error,
    this.message,
  });

  /// Create idle state
  const LoadingState.idle() : this._(status: LoadingStatus.idle);

  /// Create loading state
  const LoadingState.loading([String? message])
    : this._(status: LoadingStatus.loading, message: message);

  /// Create success state
  const LoadingState.success(T data, [String? message])
    : this._(status: LoadingStatus.success, data: data, message: message);

  /// Create error state
  const LoadingState.error(AppError error)
    : this._(status: LoadingStatus.error, error: error);

  /// Convenience getters
  bool get isIdle => status == LoadingStatus.idle;
  bool get isLoading => status == LoadingStatus.loading;
  bool get isSuccess => status == LoadingStatus.success;
  bool get isError => status == LoadingStatus.error;
  bool get hasData => data != null;

  /// Get data or throw if not available
  T get requireData {
    if (data == null) {
      throw StateError('Data is not available in current state: $status');
    }
    return data!;
  }

  /// Transform the data while preserving the state
  LoadingState<U> map<U>(U Function(T data) transform) {
    if (data == null) {
      return LoadingState<U>._(status: status, error: error, message: message);
    }

    try {
      final transformedData = transform(data!);
      return LoadingState<U>._(
        status: status,
        data: transformedData,
        error: error,
        message: message,
      );
    } catch (e) {
      return LoadingState<U>.error(
        UnknownError(
          message: 'Failed to transform data: $e',
          code: 'DATA_TRANSFORM_ERROR',
        ),
      );
    }
  }

  /// Copy with new values
  LoadingState<T> copyWith({
    LoadingStatus? status,
    T? data,
    AppError? error,
    String? message,
  }) {
    return LoadingState<T>._(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'LoadingState(status: $status, hasData: $hasData, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadingState<T> &&
        other.status == status &&
        other.data == data &&
        other.error == error &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(status, data, error, message);
  }
}

/// Notifier for managing loading states
class LoadingStateNotifier<T> extends ValueNotifier<LoadingState<T>> {
  LoadingStateNotifier() : super(const LoadingState.idle());

  /// Set loading state
  void setLoading([String? message]) {
    value = LoadingState.loading(message);
  }

  /// Set success state
  void setSuccess(T data, [String? message]) {
    value = LoadingState.success(data, message);
  }

  /// Set error state
  void setError(AppError error) {
    value = LoadingState.error(error);
  }

  /// Set idle state
  void setIdle() {
    value = const LoadingState.idle();
  }

  /// Execute an async operation with automatic state management
  Future<void> execute(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
  }) async {
    try {
      setLoading(loadingMessage);
      final result = await operation();
      setSuccess(result, successMessage);
    } catch (e, stackTrace) {
      final appError = e is AppError
          ? e
          : UnknownError(message: e.toString(), stackTrace: stackTrace);
      setError(appError);
    }
  }

  /// Execute operation with retry capability
  Future<void> executeWithRetry(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? loadingMessage,
    String? successMessage,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        setLoading(loadingMessage);
        final result = await operation();
        setSuccess(result, successMessage);
        return;
      } catch (e, stackTrace) {
        attempts++;

        if (attempts >= maxRetries) {
          final appError = e is AppError
              ? e
              : UnknownError(message: e.toString(), stackTrace: stackTrace);
          setError(appError);
          return;
        }

        // Wait before retrying
        await Future.delayed(delay);
      }
    }
  }
}

/// Multiple loading states manager
class MultiLoadingStateManager {
  final Map<String, LoadingStateNotifier> _notifiers = {};

  /// Get or create a notifier for a specific key
  LoadingStateNotifier<T> getNotifier<T>(String key) {
    if (!_notifiers.containsKey(key)) {
      _notifiers[key] = LoadingStateNotifier<T>();
    }
    return _notifiers[key]! as LoadingStateNotifier<T>;
  }

  /// Check if any operation is loading
  bool get isAnyLoading {
    return _notifiers.values.any((notifier) => notifier.value.isLoading);
  }

  /// Get all current errors
  List<AppError> get allErrors {
    return _notifiers.values
        .where((notifier) => notifier.value.isError)
        .map((notifier) => notifier.value.error!)
        .toList();
  }

  /// Clear all states
  void clearAll() {
    for (final notifier in _notifiers.values) {
      notifier.setIdle();
    }
  }

  /// Dispose all notifiers
  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
  }
}

/// Pagination loading state
class PaginationLoadingState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final AppError? error;
  final int currentPage;

  const PaginationLoadingState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  PaginationLoadingState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    AppError? error,
    int? currentPage,
  }) {
    return PaginationLoadingState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasError => error != null;
}

/// Notifier for pagination loading states
class PaginationLoadingNotifier<T>
    extends ValueNotifier<PaginationLoadingState<T>> {
  PaginationLoadingNotifier() : super(const PaginationLoadingState());

  /// Load first page
  Future<void> loadFirstPage(Future<List<T>> Function(int page) loader) async {
    try {
      value = value.copyWith(isLoading: true, error: null);
      final items = await loader(0);
      value = value.copyWith(
        items: items,
        isLoading: false,
        currentPage: 0,
        hasMore: items.isNotEmpty,
      );
    } catch (e, stackTrace) {
      final appError = e is AppError
          ? e
          : UnknownError(message: e.toString(), stackTrace: stackTrace);
      value = value.copyWith(isLoading: false, error: appError);
    }
  }

  /// Load next page
  Future<void> loadNextPage(Future<List<T>> Function(int page) loader) async {
    if (value.isLoadingMore || !value.hasMore) return;

    try {
      value = value.copyWith(isLoadingMore: true, error: null);
      final nextPage = value.currentPage + 1;
      final newItems = await loader(nextPage);

      value = value.copyWith(
        items: [...value.items, ...newItems],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: newItems.isNotEmpty,
      );
    } catch (e, stackTrace) {
      final appError = e is AppError
          ? e
          : UnknownError(message: e.toString(), stackTrace: stackTrace);
      value = value.copyWith(isLoadingMore: false, error: appError);
    }
  }

  /// Refresh (reload first page)
  Future<void> refresh(Future<List<T>> Function(int page) loader) async {
    value = const PaginationLoadingState();
    await loadFirstPage(loader);
  }
}
