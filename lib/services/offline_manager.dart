import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/app_error.dart';

/// Manages offline data storage and synchronization
class OfflineManager {
  static const String _keyPrefix = 'offline_';
  static const String _pendingActionsKey = '${_keyPrefix}pending_actions';
  static const String _lastSyncKey = '${_keyPrefix}last_sync';

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  SharedPreferences? _prefs;
  Timer? _syncTimer;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize offline manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        // Just came back online, trigger sync
        _triggerSync();
      }

      _connectivityController.add(_isOnline);
    });

    // Start periodic sync when online
    _startPeriodicSync();
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivityController.close();
  }

  /// Cache data locally
  Future<void> cacheData<T>(String key, T data) async {
    if (_prefs == null) return;

    try {
      String jsonData;
      if (data is Map<String, dynamic>) {
        jsonData = jsonEncode(data);
      } else if (data is List) {
        jsonData = jsonEncode(
          data
              .map(
                (item) => item is Map<String, dynamic> ? item : item.toJson(),
              )
              .toList(),
        );
      } else {
        // Assume the object has a toJson method
        jsonData = jsonEncode((data as dynamic).toJson());
      }

      await _prefs!.setString('$_keyPrefix$key', jsonData);
    } catch (e) {
      throw UnknownError(
        message: 'Failed to cache data: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  /// Retrieve cached data
  Future<T?> getCachedData<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (_prefs == null) return null;

    try {
      final jsonString = _prefs!.getString('$_keyPrefix$key');
      if (jsonString == null) return null;

      final jsonData = jsonDecode(jsonString);

      if (jsonData is List) {
        // Handle list of objects
        return jsonData
                .map((item) => fromJson(item as Map<String, dynamic>))
                .toList()
            as T;
      } else if (jsonData is Map<String, dynamic>) {
        // Handle single object
        return fromJson(jsonData);
      }

      return null;
    } catch (e) {
      throw UnknownError(
        message: 'Failed to retrieve cached data: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  /// Queue an action for later execution when online
  Future<void> queueOfflineAction(OfflineAction action) async {
    if (_prefs == null) return;

    try {
      final existingActions = await _getPendingActions();
      existingActions.add(action);

      await _prefs!.setString(
        _pendingActionsKey,
        jsonEncode(existingActions.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      throw UnknownError(
        message: 'Failed to queue offline action: $e',
        code: 'QUEUE_ACTION_ERROR',
      );
    }
  }

  /// Get all pending offline actions
  Future<List<OfflineAction>> _getPendingActions() async {
    if (_prefs == null) return [];

    try {
      final jsonString = _prefs!.getString(_pendingActionsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => OfflineAction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Execute all pending actions when back online
  Future<void> syncPendingActions() async {
    if (!_isOnline) return;

    final pendingActions = await _getPendingActions();
    if (pendingActions.isEmpty) return;

    final successfulActions = <OfflineAction>[];

    for (final action in pendingActions) {
      try {
        await _executeAction(action);
        successfulActions.add(action);
      } catch (e) {
        // Log error but continue with other actions
        print('Failed to sync action ${action.id}: $e');
      }
    }

    // Remove successful actions from queue
    if (successfulActions.isNotEmpty) {
      final remainingActions = pendingActions
          .where((action) => !successfulActions.contains(action))
          .toList();

      if (remainingActions.isEmpty) {
        await _prefs!.remove(_pendingActionsKey);
      } else {
        await _prefs!.setString(
          _pendingActionsKey,
          jsonEncode(remainingActions.map((a) => a.toJson()).toList()),
        );
      }
    }

    // Update last sync time
    await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Execute a specific offline action
  Future<void> _executeAction(OfflineAction action) async {
    // This would be implemented to call the appropriate service methods
    // based on the action type and data
    switch (action.type) {
      case OfflineActionType.createGroup:
        // Call GroupService.createGroup with action.data
        break;
      case OfflineActionType.addExpense:
        // Call ExpenseService.addExpense with action.data
        break;
      case OfflineActionType.recordSettlement:
        // Call BalanceService.recordSettlement with action.data
        break;
      case OfflineActionType.updateExpense:
        // Call ExpenseService.updateExpense with action.data
        break;
      case OfflineActionType.deleteExpense:
        // Call ExpenseService.deleteExpense with action.data
        break;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    if (_prefs == null) return;

    final keys = _prefs!
        .getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    if (_prefs == null) return null;

    final syncTimeString = _prefs!.getString(_lastSyncKey);
    if (syncTimeString == null) return null;

    try {
      return DateTime.parse(syncTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Start periodic sync when online
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _triggerSync();
      }
    });
  }

  /// Trigger sync of pending actions
  void _triggerSync() {
    syncPendingActions().catchError((e) {
      print('Sync failed: $e');
    });
  }
}

/// Represents an action that was performed offline and needs to be synced
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'] as String,
      type: OfflineActionType.values.firstWhere((e) => e.name == json['type']),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  OfflineAction copyWith({
    String? id,
    OfflineActionType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return OfflineAction(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

enum OfflineActionType {
  createGroup,
  addExpense,
  updateExpense,
  deleteExpense,
  recordSettlement,
}
