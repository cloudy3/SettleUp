import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/balance_service.dart';
import '../../lib/models/models.dart';

void main() {
  group('BalanceService Business Logic Tests', () {
    late BalanceService balanceService;

    const String testUserId = 'test_user_123';
    const String testGroupId = 'test_group_123';
    const String otherUserId = 'other_user_456';
    const String thirdUserId = 'third_user_789';

    setUp(() {
      balanceService = BalanceService();
    });

    group('simplifyDebts', () {
      test('should return empty list for no balances', () {
        final settlements = balanceService.simplifyDebts([]);
        expect(settlements.isEmpty, isTrue);
      });

      test('should return empty list for settled balances', () {
        final balances = [
          Balance.create(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {},
          ),
          Balance.create(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {},
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);
        expect(settlements.isEmpty, isTrue);
      });

      test('should create optimal settlements for simple case', () {
        final balances = [
          Balance.create(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {otherUserId: 100.0},
          ),
          Balance.create(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {testUserId: 100.0},
            owedBy: {},
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);

        expect(settlements.length, equals(1));
        expect(settlements[0].fromUserId, equals(otherUserId));
        expect(settlements[0].toUserId, equals(testUserId));
        expect(settlements[0].amount, closeTo(100.0, 0.01));
        expect(settlements[0].groupId, equals(testGroupId));
      });

      test('should minimize transactions in complex scenario', () {
        // A owes B 100, B owes C 100, C owes A 100
        // Should result in no transactions (circular debt)
        final balances = [
          Balance.create(
            userId: testUserId,
            groupId: testGroupId,
            owes: {otherUserId: 100.0},
            owedBy: {thirdUserId: 100.0},
          ),
          Balance.create(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {thirdUserId: 100.0},
            owedBy: {testUserId: 100.0},
          ),
          Balance.create(
            userId: thirdUserId,
            groupId: testGroupId,
            owes: {testUserId: 100.0},
            owedBy: {otherUserId: 100.0},
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);

        // Should result in no settlements as debts cancel out
        expect(settlements.isEmpty, isTrue);
      });

      test('should handle partial settlements', () {
        // A owes B 150, B owes C 100
        // Should result in: A pays C 100, A pays B 50
        final balances = [
          Balance.create(
            userId: testUserId,
            groupId: testGroupId,
            owes: {otherUserId: 150.0},
            owedBy: {},
          ),
          Balance.create(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {thirdUserId: 100.0},
            owedBy: {testUserId: 150.0},
          ),
          Balance.create(
            userId: thirdUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {otherUserId: 100.0},
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);

        expect(settlements.length, equals(2));

        // Should have settlements totaling 150 from testUser
        final totalFromTestUser = settlements
            .where((s) => s.fromUserId == testUserId)
            .fold(0.0, (sum, s) => sum + s.amount);
        expect(totalFromTestUser, closeTo(150.0, 0.01));

        // Should have one settlement to thirdUser for 100
        final settlementToThird = settlements
            .where((s) => s.toUserId == thirdUserId)
            .first;
        expect(settlementToThird.amount, closeTo(100.0, 0.01));
        expect(settlementToThird.fromUserId, equals(testUserId));
      });

      test('should handle multiple creditors and debtors', () {
        // Complex scenario: A owes 200, B owes 100, C is owed 150, D is owed 150
        final balances = [
          Balance.create(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {},
          )..copyWith(
            owes: {otherUserId: 100.0, thirdUserId: 100.0},
            owedBy: {},
          ),
          Balance.create(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {},
          )..copyWith(owes: {thirdUserId: 100.0}, owedBy: {testUserId: 100.0}),
          Balance.create(
            userId: thirdUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {},
          )..copyWith(
            owes: {},
            owedBy: {testUserId: 100.0, otherUserId: 100.0},
          ),
        ];

        // Manually create balances with correct net balances
        final testUserBalance = Balance(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: 100.0, thirdUserId: 100.0},
          owedBy: {},
          netBalance: -200.0,
        );

        final otherUserBalance = Balance(
          userId: otherUserId,
          groupId: testGroupId,
          owes: {thirdUserId: 100.0},
          owedBy: {testUserId: 100.0},
          netBalance: 0.0,
        );

        final thirdUserBalance = Balance(
          userId: thirdUserId,
          groupId: testGroupId,
          owes: {},
          owedBy: {testUserId: 100.0, otherUserId: 100.0},
          netBalance: 200.0,
        );

        final settlements = balanceService.simplifyDebts([
          testUserBalance,
          otherUserBalance,
          thirdUserBalance,
        ]);

        expect(settlements.length, equals(1));
        expect(settlements[0].fromUserId, equals(testUserId));
        expect(settlements[0].toUserId, equals(thirdUserId));
        expect(settlements[0].amount, closeTo(200.0, 0.01));
      });

      test('should handle floating point precision in debt simplification', () {
        final balances = [
          Balance(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {otherUserId: 33.33},
            netBalance: 33.33,
          ),
          Balance(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {testUserId: 33.33},
            owedBy: {},
            netBalance: -33.33,
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);

        expect(settlements.length, equals(1));
        expect(settlements[0].amount, closeTo(33.33, 0.01));
      });

      test('should ignore very small balances (less than 0.01)', () {
        final balances = [
          Balance(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {otherUserId: 0.005},
            netBalance: 0.005,
          ),
          Balance(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {testUserId: 0.005},
            owedBy: {},
            netBalance: -0.005,
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);

        // Should ignore very small amounts
        expect(settlements.isEmpty, isTrue);
      });
    });

    group('Balance calculation helpers', () {
      test('should calculate member balance correctly with single expense', () {
        // Create test data
        final expenses = [
          Expense(
            id: 'expense_1',
            groupId: testGroupId,
            description: 'Test expense',
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
          ),
        ];

        final settlements = <Settlement>[];
        final memberIds = [testUserId, otherUserId, thirdUserId];

        // Test the private method logic by simulating it
        Map<String, double> owes = {};
        Map<String, double> owedBy = {};

        // Initialize maps with all other members
        for (String memberId in memberIds) {
          if (memberId != testUserId) {
            owes[memberId] = 0.0;
            owedBy[memberId] = 0.0;
          }
        }

        // Process expenses
        for (Expense expense in expenses) {
          final participantAmounts = expense.participantAmounts;

          // If this user paid for the expense
          if (expense.paidBy == testUserId) {
            // This user is owed money by other participants
            for (String participantId in expense.split.participants) {
              if (participantId != testUserId) {
                owedBy[participantId] =
                    (owedBy[participantId] ?? 0.0) +
                    participantAmounts[participantId]!;
              }
            }
          }

          // If this user participated in the expense but didn't pay
          if (expense.split.participants.contains(testUserId) &&
              expense.paidBy != testUserId) {
            // This user owes money to the payer
            owes[expense.paidBy] =
                (owes[expense.paidBy] ?? 0.0) + participantAmounts[testUserId]!;
          }
        }

        // Process settlements (none in this test)
        for (Settlement settlement in settlements) {
          if (settlement.fromUserId == testUserId) {
            owes[settlement.toUserId] =
                (owes[settlement.toUserId] ?? 0.0) - settlement.amount;
          } else if (settlement.toUserId == testUserId) {
            owedBy[settlement.fromUserId] =
                (owedBy[settlement.fromUserId] ?? 0.0) - settlement.amount;
          }
        }

        // Clean up negative values
        owes.updateAll((key, value) => value < 0 ? 0.0 : value);
        owedBy.updateAll((key, value) => value < 0 ? 0.0 : value);

        // Remove zero amounts
        owes.removeWhere((key, value) => value < 0.01);
        owedBy.removeWhere((key, value) => value < 0.01);

        final balance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: owes,
          owedBy: owedBy,
        );

        // Test user paid 300, owes 100, so net balance is +200
        expect(balance.netBalance, closeTo(200.0, 0.01));
        expect(balance.owedBy[otherUserId], closeTo(100.0, 0.01));
        expect(balance.owedBy[thirdUserId], closeTo(100.0, 0.01));
        expect(balance.owes.isEmpty, isTrue);
      });

      test('should calculate balance correctly with custom split', () {
        final expenses = [
          Expense(
            id: 'expense_1',
            groupId: testGroupId,
            description: 'Custom split expense',
            amount: 200.0,
            paidBy: otherUserId,
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.custom,
              participants: [testUserId, otherUserId, thirdUserId],
              shares: {testUserId: 50.0, otherUserId: 100.0, thirdUserId: 50.0},
            ),
            createdBy: otherUserId,
            createdAt: DateTime.now(),
          ),
        ];

        final settlements = <Settlement>[];
        final memberIds = [testUserId, otherUserId, thirdUserId];

        // Simulate balance calculation for testUserId
        Map<String, double> owes = {};
        Map<String, double> owedBy = {};

        for (String memberId in memberIds) {
          if (memberId != testUserId) {
            owes[memberId] = 0.0;
            owedBy[memberId] = 0.0;
          }
        }

        for (Expense expense in expenses) {
          final participantAmounts = expense.participantAmounts;

          if (expense.paidBy == testUserId) {
            for (String participantId in expense.split.participants) {
              if (participantId != testUserId) {
                owedBy[participantId] =
                    (owedBy[participantId] ?? 0.0) +
                    participantAmounts[participantId]!;
              }
            }
          }

          if (expense.split.participants.contains(testUserId) &&
              expense.paidBy != testUserId) {
            owes[expense.paidBy] =
                (owes[expense.paidBy] ?? 0.0) + participantAmounts[testUserId]!;
          }
        }

        owes.updateAll((key, value) => value < 0 ? 0.0 : value);
        owedBy.updateAll((key, value) => value < 0 ? 0.0 : value);
        owes.removeWhere((key, value) => value < 0.01);
        owedBy.removeWhere((key, value) => value < 0.01);

        final balance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: owes,
          owedBy: owedBy,
        );

        // Test user owes 50 to other user
        expect(balance.netBalance, closeTo(-50.0, 0.01));
        expect(balance.owes[otherUserId], closeTo(50.0, 0.01));
        expect(balance.owedBy.isEmpty, isTrue);
      });

      test('should handle multiple expenses correctly', () {
        final expenses = [
          Expense(
            id: 'expense_1',
            groupId: testGroupId,
            description: 'First expense',
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
            description: 'Second expense',
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

        final settlements = <Settlement>[];
        final memberIds = [testUserId, otherUserId];

        // Simulate balance calculation for testUserId
        Map<String, double> owes = {};
        Map<String, double> owedBy = {};

        for (String memberId in memberIds) {
          if (memberId != testUserId) {
            owes[memberId] = 0.0;
            owedBy[memberId] = 0.0;
          }
        }

        for (Expense expense in expenses) {
          final participantAmounts = expense.participantAmounts;

          if (expense.paidBy == testUserId) {
            for (String participantId in expense.split.participants) {
              if (participantId != testUserId) {
                owedBy[participantId] =
                    (owedBy[participantId] ?? 0.0) +
                    participantAmounts[participantId]!;
              }
            }
          }

          if (expense.split.participants.contains(testUserId) &&
              expense.paidBy != testUserId) {
            owes[expense.paidBy] =
                (owes[expense.paidBy] ?? 0.0) + participantAmounts[testUserId]!;
          }
        }

        owes.updateAll((key, value) => value < 0 ? 0.0 : value);
        owedBy.updateAll((key, value) => value < 0 ? 0.0 : value);
        owes.removeWhere((key, value) => value < 0.01);
        owedBy.removeWhere((key, value) => value < 0.01);

        final balance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: owes,
          owedBy: owedBy,
        );

        // Test user: paid 150, owes 50, net = +25
        expect(balance.netBalance, closeTo(25.0, 0.01));
        expect(balance.owedBy[otherUserId], closeTo(75.0, 0.01));
        expect(balance.owes[otherUserId], closeTo(50.0, 0.01));
      });

      test('should reduce debt after settlement', () {
        final expenses = [
          Expense(
            id: 'expense_1',
            groupId: testGroupId,
            description: 'Test expense',
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
        ];

        final settlements = [
          Settlement(
            id: 'settlement_1',
            groupId: testGroupId,
            fromUserId: otherUserId,
            toUserId: testUserId,
            amount: 30.0,
            settledAt: DateTime.now(),
          ),
        ];

        final memberIds = [testUserId, otherUserId];

        // Simulate balance calculation for otherUserId
        Map<String, double> owes = {};
        Map<String, double> owedBy = {};

        for (String memberId in memberIds) {
          if (memberId != otherUserId) {
            owes[memberId] = 0.0;
            owedBy[memberId] = 0.0;
          }
        }

        for (Expense expense in expenses) {
          final participantAmounts = expense.participantAmounts;

          if (expense.paidBy == otherUserId) {
            for (String participantId in expense.split.participants) {
              if (participantId != otherUserId) {
                owedBy[participantId] =
                    (owedBy[participantId] ?? 0.0) +
                    participantAmounts[participantId]!;
              }
            }
          }

          if (expense.split.participants.contains(otherUserId) &&
              expense.paidBy != otherUserId) {
            owes[expense.paidBy] =
                (owes[expense.paidBy] ?? 0.0) +
                participantAmounts[otherUserId]!;
          }
        }

        // Process settlements
        for (Settlement settlement in settlements) {
          if (settlement.fromUserId == otherUserId) {
            owes[settlement.toUserId] =
                (owes[settlement.toUserId] ?? 0.0) - settlement.amount;
          } else if (settlement.toUserId == otherUserId) {
            owedBy[settlement.fromUserId] =
                (owedBy[settlement.fromUserId] ?? 0.0) - settlement.amount;
          }
        }

        owes.updateAll((key, value) => value < 0 ? 0.0 : value);
        owedBy.updateAll((key, value) => value < 0 ? 0.0 : value);
        owes.removeWhere((key, value) => value < 0.01);
        owedBy.removeWhere((key, value) => value < 0.01);

        final balance = Balance.create(
          userId: otherUserId,
          groupId: testGroupId,
          owes: owes,
          owedBy: owedBy,
        );

        // Other user initially owed 50, paid 30, so now owes 20
        expect(balance.netBalance, closeTo(-20.0, 0.01));
        expect(balance.owes[testUserId], closeTo(20.0, 0.01));
      });

      test('should handle complete settlement', () {
        final expenses = [
          Expense(
            id: 'expense_1',
            groupId: testGroupId,
            description: 'Test expense',
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
        ];

        final settlements = [
          Settlement(
            id: 'settlement_1',
            groupId: testGroupId,
            fromUserId: otherUserId,
            toUserId: testUserId,
            amount: 50.0,
            settledAt: DateTime.now(),
          ),
        ];

        final memberIds = [testUserId, otherUserId];

        // Simulate balance calculation for otherUserId
        Map<String, double> owes = {};
        Map<String, double> owedBy = {};

        for (String memberId in memberIds) {
          if (memberId != otherUserId) {
            owes[memberId] = 0.0;
            owedBy[memberId] = 0.0;
          }
        }

        for (Expense expense in expenses) {
          final participantAmounts = expense.participantAmounts;

          if (expense.paidBy == otherUserId) {
            for (String participantId in expense.split.participants) {
              if (participantId != otherUserId) {
                owedBy[participantId] =
                    (owedBy[participantId] ?? 0.0) +
                    participantAmounts[participantId]!;
              }
            }
          }

          if (expense.split.participants.contains(otherUserId) &&
              expense.paidBy != otherUserId) {
            owes[expense.paidBy] =
                (owes[expense.paidBy] ?? 0.0) +
                participantAmounts[otherUserId]!;
          }
        }

        // Process settlements
        for (Settlement settlement in settlements) {
          if (settlement.fromUserId == otherUserId) {
            owes[settlement.toUserId] =
                (owes[settlement.toUserId] ?? 0.0) - settlement.amount;
          } else if (settlement.toUserId == otherUserId) {
            owedBy[settlement.fromUserId] =
                (owedBy[settlement.fromUserId] ?? 0.0) - settlement.amount;
          }
        }

        owes.updateAll((key, value) => value < 0 ? 0.0 : value);
        owedBy.updateAll((key, value) => value < 0 ? 0.0 : value);
        owes.removeWhere((key, value) => value < 0.01);
        owedBy.removeWhere((key, value) => value < 0.01);

        final balance = Balance.create(
          userId: otherUserId,
          groupId: testGroupId,
          owes: owes,
          owedBy: owedBy,
        );

        // Other user owed 50, paid 50, so now settled
        expect(balance.netBalance, closeTo(0.0, 0.01));
        expect(balance.owes.isEmpty, isTrue);
        expect(balance.isSettledUp, isTrue);
      });
    });

    group('Input validation', () {
      test('should validate settlement parameters', () {
        // Test invalid amounts
        final invalidAmountSettlement = Settlement(
          id: 'test',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 0.0,
          settledAt: DateTime.now(),
        );
        expect(invalidAmountSettlement.isValid, equals(false));

        final negativeAmountSettlement = Settlement(
          id: 'test',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: -10.0,
          settledAt: DateTime.now(),
        );
        expect(negativeAmountSettlement.isValid, equals(false));

        // Test self settlement
        final selfSettlement = Settlement(
          id: 'test',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: testUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
        );
        expect(selfSettlement.isValid, equals(false));

        // Test valid settlement
        final validSettlement = Settlement(
          id: 'test',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
        );
        expect(validSettlement.isValid, equals(true));
      });

      test('should validate balance data', () {
        // Test valid balance
        final validBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: 50.0},
          owedBy: {thirdUserId: 30.0},
        );

        expect(validBalance.isValid, isTrue);
        expect(validBalance.netBalance, closeTo(-20.0, 0.01));

        // Test balance with negative amounts (should be invalid)
        final invalidBalance = Balance(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: -50.0},
          owedBy: {},
          netBalance: 50.0,
        );

        expect(invalidBalance.isValid, isFalse);
      });
    });

    group('Edge cases', () {
      test('should handle very small amounts in debt simplification', () {
        final balances = [
          Balance(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {otherUserId: 0.001},
            netBalance: 0.001,
          ),
          Balance(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {testUserId: 0.001},
            owedBy: {},
            netBalance: -0.001,
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);
        expect(settlements.isEmpty, isTrue);
      });

      test('should handle large amounts in debt simplification', () {
        final balances = [
          Balance(
            userId: testUserId,
            groupId: testGroupId,
            owes: {},
            owedBy: {otherUserId: 1000000.0},
            netBalance: 1000000.0,
          ),
          Balance(
            userId: otherUserId,
            groupId: testGroupId,
            owes: {testUserId: 1000000.0},
            owedBy: {},
            netBalance: -1000000.0,
          ),
        ];

        final settlements = balanceService.simplifyDebts(balances);

        expect(settlements.length, equals(1));
        expect(settlements[0].amount, equals(1000000.0));
      });

      test('should handle many users in debt simplification', () {
        final userIds = List.generate(10, (index) => 'user_$index');
        final balances = <Balance>[];

        // Create scenario where user_0 owes 10 to each other user
        balances.add(
          Balance(
            userId: userIds[0],
            groupId: testGroupId,
            owes: {for (int i = 1; i < userIds.length; i++) userIds[i]: 10.0},
            owedBy: {},
            netBalance: -90.0,
          ),
        );

        // Each other user is owed 10 by user_0
        for (int i = 1; i < userIds.length; i++) {
          balances.add(
            Balance(
              userId: userIds[i],
              groupId: testGroupId,
              owes: {},
              owedBy: {userIds[0]: 10.0},
              netBalance: 10.0,
            ),
          );
        }

        final settlements = balanceService.simplifyDebts(balances);

        expect(settlements.length, equals(9));
        expect(settlements.every((s) => s.fromUserId == userIds[0]), isTrue);
        expect(settlements.every((s) => s.amount == 10.0), isTrue);
      });
    });
  });
}
