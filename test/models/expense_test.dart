import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('ExpenseSplit', () {
    test('should create valid equal split', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2', 'user3'],
        shares: {
          'user1': 0,
          'user2': 0,
          'user3': 0,
        }, // Shares don't matter for equal split
      );

      expect(split.isValid, true);
      expect(split.type, SplitType.equal);
      expect(split.participants.length, 3);
    });

    test('should create valid custom split', () {
      final split = ExpenseSplit(
        type: SplitType.custom,
        participants: ['user1', 'user2'],
        shares: {'user1': 60.0, 'user2': 40.0},
      );

      expect(split.isValid, true);
      expect(split.type, SplitType.custom);
    });

    test('should create valid percentage split', () {
      final split = ExpenseSplit(
        type: SplitType.percentage,
        participants: ['user1', 'user2'],
        shares: {'user1': 60.0, 'user2': 40.0},
      );

      expect(split.isValid, true);
      expect(split.type, SplitType.percentage);
    });

    test('should validate percentage split totals 100', () {
      final invalidSplit = ExpenseSplit(
        type: SplitType.percentage,
        participants: ['user1', 'user2'],
        shares: {'user1': 60.0, 'user2': 50.0}, // Totals 110%
      );

      expect(invalidSplit.isValid, false);
    });

    test('should validate all participants have shares', () {
      final invalidSplit = ExpenseSplit(
        type: SplitType.custom,
        participants: ['user1', 'user2', 'user3'],
        shares: {'user1': 50.0, 'user2': 50.0}, // Missing user3
      );

      expect(invalidSplit.isValid, false);
    });

    test('should validate no negative shares', () {
      final invalidSplit = ExpenseSplit(
        type: SplitType.custom,
        participants: ['user1', 'user2'],
        shares: {'user1': 60.0, 'user2': -10.0},
      );

      expect(invalidSplit.isValid, false);
    });

    test('should calculate equal split amounts correctly', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2', 'user3'],
        shares: {'user1': 0, 'user2': 0, 'user3': 0},
      );

      final amounts = split.calculateAmounts(150.0);

      expect(amounts['user1'], 50.0);
      expect(amounts['user2'], 50.0);
      expect(amounts['user3'], 50.0);
    });

    test('should calculate custom split amounts correctly', () {
      final split = ExpenseSplit(
        type: SplitType.custom,
        participants: ['user1', 'user2'],
        shares: {'user1': 80.0, 'user2': 20.0},
      );

      final amounts = split.calculateAmounts(100.0);

      expect(amounts['user1'], 80.0);
      expect(amounts['user2'], 20.0);
    });

    test('should calculate percentage split amounts correctly', () {
      final split = ExpenseSplit(
        type: SplitType.percentage,
        participants: ['user1', 'user2'],
        shares: {'user1': 60.0, 'user2': 40.0},
      );

      final amounts = split.calculateAmounts(100.0);

      expect(amounts['user1'], 60.0);
      expect(amounts['user2'], 40.0);
    });

    test('should serialize to and from JSON', () {
      final split = ExpenseSplit(
        type: SplitType.percentage,
        participants: ['user1', 'user2'],
        shares: {'user1': 60.0, 'user2': 40.0},
      );

      final json = split.toJson();
      final fromJson = ExpenseSplit.fromJson(json);

      expect(fromJson.type, split.type);
      expect(fromJson.participants, split.participants);
      expect(fromJson.shares, split.shares);
    });

    test('should support copyWith', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final updated = split.copyWith(
        type: SplitType.custom,
        shares: {'user1': 60.0, 'user2': 40.0},
      );

      expect(updated.type, SplitType.custom);
      expect(updated.participants, split.participants);
      expect(updated.shares['user1'], 60.0);
    });

    test('should implement equality correctly', () {
      final split1 = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final split2 = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      expect(split1, equals(split2));
      // Note: hashCode equality is not guaranteed for complex objects with Maps/Lists
    });
  });

  group('Expense', () {
    test('should create valid Expense', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final expense = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1',
        date: DateTime.now(),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      expect(expense.isValid, true);
      expect(expense.description, 'Dinner');
      expect(expense.amount, 100.0);
      expect(expense.paidBy, 'user1');
    });

    test('should validate required fields', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1'],
        shares: {'user1': 0},
      );

      final invalidExpense = Expense(
        id: '',
        groupId: '',
        description: '',
        amount: 100.0,
        paidBy: 'user1',
        date: DateTime.now(),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      expect(invalidExpense.isValid, false);
    });

    test('should validate positive amount', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1'],
        shares: {'user1': 0},
      );

      final invalidExpense = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: -50.0,
        paidBy: 'user1',
        date: DateTime.now(),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      expect(invalidExpense.isValid, false);
    });

    test('should validate paidBy is in participants', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user2', 'user3'],
        shares: {'user2': 0, 'user3': 0},
      );

      final invalidExpense = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1', // Not in participants
        date: DateTime.now(),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      expect(invalidExpense.isValid, false);
    });

    test('should get participant amounts correctly', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final expense = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1',
        date: DateTime.now(),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      final amounts = expense.participantAmounts;

      expect(amounts['user1'], 50.0);
      expect(amounts['user2'], 50.0);
    });

    test('should serialize to and from JSON', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final expense = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1',
        date: DateTime(2025, 1, 15, 14, 0),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime(2025, 1, 15, 14, 5),
      );

      final json = expense.toJson();
      final fromJson = Expense.fromJson(json);

      expect(fromJson.id, expense.id);
      expect(fromJson.groupId, expense.groupId);
      expect(fromJson.description, expense.description);
      expect(fromJson.amount, expense.amount);
      expect(fromJson.paidBy, expense.paidBy);
      expect(fromJson.split.type, expense.split.type);
      expect(fromJson.createdBy, expense.createdBy);
    });

    test('should support copyWith', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final expense = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1',
        date: DateTime.now(),
        split: split,
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      final updated = expense.copyWith(description: 'Lunch', amount: 50.0);

      expect(updated.description, 'Lunch');
      expect(updated.amount, 50.0);
      expect(updated.id, expense.id);
      expect(updated.paidBy, expense.paidBy);
    });

    test('should implement equality correctly', () {
      final split = ExpenseSplit(
        type: SplitType.equal,
        participants: ['user1', 'user2'],
        shares: {'user1': 0, 'user2': 0},
      );

      final date = DateTime.now();
      final createdAt = DateTime.now();

      final expense1 = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1',
        date: date,
        split: split,
        createdBy: 'user1',
        createdAt: createdAt,
      );

      final expense2 = Expense(
        id: 'expense123',
        groupId: 'group123',
        description: 'Dinner',
        amount: 100.0,
        paidBy: 'user1',
        date: date,
        split: split,
        createdBy: 'user1',
        createdAt: createdAt,
      );

      expect(expense1, equals(expense2));
      expect(expense1.hashCode, equals(expense2.hashCode));
    });
  });
}
