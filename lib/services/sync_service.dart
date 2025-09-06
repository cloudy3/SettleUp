import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'services.dart';

/// Service that manages real-time synchronization and offline caching
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();
  final BalanceService _balanceService = BalanceService();
  final NotificationService _notificationService = NotificationService();

  // Stream controllers for real-time updates
  final StreamController<List<Group>> _groupsController =
      StreamController<List<Group>>.broadcast();
  final StreamController<Map<String, List<Expense>>> _expensesController =
      StreamController<Map<String, List<Expense>>>.broadcast();
  final StreamController<Map<String, List<Balance>>> _balancesController =
      StreamController<Map<String, List<Balance>>>.broadcast();
  final StreamController<List<SettlementNotification>>
  _notificationsController =
      StreamController<List<SettlementNotification>>.broadcast();

  // Stream subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  // Cached data
  List<Group> _cachedGroups = [];
  final Map<String, List<Expense>> _cachedExpenses = {};
  final Map<String, List<Balance>> _cachedBalances = {};
  List<SettlementNotification> _cachedNotifications = [];

  // Getters for streams
  Stream<List<Group>> get groupsStream => _groupsController.stream;
  Stream<Map<String, List<Expense>>> get expensesStream =>
      _expensesController.stream;
  Stream<Map<String, List<Balance>>> get balancesStream =>
      _balancesController.stream;
  Stream<List<SettlementNotification>> get notificationsStream =>
      _notificationsController.stream;

  // Getters for cached data
  List<Group> get cachedGroups => _cachedGroups;
  Map<String, List<Expense>> get cachedExpenses => _cachedExpenses;
  Map<String, List<Balance>> get cachedBalances => _cachedBalances;
  List<SettlementNotification> get cachedNotifications => _cachedNotifications;

  /// Initialize real-time synchronization
  Future<void> initialize() async {
    try {
      await _initializeGroupsSync();
      await _initializeNotificationsSync();
    } catch (e) {
      debugPrint('Failed to initialize sync service: $e');
    }
  }

  /// Initialize groups synchronization
  Future<void> _initializeGroupsSync() async {
    _subscriptions['groups']?.cancel();
    _subscriptions['groups'] = _groupService.getGroupsStream().listen(
      (groups) {
        _cachedGroups = groups;
        _groupsController.add(groups);

        // Initialize expense and balance sync for each group
        for (final group in groups) {
          _initializeGroupDataSync(group.id);
        }
      },
      onError: (error) {
        debugPrint('Groups sync error: $error');
        // Emit cached data on error
        _groupsController.add(_cachedGroups);
      },
    );
  }

  /// Initialize notifications synchronization
  Future<void> _initializeNotificationsSync() async {
    _subscriptions['notifications']?.cancel();
    _subscriptions['notifications'] = _notificationService
        .getUserNotificationsStream()
        .listen(
          (notifications) {
            _cachedNotifications = notifications;
            _notificationsController.add(notifications);
          },
          onError: (error) {
            debugPrint('Notifications sync error: $error');
            // Emit cached data on error
            _notificationsController.add(_cachedNotifications);
          },
        );
  }

  /// Initialize data sync for a specific group
  Future<void> _initializeGroupDataSync(String groupId) async {
    // Initialize expenses sync
    _subscriptions['expenses_$groupId']?.cancel();
    _subscriptions['expenses_$groupId'] = _expenseService
        .getExpensesStream(groupId)
        .listen(
          (expenses) {
            _cachedExpenses[groupId] = expenses;
            _expensesController.add(_cachedExpenses);
          },
          onError: (error) {
            debugPrint('Expenses sync error for group $groupId: $error');
          },
        );

    // Initialize balances sync
    _subscriptions['balances_$groupId']?.cancel();
    _subscriptions['balances_$groupId'] = _balanceService
        .getGroupBalancesStream(groupId)
        .listen(
          (balances) {
            _cachedBalances[groupId] = balances;
            _balancesController.add(_cachedBalances);
          },
          onError: (error) {
            debugPrint('Balances sync error for group $groupId: $error');
          },
        );
  }

  /// Stop sync for a specific group
  void stopGroupSync(String groupId) {
    _subscriptions['expenses_$groupId']?.cancel();
    _subscriptions['balances_$groupId']?.cancel();
    _subscriptions.remove('expenses_$groupId');
    _subscriptions.remove('balances_$groupId');
  }

  /// Update cached data from offline provider
  void updateCachedData({
    List<Group>? groups,
    Map<String, List<Expense>>? expenses,
    Map<String, List<Balance>>? balances,
    List<SettlementNotification>? notifications,
  }) {
    if (groups != null) {
      _cachedGroups = groups;
    }
    if (expenses != null) {
      _cachedExpenses.addAll(expenses);
    }
    if (balances != null) {
      _cachedBalances.addAll(balances);
    }
    if (notifications != null) {
      _cachedNotifications = notifications;
    }
  }

  /// Get expenses for a specific group
  List<Expense> getExpensesForGroup(String groupId) {
    return _cachedExpenses[groupId] ?? [];
  }

  /// Get balances for a specific group
  List<Balance> getBalancesForGroup(String groupId) {
    return _cachedBalances[groupId] ?? [];
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    try {
      // Refresh groups (this will trigger cascade refresh)
      final groups = await _groupService.getGroupsForUser();
      _cachedGroups = groups;
      _groupsController.add(groups);

      // Refresh notifications
      final notifications = await _notificationService.getUserNotifications();
      _cachedNotifications = notifications;
      _notificationsController.add(notifications);
    } catch (e) {
      debugPrint('Failed to refresh all data: $e');
    }
  }

  /// Handle connectivity changes
  void onConnectivityChanged(bool isOnline) {
    if (isOnline) {
      // Reinitialize sync when back online
      initialize();
    } else {
      // Emit cached data when offline
      _groupsController.add(_cachedGroups);
      _expensesController.add(_cachedExpenses);
      _balancesController.add(_cachedBalances);
      _notificationsController.add(_cachedNotifications);
    }
  }

  /// Dispose resources
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _groupsController.close();
    _expensesController.close();
    _balancesController.close();
    _notificationsController.close();
  }
}
