import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('Expense Workflow Integration Tests', () {
    const String testUserId = 'test_user_123';
    const String otherUserId = 'other_user_456';
    const String thirdUserId = 'third_user_789';
    const String testGroupId = 'test_group_123';

    group('Expense Addition with Various Split Types', () {
      testWidgets('should add equal split expense correctly', (tester) async {
        // Create expense with equal split
        final expense = Expense(
          id: 'expense_1',
          groupId: testGroupId,
          description: 'Dinner',
          amount: 300.0,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0, thirdUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, isTrue);
        expect(expense.split.isValid, isTrue);

        // Calculate participant amounts
        final participantAmounts = expense.participantAmounts;
        expect(participantAmounts[testUserId], 100.0);
        expect(participantAmounts[otherUserId], 100.0);
        expect(participantAmounts[thirdUserId], 100.0);

        // Verify total adds up
        final total = participantAmounts.values.fold(
          0.0,
          (sum, amount) => sum + amount,
        );
        expect(total, expense.amount);
      });

      testWidgets('should add custom split expense correctly', (tester) async {
        // Create expense with custom split
        final expense = Expense(
          id: 'expense_2',
          groupId: testGroupId,
          description: 'Groceries',
          amount: 200.0,
          paidBy: otherUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.custom,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 80.0, otherUserId: 60.0, thirdUserId: 60.0},
          ),
          createdBy: otherUserId,
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, isTrue);
        expect(expense.split.isValid, isTrue);

        // Calculate participant amounts
        final participantAmounts = expense.participantAmounts;
        expect(participantAmounts[testUserId], 80.0);
        expect(participantAmounts[otherUserId], 60.0);
        expect(participantAmounts[thirdUserId], 60.0);

        // Verify total adds up
        final total = participantAmounts.values.fold(
          0.0,
          (sum, amount) => sum + amount,
        );
        expect(total, expense.amount);
      });

      testWidgets('should add percentage split expense correctly', (
        tester,
      ) async {
        // Create expense with percentage split
        final expense = Expense(
          id: 'expense_3',
          groupId: testGroupId,
          description: 'Utilities',
          amount: 150.0,
          paidBy: thirdUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.percentage,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 50.0, otherUserId: 30.0, thirdUserId: 20.0},
          ),
          createdBy: thirdUserId,
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, isTrue);
        expect(expense.split.isValid, isTrue);

        // Calculate participant amounts
        final participantAmounts = expense.participantAmounts;
        expect(participantAmounts[testUserId], 75.0);
        expect(participantAmounts[otherUserId], 45.0);
        expect(participantAmounts[thirdUserId], 30.0);

        // Verify total adds up
        final total = participantAmounts.values.fold(
          0.0,
          (sum, amount) => sum + amount,
        );
        expect(total, expense.amount);
      });

      testWidgets('should validate expense data correctly', (tester) async {
        // Test invalid expenses
        final invalidExpenses = [
          // Empty description
          Expense(
            id: 'invalid_1',
            groupId: testGroupId,
            description: '',
            amount: 100.0,
            paidBy: testUserId,
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.equal,
              participants: [testUserId, otherUserId],
              shares: {testUserId: 1.0, otherUserId: 1.0},
            ),
            createdBy: testUserId,
            createdAt: DateTime.now(),
          ),
          // Zero amount
          Expense(
            id: 'invalid_2',
            groupId: testGroupId,
            description: 'Test',
            amount: 0.0,
            paidBy: testUserId,
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.equal,
              participants: [testUserId, otherUserId],
              shares: {testUserId: 1.0, otherUserId: 1.0},
            ),
            createdBy: testUserId,
            createdAt: DateTime.now(),
          ),
          // Payer not in participants
          Expense(
            id: 'invalid_3',
            groupId: testGroupId,
            description: 'Test',
            amount: 100.0,
            paidBy: thirdUserId,
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.equal,
              participants: [testUserId, otherUserId],
              shares: {testUserId: 1.0, otherUserId: 1.0},
            ),
            createdBy: testUserId,
            createdAt: DateTime.now(),
          ),
        ];

        for (final expense in invalidExpenses) {
          expect(expense.isValid, isFalse);
        }

        // Test valid expense
        final validExpense = Expense(
          id: 'valid_1',
          groupId: testGroupId,
          description: 'Valid Expense',
          amount: 100.0,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        expect(validExpense.isValid, isTrue);
      });
    });

    group('Balance Calculations', () {
      testWidgets('should calculate balances correctly for equal split', (
        tester,
      ) async {
        // Create expense where testUser paid for 3 people
        final expense = Expense(
          id: 'expense_1',
          groupId: testGroupId,
          description: 'Dinner',
          amount: 300.0,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0, thirdUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        final participantAmounts = expense.participantAmounts;

        // Calculate balances for testUser (who paid)
        final testUserBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {},
          owedBy: {
            otherUserId: participantAmounts[otherUserId]!,
            thirdUserId: participantAmounts[thirdUserId]!,
          },
        );

        expect(
          testUserBalance.netBalance,
          200.0,
        ); // Paid 300, owes 100, net +200
        expect(testUserBalance.owedBy[otherUserId], 100.0);
        expect(testUserBalance.owedBy[thirdUserId], 100.0);

        // Calculate balances for otherUser (who owes)
        final otherUserBalance = Balance.create(
          userId: otherUserId,
          groupId: testGroupId,
          owes: {testUserId: participantAmounts[otherUserId]!},
          owedBy: {},
        );

        expect(otherUserBalance.netBalance, -100.0); // Owes 100
        expect(otherUserBalance.owes[testUserId], 100.0);
      });

      testWidgets('should calculate balances correctly for custom split', (
        tester,
      ) async {
        // Create expense with custom split
        final expense = Expense(
          id: 'expense_2',
          groupId: testGroupId,
          description: 'Groceries',
          amount: 200.0,
          paidBy: otherUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.custom,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 80.0, otherUserId: 60.0, thirdUserId: 60.0},
          ),
          createdBy: otherUserId,
          createdAt: DateTime.now(),
        );

        final participantAmounts = expense.participantAmounts;

        // Calculate balances for otherUser (who paid)
        final otherUserBalance = Balance.create(
          userId: otherUserId,
          groupId: testGroupId,
          owes: {},
          owedBy: {
            testUserId: participantAmounts[testUserId]!,
            thirdUserId: participantAmounts[thirdUserId]!,
          },
        );

        expect(
          otherUserBalance.netBalance,
          140.0,
        ); // Paid 200, owes 60, net +140
        expect(otherUserBalance.owedBy[testUserId], 80.0);
        expect(otherUserBalance.owedBy[thirdUserId], 60.0);

        // Calculate balances for testUser (who owes)
        final testUserBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: participantAmounts[testUserId]!},
          owedBy: {},
        );

        expect(testUserBalance.netBalance, -80.0); // Owes 80
        expect(testUserBalance.owes[otherUserId], 80.0);
      });

      testWidgets('should handle multiple expenses and cumulative balances', (
        tester,
      ) async {
        // Create multiple expenses
        final expenses = [
          Expense(
            id: 'expense_1',
            groupId: testGroupId,
            description: 'Dinner',
            amount: 150.0,
            paidBy: testUserId,
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.equal,
              participants: [testUserId, otherUserId],
              shares: {testUserId: 1.0, otherUserId: 1.0},
            ),
            createdBy: testUserId,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 'expense_2',
            groupId: testGroupId,
            description: 'Lunch',
            amount: 100.0,
            paidBy: otherUserId,
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.equal,
              participants: [testUserId, otherUserId],
              shares: {testUserId: 1.0, otherUserId: 1.0},
            ),
            createdBy: otherUserId,
            createdAt: DateTime.now(),
          ),
        ];

        // Calculate cumulative balances
        Map<String, double> testUserOwes = {};
        Map<String, double> testUserOwedBy = {};

        for (final expense in expenses) {
          final participantAmounts = expense.participantAmounts;

          if (expense.paidBy == testUserId) {
            // Test user paid, others owe them
            for (final participantId in expense.split.participants) {
              if (participantId != testUserId) {
                testUserOwedBy[participantId] =
                    (testUserOwedBy[participantId] ?? 0.0) +
                    participantAmounts[participantId]!;
              }
            }
          } else if (expense.split.participants.contains(testUserId)) {
            // Test user participated but didn't pay
            testUserOwes[expense.paidBy] =
                (testUserOwes[expense.paidBy] ?? 0.0) +
                participantAmounts[testUserId]!;
          }
        }

        final testUserBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: testUserOwes,
          owedBy: testUserOwedBy,
        );

        // Test user: paid 150 (owedBy 75), owes 50, net = +25
        expect(testUserBalance.netBalance, 25.0);
        expect(testUserBalance.owedBy[otherUserId], 75.0);
        expect(testUserBalance.owes[otherUserId], 50.0);
      });
    });

    group('Expense Editing and Deletion', () {
      testWidgets('should handle expense editing correctly', (tester) async {
        // Original expense
        final originalExpense = Expense(
          id: 'expense_1',
          groupId: testGroupId,
          description: 'Original Description',
          amount: 100.0,
          paidBy: testUserId,
          date: DateTime(2025, 1, 15),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime(2025, 1, 15, 10, 0),
        );

        // Edit expense
        final editedExpense = originalExpense.copyWith(
          description: 'Updated Description',
          amount: 150.0,
        );

        expect(editedExpense.description, 'Updated Description');
        expect(editedExpense.amount, 150.0);
        expect(editedExpense.id, originalExpense.id);
        expect(editedExpense.paidBy, originalExpense.paidBy);
        expect(editedExpense.createdBy, originalExpense.createdBy);

        // Verify edited expense is valid
        expect(editedExpense.isValid, isTrue);

        // Verify balance recalculation
        final newParticipantAmounts = editedExpense.participantAmounts;
        expect(newParticipantAmounts[testUserId], 75.0);
        expect(newParticipantAmounts[otherUserId], 75.0);
      });

      testWidgets('should handle expense split modification', (tester) async {
        // Original expense with equal split
        final originalExpense = Expense(
          id: 'expense_1',
          groupId: testGroupId,
          description: 'Test Expense',
          amount: 120.0,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0, thirdUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        // Change to custom split
        final editedExpense = originalExpense.copyWith(
          split: ExpenseSplit(
            type: SplitType.custom,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 60.0, otherUserId: 40.0, thirdUserId: 20.0},
          ),
        );

        expect(editedExpense.split.type, SplitType.custom);
        expect(editedExpense.isValid, isTrue);

        // Verify new participant amounts
        final newAmounts = editedExpense.participantAmounts;
        expect(newAmounts[testUserId], 60.0);
        expect(newAmounts[otherUserId], 40.0);
        expect(newAmounts[thirdUserId], 20.0);
      });

      testWidgets('should validate expense deletion impact', (tester) async {
        // Create expense that affects balances
        final expense = Expense(
          id: 'expense_to_delete',
          groupId: testGroupId,
          description: 'To be deleted',
          amount: 200.0,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        // Calculate balance before deletion
        final balanceBeforeDeletion = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {},
          owedBy: {otherUserId: 100.0},
        );

        expect(balanceBeforeDeletion.netBalance, 100.0);

        // Simulate deletion by removing the expense impact
        final balanceAfterDeletion = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {},
          owedBy: {},
        );

        expect(balanceAfterDeletion.netBalance, 0.0);
        expect(balanceAfterDeletion.isSettledUp, isTrue);
      });
    });

    group('Expense Data Integrity', () {
      testWidgets('should maintain data consistency during serialization', (
        tester,
      ) async {
        final expense = Expense(
          id: 'test_expense',
          groupId: testGroupId,
          description: 'Serialization Test',
          amount: 123.45,
          paidBy: testUserId,
          date: DateTime(2025, 1, 15, 14, 30, 45),
          split: ExpenseSplit(
            type: SplitType.percentage,
            participants: [testUserId, otherUserId, thirdUserId],
            shares: {testUserId: 40.0, otherUserId: 35.0, thirdUserId: 25.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime(2025, 1, 15, 14, 0, 0),
        );

        // Serialize to JSON
        final json = expense.toJson();

        // Verify JSON structure
        expect(json['id'], 'test_expense');
        expect(json['description'], 'Serialization Test');
        expect(json['amount'], 123.45);
        expect(json['paidBy'], testUserId);

        // Deserialize from JSON
        final deserializedExpense = Expense.fromJson(json);

        // Verify deserialized expense matches original
        expect(deserializedExpense.id, expense.id);
        expect(deserializedExpense.description, expense.description);
        expect(deserializedExpense.amount, expense.amount);
        expect(deserializedExpense.paidBy, expense.paidBy);
        expect(deserializedExpense.split.type, expense.split.type);
        expect(
          deserializedExpense.split.participants,
          expense.split.participants,
        );
        expect(deserializedExpense.split.shares, expense.split.shares);
      });

      testWidgets('should handle edge cases in expense data', (tester) async {
        // Test with very small amounts
        final smallAmountExpense = Expense(
          id: 'small_expense',
          groupId: testGroupId,
          description: 'Small Amount',
          amount: 0.01,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        expect(smallAmountExpense.isValid, isTrue);
        final smallAmounts = smallAmountExpense.participantAmounts;
        expect(smallAmounts[testUserId], 0.005);
        expect(smallAmounts[otherUserId], 0.005);

        // Test with large amounts
        final largeAmountExpense = Expense(
          id: 'large_expense',
          groupId: testGroupId,
          description: 'Large Amount',
          amount: 999999.99,
          paidBy: testUserId,
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: [testUserId, otherUserId],
            shares: {testUserId: 1.0, otherUserId: 1.0},
          ),
          createdBy: testUserId,
          createdAt: DateTime.now(),
        );

        expect(largeAmountExpense.isValid, isTrue);
        final largeAmounts = largeAmountExpense.participantAmounts;
        expect(largeAmounts[testUserId], 499999.995);
        expect(largeAmounts[otherUserId], 499999.995);
      });
    });
  });
}
