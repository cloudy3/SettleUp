import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider for managing offline data caching and synchronization
class OfflineProvider extends ChangeNotifier {
  static const String _groupsCacheKey = 'cached_groups';
  static const String _expensesCacheKey = 'cached_expenses';
  static const String _balancesCacheKey = 'cached_balances';
  static const String _notificationsCacheKey = 'cached_notifications';
  static const String _lastSyncKey = 'last_sync_timestamp';

  SharedPreferences? _prefs;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Cached data
  List<Group> _cachedGroups = [];
  List<Group> get cachedGroups => _cachedGroups;

  final Map<String, List<Expense>> _cachedExpenses = {};
  Map<String, List<Expense>> get cachedExpenses => _cachedExpenses;

  final Map<String, List<Balance>> _cachedBalances = {};
  Map<String, List<Balance>> get cachedBalances => _cachedBalances;

  List<SettlementNotification> _cachedNotifications = [];
  List<SettlementNotification> get cachedNotifications => _cachedNotifications;

  // Pending operations for offline sync
  List<Map<String, dynamic>> _pendingOperations = [];
  List<Map<String, dynamic>> get pendingOperations => _pendingOperations;

  OfflineProvider() {
    _initializePreferences();
  }

  /// Initialize SharedPreferences and load cached data
  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCachedData();
      await _loadLastSyncTime();
    } catch (e) {
      debugPrint('Failed to initialize offline provider: $e');
    }
  }

  /// Update online status
  void updateOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();

      if (isOnline) {
        _syncPendingOperations();
      }
    }
  }

  /// Cache groups data
  Future<void> cacheGroups(List<Group> groups) async {
    try {
      _cachedGroups = groups;
      final groupsJson = groups.map((group) => group.toJson()).toList();
      await _prefs?.setString(_groupsCacheKey, jsonEncode(groupsJson));
      await _updateLastSyncTime();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cache groups: $e');
    }
  }

  /// Cache expenses data for a specific group
  Future<void> cacheExpenses(String groupId, List<Expense> expenses) async {
    try {
      _cachedExpenses[groupId] = expenses;
      final expensesJson = expenses.map((expense) => expense.toJson()).toList();
      await _prefs?.setString(
        '${_expensesCacheKey}_$groupId',
        jsonEncode(expensesJson),
      );
      await _updateLastSyncTime();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cache expenses for group $groupId: $e');
    }
  }

  /// Cache balances data for a specific group
  Future<void> cacheBalances(String groupId, List<Balance> balances) async {
    try {
      _cachedBalances[groupId] = balances;
      final balancesJson = balances.map((balance) => balance.toJson()).toList();
      await _prefs?.setString(
        '${_balancesCacheKey}_$groupId',
        jsonEncode(balancesJson),
      );
      await _updateLastSyncTime();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cache balances for group $groupId: $e');
    }
  }

  /// Cache notifications data
  Future<void> cacheNotifications(
    List<SettlementNotification> notifications,
  ) async {
    try {
      _cachedNotifications = notifications;
      final notificationsJson = notifications
          .map((notification) => notification.toJson())
          .toList();
      await _prefs?.setString(
        _notificationsCacheKey,
        jsonEncode(notificationsJson),
      );
      await _updateLastSyncTime();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cache notifications: $e');
    }
  }

  /// Get cached expenses for a group
  List<Expense> getCachedExpenses(String groupId) {
    return _cachedExpenses[groupId] ?? [];
  }

  /// Get cached balances for a group
  List<Balance> getCachedBalances(String groupId) {
    return _cachedBalances[groupId] ?? [];
  }

  /// Add pending operation for offline sync
  Future<void> addPendingOperation({
    required String type,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final pendingOp = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'operation': operation,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _pendingOperations.add(pendingOp);
      await _savePendingOperations();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add pending operation: $e');
    }
  }

  /// Sync pending operations when back online
  Future<void> _syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    try {
      final List<Map<String, dynamic>> failedOperations = [];

      for (final operation in _pendingOperations) {
        try {
          await _executePendingOperation(operation);
        } catch (e) {
          debugPrint('Failed to sync operation ${operation['id']}: $e');
          failedOperations.add(operation);
        }
      }

      // Keep only failed operations for retry
      _pendingOperations = failedOperations;
      await _savePendingOperations();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to sync pending operations: $e');
    }
  }

  /// Execute a single pending operation
  Future<void> _executePendingOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final operationType = operation['operation'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (type) {
      case 'expense':
        await _syncExpenseOperation(operationType, data);
        break;
      case 'group':
        await _syncGroupOperation(operationType, data);
        break;
      case 'settlement':
        await _syncSettlementOperation(operationType, data);
        break;
      default:
        debugPrint('Unknown operation type: $type');
    }
  }

  /// Sync expense operations
  Future<void> _syncExpenseOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    final expenseService = ExpenseService();

    switch (operation) {
      case 'add':
        await expenseService.addExpense(
          groupId: data['groupId'],
          description: data['description'],
          amount: data['amount'],
          paidBy: data['paidBy'],
          date: DateTime.parse(data['date']),
          split: ExpenseSplit.fromJson(data['split']),
        );
        break;
      case 'update':
        await expenseService.updateExpense(
          expenseId: data['expenseId'],
          description: data['description'],
          amount: data['amount'],
          paidBy: data['paidBy'],
          date: data['date'] != null ? DateTime.parse(data['date']) : null,
          split: data['split'] != null
              ? ExpenseSplit.fromJson(data['split'])
              : null,
        );
        break;
      case 'delete':
        await expenseService.deleteExpense(data['expenseId']);
        break;
    }
  }

  /// Sync group operations
  Future<void> _syncGroupOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    final groupService = GroupService();

    switch (operation) {
      case 'create':
        await groupService.createGroup(
          name: data['name'],
          description: data['description'],
        );
        break;
      case 'update':
        await groupService.updateGroup(
          groupId: data['groupId'],
          name: data['name'],
          description: data['description'],
        );
        break;
      case 'invite':
        await groupService.inviteMembers(
          groupId: data['groupId'],
          emails: List<String>.from(data['emails']),
        );
        break;
    }
  }

  /// Sync settlement operations
  Future<void> _syncSettlementOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    final balanceService = BalanceService();

    switch (operation) {
      case 'record':
        await balanceService.recordSettlement(
          groupId: data['groupId'],
          fromUserId: data['fromUserId'],
          toUserId: data['toUserId'],
          amount: data['amount'],
          note: data['note'],
        );
        break;
    }
  }

  /// Load cached data from SharedPreferences
  Future<void> _loadCachedData() async {
    try {
      // Load cached groups
      final groupsJson = _prefs?.getString(_groupsCacheKey);
      if (groupsJson != null) {
        final groupsList = jsonDecode(groupsJson) as List;
        _cachedGroups = groupsList
            .map((json) => Group.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load cached notifications
      final notificationsJson = _prefs?.getString(_notificationsCacheKey);
      if (notificationsJson != null) {
        final notificationsList = jsonDecode(notificationsJson) as List;
        _cachedNotifications = notificationsList
            .map(
              (json) =>
                  SettlementNotification.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      // Load pending operations
      await _loadPendingOperations();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cached data: $e');
    }
  }

  /// Load last sync time
  Future<void> _loadLastSyncTime() async {
    try {
      final lastSyncString = _prefs?.getString(_lastSyncKey);
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      debugPrint('Failed to load last sync time: $e');
    }
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    try {
      _lastSyncTime = DateTime.now();
      await _prefs?.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
    } catch (e) {
      debugPrint('Failed to update last sync time: $e');
    }
  }

  /// Save pending operations to SharedPreferences
  Future<void> _savePendingOperations() async {
    try {
      await _prefs?.setString(
        'pending_operations',
        jsonEncode(_pendingOperations),
      );
    } catch (e) {
      debugPrint('Failed to save pending operations: $e');
    }
  }

  /// Load pending operations from SharedPreferences
  Future<void> _loadPendingOperations() async {
    try {
      final pendingJson = _prefs?.getString('pending_operations');
      if (pendingJson != null) {
        final pendingList = jsonDecode(pendingJson) as List;
        _pendingOperations = pendingList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Failed to load pending operations: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      _cachedGroups.clear();
      _cachedExpenses.clear();
      _cachedBalances.clear();
      _cachedNotifications.clear();
      _pendingOperations.clear();

      await _prefs?.remove(_groupsCacheKey);
      await _prefs?.remove(_expensesCacheKey);
      await _prefs?.remove(_balancesCacheKey);
      await _prefs?.remove(_notificationsCacheKey);
      await _prefs?.remove('pending_operations');
      await _prefs?.remove(_lastSyncKey);

      _lastSyncTime = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get cache size information
  Map<String, int> getCacheInfo() {
    return {
      'groups': _cachedGroups.length,
      'expenses': _cachedExpenses.values.fold(
        0,
        (sum, list) => sum + list.length,
      ),
      'balances': _cachedBalances.values.fold(
        0,
        (sum, list) => sum + list.length,
      ),
      'notifications': _cachedNotifications.length,
      'pendingOperations': _pendingOperations.length,
    };
  }
}
