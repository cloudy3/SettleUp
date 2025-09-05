import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _expensesCollection =>
      _firestore.collection('expenses');
  CollectionReference get _groupsCollection => _firestore.collection('groups');

  /// Adds a new expense to a group
  Future<Expense> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required DateTime date,
    required ExpenseSplit split,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to add expense');
    }

    // Validate input parameters
    _validateExpenseInput(
      description: description,
      amount: amount,
      paidBy: paidBy,
      split: split,
    );

    // Verify user is a member of the group
    await _verifyGroupMembership(groupId, currentUser.uid);

    // Verify paidBy user is a group member
    await _verifyGroupMembership(groupId, paidBy);

    // Verify all split participants are group members
    for (final participantId in split.participants) {
      await _verifyGroupMembership(groupId, participantId);
    }

    final now = DateTime.now();
    final expenseId = _expensesCollection.doc().id;

    final expense = Expense(
      id: expenseId,
      groupId: groupId,
      description: description.trim(),
      amount: amount,
      paidBy: paidBy,
      date: date,
      split: split,
      createdBy: currentUser.uid,
      createdAt: now,
    );

    // Final validation
    if (!expense.isValid) {
      throw ArgumentError('Invalid expense data');
    }

    // Save expense to Firestore
    await _expensesCollection.doc(expenseId).set(expense.toJson());

    // Update group's total expenses
    await _updateGroupTotalExpenses(groupId, amount);

    return expense;
  }

  /// Updates an existing expense
  Future<Expense> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    String? paidBy,
    DateTime? date,
    ExpenseSplit? split,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to update expense');
    }

    final expenseDoc = await _expensesCollection.doc(expenseId).get();
    if (!expenseDoc.exists) {
      throw Exception('Expense not found');
    }

    final originalExpense = Expense.fromJson(
      expenseDoc.data() as Map<String, dynamic>,
    );

    // Only creator can update expense
    if (originalExpense.createdBy != currentUser.uid) {
      throw Exception('Only expense creator can update expense');
    }

    // Verify user is still a member of the group
    await _verifyGroupMembership(originalExpense.groupId, currentUser.uid);

    final updatedExpense = originalExpense.copyWith(
      description: description?.trim(),
      amount: amount,
      paidBy: paidBy,
      date: date,
      split: split,
    );

    // Validate updated expense
    if (updatedExpense.description.trim().isEmpty) {
      throw ArgumentError('Description cannot be empty');
    }
    if (updatedExpense.amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (!updatedExpense.split.isValid) {
      throw ArgumentError('Invalid expense split');
    }

    // Verify paidBy user is a group member
    await _verifyGroupMembership(updatedExpense.groupId, updatedExpense.paidBy);

    // Verify all split participants are group members
    for (final participantId in updatedExpense.split.participants) {
      await _verifyGroupMembership(updatedExpense.groupId, participantId);
    }

    if (!updatedExpense.isValid) {
      throw ArgumentError('Invalid updated expense data');
    }

    // Update expense in Firestore
    await _expensesCollection.doc(expenseId).update({
      'description': updatedExpense.description,
      'amount': updatedExpense.amount,
      'paidBy': updatedExpense.paidBy,
      'date': Timestamp.fromDate(updatedExpense.date),
      'split': updatedExpense.split.toJson(),
    });

    // Update group's total expenses if amount changed
    if (originalExpense.amount != updatedExpense.amount) {
      final difference = updatedExpense.amount - originalExpense.amount;
      await _updateGroupTotalExpenses(updatedExpense.groupId, difference);
    }

    return updatedExpense;
  }

  /// Deletes an expense
  Future<void> deleteExpense(String expenseId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete expense');
    }

    final expenseDoc = await _expensesCollection.doc(expenseId).get();
    if (!expenseDoc.exists) {
      throw Exception('Expense not found');
    }

    final expense = Expense.fromJson(expenseDoc.data() as Map<String, dynamic>);

    // Only creator can delete expense
    if (expense.createdBy != currentUser.uid) {
      throw Exception('Only expense creator can delete expense');
    }

    // Verify user is still a member of the group
    await _verifyGroupMembership(expense.groupId, currentUser.uid);

    // Delete expense from Firestore
    await _expensesCollection.doc(expenseId).delete();

    // Update group's total expenses
    await _updateGroupTotalExpenses(expense.groupId, -expense.amount);
  }

  /// Gets all expenses for a group
  Future<List<Expense>> getExpensesForGroup(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to fetch expenses');
    }

    // Verify user is a member of the group
    await _verifyGroupMembership(groupId, currentUser.uid);

    final querySnapshot = await _expensesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Gets a specific expense by ID
  Future<Expense?> getExpenseById(String expenseId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to fetch expense');
    }

    final expenseDoc = await _expensesCollection.doc(expenseId).get();
    if (!expenseDoc.exists) {
      return null;
    }

    final expense = Expense.fromJson(expenseDoc.data() as Map<String, dynamic>);

    // Verify user is a member of the group
    await _verifyGroupMembership(expense.groupId, currentUser.uid);

    return expense;
  }

  /// Creates an equal split for given participants
  ExpenseSplit createEqualSplit(List<String> participants) {
    if (participants.isEmpty) {
      throw ArgumentError('Participants list cannot be empty');
    }

    return ExpenseSplit(
      type: SplitType.equal,
      participants: participants,
      shares: {for (String participant in participants) participant: 1.0},
    );
  }

  /// Creates a custom split with specific amounts
  ExpenseSplit createCustomSplit(Map<String, double> customAmounts) {
    if (customAmounts.isEmpty) {
      throw ArgumentError('Custom amounts cannot be empty');
    }

    for (final amount in customAmounts.values) {
      if (amount < 0) {
        throw ArgumentError('Custom amounts must be non-negative');
      }
    }

    return ExpenseSplit(
      type: SplitType.custom,
      participants: customAmounts.keys.toList(),
      shares: customAmounts,
    );
  }

  /// Creates a percentage split
  ExpenseSplit createPercentageSplit(Map<String, double> percentages) {
    if (percentages.isEmpty) {
      throw ArgumentError('Percentages cannot be empty');
    }

    double totalPercentage = 0;
    for (final percentage in percentages.values) {
      if (percentage < 0 || percentage > 100) {
        throw ArgumentError('Percentages must be between 0 and 100');
      }
      totalPercentage += percentage;
    }

    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError('Percentages must sum to 100');
    }

    return ExpenseSplit(
      type: SplitType.percentage,
      participants: percentages.keys.toList(),
      shares: percentages,
    );
  }

  /// Validates split configuration against total amount
  bool validateSplit(ExpenseSplit split, double totalAmount) {
    if (!split.isValid) return false;
    if (totalAmount <= 0) return false; // Invalid total amount

    final amounts = split.calculateAmounts(totalAmount);
    final calculatedTotal = amounts.values.fold(
      0.0,
      (total, amount) => total + amount,
    );

    // Allow small floating point differences
    return (calculatedTotal - totalAmount).abs() < 0.01;
  }

  /// Real-time stream of expenses for a group
  Stream<List<Expense>> getExpensesStream(String groupId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream expenses');
    }

    return _expensesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          // Verify user is a member of the group for each update
          try {
            await _verifyGroupMembership(groupId, currentUser.uid);
            return snapshot.docs
                .map(
                  (doc) => Expense.fromJson(doc.data() as Map<String, dynamic>),
                )
                .toList();
          } catch (e) {
            throw Exception(
              'Access denied: User is not a member of this group',
            );
          }
        });
  }

  /// Real-time stream of a specific expense
  Stream<Expense?> getExpenseStream(String expenseId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream expense');
    }

    return _expensesCollection.doc(expenseId).snapshots().asyncMap((
      snapshot,
    ) async {
      if (!snapshot.exists) return null;

      final expense = Expense.fromJson(snapshot.data() as Map<String, dynamic>);

      // Verify user is a member of the group
      try {
        await _verifyGroupMembership(expense.groupId, currentUser.uid);
        return expense;
      } catch (e) {
        throw Exception('Access denied: User is not a member of this group');
      }
    });
  }

  /// Private helper methods

  /// Validates expense input parameters
  void _validateExpenseInput({
    required String description,
    required double amount,
    required String paidBy,
    required ExpenseSplit split,
  }) {
    if (description.trim().isEmpty) {
      throw ArgumentError('Description cannot be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (paidBy.isEmpty) {
      throw ArgumentError('PaidBy user ID cannot be empty');
    }
    if (!split.isValid) {
      throw ArgumentError('Invalid expense split');
    }
    if (!split.participants.contains(paidBy)) {
      throw ArgumentError('PaidBy user must be included in split participants');
    }
  }

  /// Verifies that a user is a member of a group
  Future<void> _verifyGroupMembership(String groupId, String userId) async {
    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);
    if (!group.memberIds.contains(userId)) {
      throw Exception('User is not a member of this group');
    }
  }

  /// Updates the total expenses for a group
  Future<void> _updateGroupTotalExpenses(
    String groupId,
    double amountChange,
  ) async {
    await _groupsCollection.doc(groupId).update({
      'totalExpenses': FieldValue.increment(amountChange),
    });
  }
}
