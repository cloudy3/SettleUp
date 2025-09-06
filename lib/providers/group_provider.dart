import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider for managing individual group state with real-time updates
class GroupProvider extends ChangeNotifier {
  final String groupId;
  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();
  final BalanceService _balanceService = BalanceService();

  // Group data
  Group? _group;
  Group? get group => _group;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> get members => _members;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  List<Balance> _balances = [];
  List<Balance> get balances => _balances;

  // Loading states
  bool _isLoadingGroup = false;
  bool get isLoadingGroup => _isLoadingGroup;

  bool _isLoadingExpenses = false;
  bool get isLoadingExpenses => _isLoadingExpenses;

  bool _isLoadingBalances = false;
  bool get isLoadingBalances => _isLoadingBalances;

  // Error states
  String? _error;
  String? get error => _error;

  // Stream subscriptions
  StreamSubscription<Group?>? _groupSubscription;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<List<Balance>>? _balancesSubscription;

  GroupProvider(this.groupId) {
    _initializeStreams();
  }

  /// Initialize all real-time streams for the group
  void _initializeStreams() {
    _loadGroup();
    _loadExpenses();
    _loadBalances();
  }

  /// Load group data with real-time updates
  void _loadGroup() {
    _isLoadingGroup = true;
    _error = null;
    notifyListeners();

    _groupSubscription?.cancel();
    _groupSubscription = _groupService
        .getGroupStream(groupId)
        .listen(
          (group) async {
            _group = group;
            _isLoadingGroup = false;
            _error = null;

            // Load members when group is loaded
            if (group != null) {
              try {
                _members = await _groupService.getGroupMembers(groupId);
              } catch (e) {
                debugPrint('Failed to load group members: $e');
              }
            }

            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load group: $error';
            _isLoadingGroup = false;
            notifyListeners();
          },
        );
  }

  /// Load expenses with real-time updates
  void _loadExpenses() {
    _isLoadingExpenses = true;
    notifyListeners();

    _expensesSubscription?.cancel();
    _expensesSubscription = _expenseService
        .getExpensesStream(groupId)
        .listen(
          (expenses) {
            _expenses = expenses;
            _isLoadingExpenses = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to load expenses: $error');
            _isLoadingExpenses = false;
            notifyListeners();
          },
        );
  }

  /// Load balances with real-time updates
  void _loadBalances() {
    _isLoadingBalances = true;
    notifyListeners();

    _balancesSubscription?.cancel();
    _balancesSubscription = _balanceService
        .getGroupBalancesStream(groupId)
        .listen(
          (balances) {
            _balances = balances;
            _isLoadingBalances = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to load balances: $error');
            _isLoadingBalances = false;
            notifyListeners();
          },
        );
  }

  /// Get member name by user ID
  String getMemberName(String userId) {
    final member = _members.firstWhere(
      (m) => m['id'] == userId,
      orElse: () => {'name': 'Unknown User'},
    );
    return member['name'] ?? 'Unknown User';
  }

  /// Get current user's balance
  Balance? getCurrentUserBalance(String currentUserId) {
    try {
      return _balances.firstWhere((balance) => balance.userId == currentUserId);
    } catch (e) {
      return null;
    }
  }

  /// Add expense (will trigger real-time update)
  Future<void> addExpense({
    required String description,
    required double amount,
    required String paidBy,
    required DateTime date,
    required ExpenseSplit split,
  }) async {
    try {
      await _expenseService.addExpense(
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        date: date,
        split: split,
      );
      // Real-time stream will automatically update the UI
    } catch (e) {
      rethrow;
    }
  }

  /// Update expense (will trigger real-time update)
  Future<void> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    String? paidBy,
    DateTime? date,
    ExpenseSplit? split,
  }) async {
    try {
      await _expenseService.updateExpense(
        expenseId: expenseId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        date: date,
        split: split,
      );
      // Real-time stream will automatically update the UI
    } catch (e) {
      rethrow;
    }
  }

  /// Delete expense (will trigger real-time update)
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expenseService.deleteExpense(expenseId);
      // Real-time stream will automatically update the UI
    } catch (e) {
      rethrow;
    }
  }

  /// Record settlement (will trigger real-time update)
  Future<void> recordSettlement({
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? note,
  }) async {
    try {
      await _balanceService.recordSettlement(
        groupId: groupId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        note: note,
      );
      // Real-time stream will automatically update the UI
    } catch (e) {
      rethrow;
    }
  }

  /// Invite members (will trigger real-time update)
  Future<void> inviteMembers(List<String> emails) async {
    try {
      await _groupService.inviteMembers(groupId: groupId, emails: emails);
      // Real-time stream will automatically update the UI
    } catch (e) {
      rethrow;
    }
  }

  /// Update group (will trigger real-time update)
  Future<void> updateGroup({String? name, String? description}) async {
    try {
      await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
      );
      // Real-time stream will automatically update the UI
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh all data manually
  Future<void> refresh() async {
    _initializeStreams();
  }

  /// Cancel all subscriptions
  void _cancelSubscriptions() {
    _groupSubscription?.cancel();
    _expensesSubscription?.cancel();
    _balancesSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
