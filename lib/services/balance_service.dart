import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'notification_service.dart';

class BalanceService {
  final NotificationService _notificationService;

  BalanceService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  // Protected getters for testing
  @protected
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @protected
  FirebaseAuth get auth => FirebaseAuth.instance;

  // Collection references
  CollectionReference get _expensesCollection =>
      firestore.collection('expenses');
  CollectionReference get _groupsCollection => firestore.collection('groups');
  CollectionReference get _settlementsCollection =>
      firestore.collection('settlements');

  /// Calculates net balances for all members in a group
  Future<List<Balance>> calculateGroupBalances(String groupId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to calculate balances');
    }

    // Verify user is a member of the group
    await _verifyGroupMembership(groupId, currentUser.uid);

    // Get group members
    final group = await _getGroup(groupId);
    final memberIds = group.memberIds;

    // Get all expenses for the group
    final expenses = await _getGroupExpenses(groupId);

    // Get all settlements for the group
    final settlements = await _getGroupSettlements(groupId);

    // Calculate balances for each member
    List<Balance> balances = [];
    for (String memberId in memberIds) {
      final balance = await _calculateMemberBalance(
        memberId,
        groupId,
        memberIds,
        expenses,
        settlements,
      );
      balances.add(balance);
    }

    return balances;
  }

  /// Gets balance for a specific user in a group
  Future<Balance> getUserBalance(String userId, String groupId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to get balance');
    }

    // Verify user is a member of the group
    await _verifyGroupMembership(groupId, currentUser.uid);

    // Get group members
    final group = await _getGroup(groupId);
    final memberIds = group.memberIds;

    if (!memberIds.contains(userId)) {
      throw Exception('User is not a member of this group');
    }

    // Get all expenses for the group
    final expenses = await _getGroupExpenses(groupId);

    // Get all settlements for the group
    final settlements = await _getGroupSettlements(groupId);

    return _calculateMemberBalance(
      userId,
      groupId,
      memberIds,
      expenses,
      settlements,
    );
  }

  /// Simplifies debts to minimize the number of transactions needed
  List<Settlement> simplifyDebts(List<Balance> balances) {
    if (balances.isEmpty) return [];

    // Create lists of creditors (positive balance) and debtors (negative balance)
    List<_DebtNode> creditors = [];
    List<_DebtNode> debtors = [];

    for (Balance balance in balances) {
      if (balance.netBalance > 0.01) {
        // User is owed money
        creditors.add(_DebtNode(balance.userId, balance.netBalance));
      } else if (balance.netBalance < -0.01) {
        // User owes money
        debtors.add(_DebtNode(balance.userId, -balance.netBalance));
      }
    }

    // Generate optimal settlements
    List<Settlement> settlements = [];
    String groupId = balances.isNotEmpty ? balances.first.groupId : '';

    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      _DebtNode creditor = creditors.first;
      _DebtNode debtor = debtors.first;

      // Calculate settlement amount (minimum of what's owed and what's due)
      double settlementAmount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      // Create settlement record
      settlements.add(
        Settlement(
          id: '', // Will be set when actually recorded
          groupId: groupId,
          fromUserId: debtor.userId,
          toUserId: creditor.userId,
          amount: settlementAmount,
          settledAt: DateTime.now(),
        ),
      );

      // Update amounts
      creditor.amount -= settlementAmount;
      debtor.amount -= settlementAmount;

      // Remove settled parties
      if (creditor.amount < 0.01) {
        creditors.removeAt(0);
      }
      if (debtor.amount < 0.01) {
        debtors.removeAt(0);
      }
    }

    return settlements;
  }

  /// Records a settlement between two users
  Future<Settlement> recordSettlement({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? note,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to record settlement');
    }

    // Verify user is a member of the group
    await _verifyGroupMembership(groupId, currentUser.uid);

    // Verify both users are members of the group
    await _verifyGroupMembership(groupId, fromUserId);
    await _verifyGroupMembership(groupId, toUserId);

    // Validate settlement data
    if (fromUserId == toUserId) {
      throw ArgumentError('Cannot settle with yourself');
    }
    if (amount <= 0) {
      throw ArgumentError('Settlement amount must be positive');
    }

    // Verify the settlement makes sense (fromUser actually owes toUser)
    final fromUserBalance = await getUserBalance(fromUserId, groupId);
    if (!fromUserBalance.owes.containsKey(toUserId) ||
        fromUserBalance.owes[toUserId]! < amount - 0.01) {
      throw Exception(
        'Invalid settlement: $fromUserId does not owe $amount to $toUserId',
      );
    }

    final settlementId = _settlementsCollection.doc().id;
    final settlement = Settlement(
      id: settlementId,
      groupId: groupId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      settledAt: DateTime.now(),
      note: note?.trim(),
    );

    // Save settlement to Firestore
    await _settlementsCollection.doc(settlementId).set(settlement.toJson());

    // Send notifications
    try {
      final fromUserName = await _getUserName(settlement.fromUserId);
      final toUserName = await _getUserName(settlement.toUserId);
      final group = await _getGroup(groupId);

      await _notificationService.sendSettlementNotification(
        settlement: settlement,
        fromUserName: fromUserName,
        toUserName: toUserName,
        groupName: group.name,
      );
    } catch (e) {
      // Log notification error but don't fail the settlement
      debugPrint('Failed to send settlement notification: $e');
    }

    return settlement;
  }

  /// Gets settlement history for a group
  Future<List<Settlement>> getGroupSettlements(String groupId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to get settlements');
    }

    // Verify user is a member of the group
    await _verifyGroupMembership(groupId, currentUser.uid);

    return _getGroupSettlements(groupId);
  }

  /// Real-time stream of balances for a group
  Stream<List<Balance>> getGroupBalancesStream(String groupId) {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream balances');
    }

    // Combine streams from expenses and settlements
    return StreamGroup.merge([
      _expensesCollection.where('groupId', isEqualTo: groupId).snapshots(),
      _settlementsCollection.where('groupId', isEqualTo: groupId).snapshots(),
    ]).asyncMap((_) async {
      try {
        return await calculateGroupBalances(groupId);
      } catch (e) {
        throw Exception('Failed to calculate balances: $e');
      }
    });
  }

  /// Real-time stream of balance for a specific user
  Stream<Balance> getUserBalanceStream(String userId, String groupId) {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream balance');
    }

    // Combine streams from expenses and settlements
    return StreamGroup.merge([
      _expensesCollection.where('groupId', isEqualTo: groupId).snapshots(),
      _settlementsCollection.where('groupId', isEqualTo: groupId).snapshots(),
    ]).asyncMap((_) async {
      try {
        return await getUserBalance(userId, groupId);
      } catch (e) {
        throw Exception('Failed to calculate user balance: $e');
      }
    });
  }

  /// Private helper methods

  /// Calculates balance for a specific member
  Future<Balance> _calculateMemberBalance(
    String userId,
    String groupId,
    List<String> memberIds,
    List<Expense> expenses,
    List<Settlement> settlements,
  ) async {
    Map<String, double> owes = {};
    Map<String, double> owedBy = {};

    // Initialize maps with all other members
    for (String memberId in memberIds) {
      if (memberId != userId) {
        owes[memberId] = 0.0;
        owedBy[memberId] = 0.0;
      }
    }

    // Process expenses
    for (Expense expense in expenses) {
      final participantAmounts = expense.participantAmounts;

      // If this user paid for the expense
      if (expense.paidBy == userId) {
        // This user is owed money by other participants
        for (String participantId in expense.split.participants) {
          if (participantId != userId) {
            owedBy[participantId] =
                (owedBy[participantId] ?? 0.0) +
                participantAmounts[participantId]!;
          }
        }
      }

      // If this user participated in the expense but didn't pay
      if (expense.split.participants.contains(userId) &&
          expense.paidBy != userId) {
        // This user owes money to the payer
        owes[expense.paidBy] =
            (owes[expense.paidBy] ?? 0.0) + participantAmounts[userId]!;
      }
    }

    // Process settlements to reduce debts
    for (Settlement settlement in settlements) {
      if (settlement.fromUserId == userId) {
        // This user paid someone
        owes[settlement.toUserId] =
            (owes[settlement.toUserId] ?? 0.0) - settlement.amount;
      } else if (settlement.toUserId == userId) {
        // Someone paid this user
        owedBy[settlement.fromUserId] =
            (owedBy[settlement.fromUserId] ?? 0.0) - settlement.amount;
      }
    }

    // Clean up negative values (shouldn't happen but safety check)
    owes.updateAll((key, value) => value < 0 ? 0.0 : value);
    owedBy.updateAll((key, value) => value < 0 ? 0.0 : value);

    // Remove zero amounts
    owes.removeWhere((key, value) => value < 0.01);
    owedBy.removeWhere((key, value) => value < 0.01);

    return Balance.create(
      userId: userId,
      groupId: groupId,
      owes: owes,
      owedBy: owedBy,
    );
  }

  /// Gets group data
  Future<Group> _getGroup(String groupId) async {
    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }
    return Group.fromJson(groupDoc.data() as Map<String, dynamic>);
  }

  /// Gets all expenses for a group
  Future<List<Expense>> _getGroupExpenses(String groupId) async {
    final querySnapshot = await _expensesCollection
        .where('groupId', isEqualTo: groupId)
        .get();

    return querySnapshot.docs
        .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Gets all settlements for a group
  Future<List<Settlement>> _getGroupSettlements(String groupId) async {
    final querySnapshot = await _settlementsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('settledAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Settlement.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Verifies that a user is a member of a group
  Future<void> _verifyGroupMembership(String groupId, String userId) async {
    final group = await _getGroup(groupId);
    if (!group.memberIds.contains(userId)) {
      throw Exception('User is not a member of this group');
    }
  }

  /// Gets user name by user ID (helper method for notifications)
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await firestore.collection('Users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? userData['email'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }
}

/// Helper class for debt simplification algorithm
class _DebtNode {
  final String userId;
  double amount;

  _DebtNode(this.userId, this.amount);
}

/// StreamGroup implementation for combining multiple streams
class StreamGroup<T> {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    List<StreamSubscription<T>> subscriptions = [];

    controller = StreamController<T>(
      onListen: () {
        for (Stream<T> stream in streams) {
          subscriptions.add(
            stream.listen(controller.add, onError: controller.addError),
          );
        }
      },
      onCancel: () {
        for (StreamSubscription<T> subscription in subscriptions) {
          subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}
