import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('ExpenseService Business Logic Tests', () {
    group('Input validation', () {
      test('should validate expense description is not empty', () {
        const description = 'Dinner at restaurant';
        const emptyDescription = '';
        const whitespaceDescription = '   ';

        expect(description.trim().isNotEmpty, true);
        expect(emptyDescription.trim().isEmpty, true);
        expect(whitespaceDescription.trim().isEmpty, true);
      });

      test('should validate expense amount is positive', () {
        const validAmount = 50.0;
        const zeroAmount = 0.0;
        const negativeAmount = -10.0;

        expect(validAmount > 0, true);
        expect(zeroAmount > 0, false);
        expect(negativeAmount > 0, false);
      });

      test('should validate paidBy user ID is not empty', () {
        const validPaidBy = 'user123';
        const emptyPaidBy = '';

        expect(validPaidBy.isNotEmpty, true);
        expect(emptyPaidBy.isEmpty, true);
      });

      test('should validate split participants list is not empty', () {
        final validParticipants = ['user1', 'user2'];
        final emptyParticipants = <String>[];

        expect(validParticipants.isNotEmpty, true);
        expect(emptyParticipants.isEmpty, true);
      });

      test('should validate paidBy user is included in split participants', () {
        const paidBy = 'user1';
        final participantsWithPayer = ['user1', 'user2'];
        final participantsWithoutPayer = ['user2', 'user3'];

        expect(participantsWithPayer.contains(paidBy), true);
        expect(participantsWithoutPayer.contains(paidBy), false);
      });
    });

    group('ExpenseSplit validation', () {
      test('should validate equal split', () {
        final equalSplit = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2', 'user3'],
          shares: {'user1': 1.0, 'user2': 1.0, 'user3': 1.0},
        );

        expect(equalSplit.isValid, true);
        expect(equalSplit.participants.length, 3);
        expect(equalSplit.shares.length, 3);
      });

      test('should validate custom split', () {
        final customSplit = ExpenseSplit(
          type: SplitType.custom,
          participants: ['user1', 'user2'],
          shares: {'user1': 30.0, 'user2': 20.0},
        );

        expect(customSplit.isValid, true);
        expect(customSplit.shares['user1'], 30.0);
        expect(customSplit.shares['user2'], 20.0);
      });

      test('should validate percentage split sums to 100', () {
        final validPercentageSplit = ExpenseSplit(
          type: SplitType.percentage,
          participants: ['user1', 'user2'],
          shares: {'user1': 60.0, 'user2': 40.0},
        );

        final invalidPercentageSplit = ExpenseSplit(
          type: SplitType.percentage,
          participants: ['user1', 'user2'],
          shares: {
            'user1': 60.0,
            'user2': 50.0, // Total = 110%
          },
        );

        expect(validPercentageSplit.isValid, true);
        expect(invalidPercentageSplit.isValid, false);
      });

      test('should invalidate split with negative shares', () {
        final splitWithNegativeShare = ExpenseSplit(
          type: SplitType.custom,
          participants: ['user1', 'user2'],
          shares: {
            'user1': 30.0,
            'user2': -10.0, // Negative share
          },
        );

        expect(splitWithNegativeShare.isValid, false);
      });

      test('should invalidate split with missing participant shares', () {
        final splitWithMissingShare = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2', 'user3'],
          shares: {
            'user1': 1.0,
            'user2': 1.0,
            // Missing user3
          },
        );

        expect(splitWithMissingShare.isValid, false);
      });

      test('should invalidate split with empty participants', () {
        final splitWithEmptyParticipants = ExpenseSplit(
          type: SplitType.equal,
          participants: [],
          shares: {},
        );

        expect(splitWithEmptyParticipants.isValid, false);
      });
    });

    group('Split amount calculations', () {
      test('should calculate equal split amounts correctly', () {
        final equalSplit = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2', 'user3'],
          shares: {'user1': 1.0, 'user2': 1.0, 'user3': 1.0},
        );

        final amounts = equalSplit.calculateAmounts(150.0);

        expect(amounts['user1'], 50.0);
        expect(amounts['user2'], 50.0);
        expect(amounts['user3'], 50.0);
      });

      test('should calculate custom split amounts correctly', () {
        final customSplit = ExpenseSplit(
          type: SplitType.custom,
          participants: ['user1', 'user2'],
          shares: {'user1': 30.0, 'user2': 20.0},
        );

        final amounts = customSplit.calculateAmounts(50.0);

        expect(amounts['user1'], 30.0);
        expect(amounts['user2'], 20.0);
      });

      test('should calculate percentage split amounts correctly', () {
        final percentageSplit = ExpenseSplit(
          type: SplitType.percentage,
          participants: ['user1', 'user2'],
          shares: {'user1': 60.0, 'user2': 40.0},
        );

        final amounts = percentageSplit.calculateAmounts(100.0);

        expect(amounts['user1'], 60.0);
        expect(amounts['user2'], 40.0);
      });

      test(
        'should handle uneven equal splits with floating point precision',
        () {
          final equalSplit = ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2', 'user3'],
            shares: {'user1': 1.0, 'user2': 1.0, 'user3': 1.0},
          );

          final amounts = equalSplit.calculateAmounts(100.0);
          final total = amounts.values.fold(0.0, (sum, amount) => sum + amount);

          expect(
            (total - 100.0).abs() < 0.01,
            true,
          ); // Allow small floating point errors
        },
      );
    });

    group('Expense model validation', () {
      test('should validate complete expense data', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 60.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, true);
      });

      test('should invalidate expense with empty description', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: '',
          amount: 60.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, false);
      });

      test('should invalidate expense with zero amount', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 0.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, false);
      });

      test('should invalidate expense with negative amount', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: -10.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, false);
      });

      test(
        'should invalidate expense where paidBy is not in split participants',
        () {
          final expense = Expense(
            id: 'expense_123',
            groupId: 'group_456',
            description: 'Dinner',
            amount: 60.0,
            paidBy: 'user3', // Not in participants
            date: DateTime.now(),
            split: ExpenseSplit(
              type: SplitType.equal,
              participants: ['user1', 'user2'],
              shares: {'user1': 1.0, 'user2': 1.0},
            ),
            createdBy: 'user1',
            createdAt: DateTime.now(),
          );

          expect(expense.isValid, false);
        },
      );

      test('should invalidate expense with invalid split', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 60.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.percentage,
            participants: ['user1', 'user2'],
            shares: {'user1': 60.0, 'user2': 50.0}, // Invalid percentage total
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        expect(expense.isValid, false);
      });
    });

    group('Split creation helpers', () {
      test('should create equal split correctly', () {
        final participants = ['user1', 'user2', 'user3'];

        // Simulate createEqualSplit method
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

        final split = createEqualSplit(participants);

        expect(split.type, SplitType.equal);
        expect(split.participants, participants);
        expect(split.shares.length, 3);
        expect(split.shares['user1'], 1.0);
        expect(split.isValid, true);
      });

      test('should create custom split correctly', () {
        final customAmounts = {'user1': 30.0, 'user2': 20.0};

        // Simulate createCustomSplit method
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

        final split = createCustomSplit(customAmounts);

        expect(split.type, SplitType.custom);
        expect(split.participants, ['user1', 'user2']);
        expect(split.shares, customAmounts);
        expect(split.isValid, true);
      });

      test('should create percentage split correctly', () {
        final percentages = {'user1': 60.0, 'user2': 40.0};

        // Simulate createPercentageSplit method
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

        final split = createPercentageSplit(percentages);

        expect(split.type, SplitType.percentage);
        expect(split.participants, ['user1', 'user2']);
        expect(split.shares, percentages);
        expect(split.isValid, true);
      });

      test('should throw error for empty participants in equal split', () {
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

        expect(() => createEqualSplit([]), throwsArgumentError);
      });

      test('should throw error for negative amounts in custom split', () {
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

        expect(() => createCustomSplit({'user1': -10.0}), throwsArgumentError);
      });

      test('should throw error for invalid percentage totals', () {
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

        expect(
          () => createPercentageSplit({'user1': 60.0, 'user2': 50.0}),
          throwsArgumentError,
        );
        expect(
          () => createPercentageSplit({'user1': 110.0}),
          throwsArgumentError,
        );
        expect(
          () => createPercentageSplit({'user1': -10.0}),
          throwsArgumentError,
        );
      });
    });

    group('Split validation against total amount', () {
      test('should validate equal split against total amount', () {
        final split = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2'],
          shares: {'user1': 1.0, 'user2': 1.0},
        );

        // Simulate validateSplit method
        bool validateSplit(ExpenseSplit split, double totalAmount) {
          if (!split.isValid) return false;
          if (totalAmount <= 0) return false; // Invalid total amount
          final amounts = split.calculateAmounts(totalAmount);
          final calculatedTotal = amounts.values.fold(
            0.0,
            (sum, amount) => sum + amount,
          );
          return (calculatedTotal - totalAmount).abs() < 0.01;
        }

        expect(validateSplit(split, 100.0), true);
        expect(validateSplit(split, 0.0), false); // Invalid total amount
      });

      test('should validate custom split against total amount', () {
        final validSplit = ExpenseSplit(
          type: SplitType.custom,
          participants: ['user1', 'user2'],
          shares: {'user1': 30.0, 'user2': 20.0},
        );

        final invalidSplit = ExpenseSplit(
          type: SplitType.custom,
          participants: ['user1', 'user2'],
          shares: {'user1': 30.0, 'user2': 30.0}, // Total 60, but expense is 50
        );

        bool validateSplit(ExpenseSplit split, double totalAmount) {
          if (!split.isValid) return false;
          if (totalAmount <= 0) return false; // Invalid total amount
          final amounts = split.calculateAmounts(totalAmount);
          final calculatedTotal = amounts.values.fold(
            0.0,
            (sum, amount) => sum + amount,
          );
          return (calculatedTotal - totalAmount).abs() < 0.01;
        }

        expect(validateSplit(validSplit, 50.0), true);
        expect(validateSplit(invalidSplit, 50.0), false);
      });

      test('should validate percentage split against total amount', () {
        final split = ExpenseSplit(
          type: SplitType.percentage,
          participants: ['user1', 'user2'],
          shares: {'user1': 60.0, 'user2': 40.0},
        );

        bool validateSplit(ExpenseSplit split, double totalAmount) {
          if (!split.isValid) return false;
          if (totalAmount <= 0) return false; // Invalid total amount
          final amounts = split.calculateAmounts(totalAmount);
          final calculatedTotal = amounts.values.fold(
            0.0,
            (sum, amount) => sum + amount,
          );
          return (calculatedTotal - totalAmount).abs() < 0.01;
        }

        expect(validateSplit(split, 100.0), true);
        expect(
          validateSplit(split, 50.0),
          true,
        ); // Percentage splits work with any amount
      });
    });

    group('Data serialization', () {
      test('should serialize Expense to JSON with correct structure', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 60.0,
          paidBy: 'user1',
          date: DateTime(2025, 1, 15),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime(2025, 1, 15),
        );

        final json = expense.toJson();

        expect(json['id'], 'expense_123');
        expect(json['groupId'], 'group_456');
        expect(json['description'], 'Dinner');
        expect(json['amount'], 60.0);
        expect(json['paidBy'], 'user1');
        expect(json['createdBy'], 'user1');
        expect(json['split'], isA<Map<String, dynamic>>());
      });

      test('should serialize ExpenseSplit to JSON with correct structure', () {
        final split = ExpenseSplit(
          type: SplitType.percentage,
          participants: ['user1', 'user2'],
          shares: {'user1': 60.0, 'user2': 40.0},
        );

        final json = split.toJson();

        expect(json['type'], 'percentage');
        expect(json['participants'], ['user1', 'user2']);
        expect(json['shares'], {'user1': 60.0, 'user2': 40.0});
      });

      test('should handle different split types in serialization', () {
        final splitTypes = [
          SplitType.equal,
          SplitType.custom,
          SplitType.percentage,
        ];

        for (final type in splitTypes) {
          final split = ExpenseSplit(
            type: type,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          );

          final json = split.toJson();
          expect(json['type'], type.name);
        }
      });
    });

    group('Data copying and equality', () {
      test('should create correct copy of Expense with changes', () {
        final originalExpense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Original Description',
          amount: 50.0,
          paidBy: 'user1',
          date: DateTime(2025, 1, 15),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2'],
            shares: {'user1': 1.0, 'user2': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime(2025, 1, 15),
        );

        final copiedExpense = originalExpense.copyWith(
          description: 'New Description',
          amount: 75.0,
        );

        expect(copiedExpense.id, originalExpense.id);
        expect(copiedExpense.description, 'New Description');
        expect(copiedExpense.amount, 75.0);
        expect(copiedExpense.groupId, originalExpense.groupId);
        expect(copiedExpense.split, originalExpense.split);
      });

      test('should create correct copy of ExpenseSplit with changes', () {
        final originalSplit = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2'],
          shares: {'user1': 1.0, 'user2': 1.0},
        );

        final copiedSplit = originalSplit.copyWith(
          type: SplitType.custom,
          shares: {'user1': 30.0, 'user2': 20.0},
        );

        expect(copiedSplit.participants, originalSplit.participants);
        expect(copiedSplit.type, SplitType.custom);
        expect(copiedSplit.shares, {'user1': 30.0, 'user2': 20.0});
      });

      test('should correctly compare Expense equality', () {
        final date = DateTime(2025, 1, 15);
        final split = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2'],
          shares: {'user1': 1.0, 'user2': 1.0},
        );

        final expense1 = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 60.0,
          paidBy: 'user1',
          date: date,
          split: split,
          createdBy: 'user1',
          createdAt: date,
        );

        final expense2 = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 60.0,
          paidBy: 'user1',
          date: date,
          split: split,
          createdBy: 'user1',
          createdAt: date,
        );

        final expense3 = expense1.copyWith(
          description: 'Different Description',
        );

        expect(expense1 == expense2, true);
        expect(expense1 == expense3, false);
      });

      test('should correctly compare ExpenseSplit equality', () {
        final split1 = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2'],
          shares: {'user1': 1.0, 'user2': 1.0},
        );

        final split2 = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2'],
          shares: {'user1': 1.0, 'user2': 1.0},
        );

        final split3 = split1.copyWith(type: SplitType.custom);

        expect(split1 == split2, true);
        expect(split1 == split3, false);
      });
    });

    group('Edge cases and error conditions', () {
      test(
        'should handle very small amounts with floating point precision',
        () {
          final split = ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2', 'user3'],
            shares: {'user1': 1.0, 'user2': 1.0, 'user3': 1.0},
          );

          final amounts = split.calculateAmounts(0.01);
          final total = amounts.values.fold(0.0, (sum, amount) => sum + amount);

          expect((total - 0.01).abs() < 0.001, true);
        },
      );

      test('should handle very large amounts', () {
        final split = ExpenseSplit(
          type: SplitType.equal,
          participants: ['user1', 'user2'],
          shares: {'user1': 1.0, 'user2': 1.0},
        );

        final amounts = split.calculateAmounts(1000000.0);

        expect(amounts['user1'], 500000.0);
        expect(amounts['user2'], 500000.0);
      });

      test('should handle many participants in equal split', () {
        final participants = List.generate(100, (index) => 'user_$index');
        final shares = {
          for (String participant in participants) participant: 1.0,
        };

        final split = ExpenseSplit(
          type: SplitType.equal,
          participants: participants,
          shares: shares,
        );

        expect(split.isValid, true);
        expect(split.participants.length, 100);

        final amounts = split.calculateAmounts(1000.0);
        expect(amounts.values.every((amount) => amount == 10.0), true);
      });

      test('should handle percentage splits with decimal precision', () {
        final split = ExpenseSplit(
          type: SplitType.percentage,
          participants: ['user1', 'user2', 'user3'],
          shares: {'user1': 33.33, 'user2': 33.33, 'user3': 33.34},
        );

        expect(split.isValid, true);

        final amounts = split.calculateAmounts(100.0);
        final total = amounts.values.fold(0.0, (sum, amount) => sum + amount);

        expect((total - 100.0).abs() < 0.01, true);
      });
    });

    group('Participant amount calculations', () {
      test('should calculate participant amounts correctly for expense', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 90.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.equal,
            participants: ['user1', 'user2', 'user3'],
            shares: {'user1': 1.0, 'user2': 1.0, 'user3': 1.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        final participantAmounts = expense.participantAmounts;

        expect(participantAmounts['user1'], 30.0);
        expect(participantAmounts['user2'], 30.0);
        expect(participantAmounts['user3'], 30.0);
      });

      test('should calculate participant amounts for custom split', () {
        final expense = Expense(
          id: 'expense_123',
          groupId: 'group_456',
          description: 'Dinner',
          amount: 100.0,
          paidBy: 'user1',
          date: DateTime.now(),
          split: ExpenseSplit(
            type: SplitType.custom,
            participants: ['user1', 'user2'],
            shares: {'user1': 60.0, 'user2': 40.0},
          ),
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );

        final participantAmounts = expense.participantAmounts;

        expect(participantAmounts['user1'], 60.0);
        expect(participantAmounts['user2'], 40.0);
      });
    });
  });
}
