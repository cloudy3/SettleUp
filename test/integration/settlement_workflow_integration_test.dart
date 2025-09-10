import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('Settlement Workflow Integration Tests', () {
    const String testUserId = 'test_user_123';
    const String otherUserId = 'other_user_456';
    const String thirdUserId = 'third_user_789';
    const String testGroupId = 'test_group_123';

    group('Settlement Recording and Balance Updates', () {
      testWidgets('should record settlement and update balances correctly', (
        tester,
      ) async {
        // Initial state: testUser owes otherUser 100
        final initialBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: 100.0},
          owedBy: {},
        );

        expect(initialBalance.netBalance, -100.0);
        expect(initialBalance.owes[otherUserId], 100.0);

        // Record settlement
        final settlement = Settlement(
          id: 'settlement_1',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 60.0,
          settledAt: DateTime.now(),
        );

        expect(settlement.isValid, isTrue);

        // Calculate updated balance after settlement
        final updatedOwes = Map<String, double>.from(initialBalance.owes);
        updatedOwes[otherUserId] =
            updatedOwes[otherUserId]! - settlement.amount;

        // Remove zero amounts
        updatedOwes.removeWhere((key, value) => value < 0.01);

        final updatedBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: updatedOwes,
          owedBy: initialBalance.owedBy,
        );

        expect(updatedBalance.netBalance, -40.0);
        expect(updatedBalance.owes[otherUserId], 40.0);
      });

      testWidgets('should handle complete settlement', (tester) async {
        // Initial state: testUser owes otherUser 100
        final initialBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: 100.0},
          owedBy: {},
        );

        // Record complete settlement
        final settlement = Settlement(
          id: 'settlement_1',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 100.0,
          settledAt: DateTime.now(),
        );

        // Calculate updated balance after complete settlement
        final updatedOwes = Map<String, double>.from(initialBalance.owes);
        updatedOwes[otherUserId] =
            updatedOwes[otherUserId]! - settlement.amount;
        updatedOwes.removeWhere((key, value) => value < 0.01);

        final updatedBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: updatedOwes,
          owedBy: initialBalance.owedBy,
        );

        expect(updatedBalance.netBalance, 0.0);
        expect(updatedBalance.owes.isEmpty, isTrue);
        expect(updatedBalance.isSettledUp, isTrue);
      });

      testWidgets('should handle multiple settlements', (tester) async {
        // Initial state: complex balances
        final initialBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: {otherUserId: 150.0, thirdUserId: 50.0},
          owedBy: {},
        );

        expect(initialBalance.netBalance, -200.0);

        // Record multiple settlements
        final settlements = [
          Settlement(
            id: 'settlement_1',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: otherUserId,
            amount: 100.0,
            settledAt: DateTime.now(),
          ),
          Settlement(
            id: 'settlement_2',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: thirdUserId,
            amount: 50.0,
            settledAt: DateTime.now(),
          ),
        ];

        // Apply settlements
        final updatedOwes = Map<String, double>.from(initialBalance.owes);
        for (final settlement in settlements) {
          updatedOwes[settlement.toUserId] =
              updatedOwes[settlement.toUserId]! - settlement.amount;
        }
        updatedOwes.removeWhere((key, value) => value < 0.01);

        final updatedBalance = Balance.create(
          userId: testUserId,
          groupId: testGroupId,
          owes: updatedOwes,
          owedBy: initialBalance.owedBy,
        );

        expect(updatedBalance.netBalance, -50.0);
        expect(updatedBalance.owes[otherUserId], 50.0);
        expect(updatedBalance.owes.containsKey(thirdUserId), isFalse);
      });

      testWidgets('should validate settlement data', (tester) async {
        // Test invalid settlements
        final invalidSettlements = [
          // Zero amount
          Settlement(
            id: 'invalid_1',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: otherUserId,
            amount: 0.0,
            settledAt: DateTime.now(),
          ),
          // Negative amount
          Settlement(
            id: 'invalid_2',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: otherUserId,
            amount: -50.0,
            settledAt: DateTime.now(),
          ),
          // Self settlement
          Settlement(
            id: 'invalid_3',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: testUserId,
            amount: 50.0,
            settledAt: DateTime.now(),
          ),
        ];

        for (final settlement in invalidSettlements) {
          expect(settlement.isValid, isFalse);
        }

        // Test valid settlement
        final validSettlement = Settlement(
          id: 'valid_1',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
        );

        expect(validSettlement.isValid, isTrue);
      });

      testWidgets('should track settlement history', (tester) async {
        // Create settlement history
        final settlements = [
          Settlement(
            id: 'settlement_1',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: otherUserId,
            amount: 50.0,
            settledAt: DateTime(2025, 1, 15, 10, 0),
            note: 'First payment',
          ),
          Settlement(
            id: 'settlement_2',
            groupId: testGroupId,
            fromUserId: testUserId,
            toUserId: otherUserId,
            amount: 30.0,
            settledAt: DateTime(2025, 1, 16, 15, 30),
            note: 'Second payment',
          ),
          Settlement(
            id: 'settlement_3',
            groupId: testGroupId,
            fromUserId: otherUserId,
            toUserId: testUserId,
            amount: 25.0,
            settledAt: DateTime(2025, 1, 17, 9, 15),
          ),
        ];

        // Verify settlement history properties
        expect(settlements.length, 3);
        expect(settlements[0].note, 'First payment');
        expect(settlements[1].note, 'Second payment');
        expect(settlements[2].note, isNull);

        // Verify chronological order
        expect(
          settlements[0].settledAt.isBefore(settlements[1].settledAt),
          isTrue,
        );
        expect(
          settlements[1].settledAt.isBefore(settlements[2].settledAt),
          isTrue,
        );

        // Verify settlement amounts
        final totalFromTestUser = settlements
            .where((s) => s.fromUserId == testUserId)
            .fold(0.0, (sum, s) => sum + s.amount);
        expect(totalFromTestUser, 80.0);

        final totalToTestUser = settlements
            .where((s) => s.toUserId == testUserId)
            .fold(0.0, (sum, s) => sum + s.amount);
        expect(totalToTestUser, 25.0);
      });
    });

    group('Settlement Data Integrity', () {
      testWidgets('should maintain data consistency during serialization', (
        tester,
      ) async {
        final settlement = Settlement(
          id: 'test_settlement',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 123.45,
          settledAt: DateTime(2025, 1, 15, 14, 30, 45),
          note: 'Test settlement note',
        );

        // Serialize to JSON
        final json = settlement.toJson();

        // Verify JSON structure
        expect(json['id'], 'test_settlement');
        expect(json['fromUserId'], testUserId);
        expect(json['toUserId'], otherUserId);
        expect(json['amount'], 123.45);
        expect(json['note'], 'Test settlement note');

        // Deserialize from JSON
        final deserializedSettlement = Settlement.fromJson(json);

        // Verify deserialized settlement matches original
        expect(deserializedSettlement.id, settlement.id);
        expect(deserializedSettlement.fromUserId, settlement.fromUserId);
        expect(deserializedSettlement.toUserId, settlement.toUserId);
        expect(deserializedSettlement.amount, settlement.amount);
        expect(deserializedSettlement.note, settlement.note);
      });

      testWidgets('should handle edge cases in settlement data', (
        tester,
      ) async {
        // Test with very small amounts
        final smallAmountSettlement = Settlement(
          id: 'small_settlement',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 0.01,
          settledAt: DateTime.now(),
        );

        expect(smallAmountSettlement.isValid, isTrue);

        // Test with large amounts
        final largeAmountSettlement = Settlement(
          id: 'large_settlement',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 999999.99,
          settledAt: DateTime.now(),
        );

        expect(largeAmountSettlement.isValid, isTrue);

        // Test without note
        final settlementWithoutNote = Settlement(
          id: 'no_note_settlement',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
        );

        expect(settlementWithoutNote.isValid, isTrue);
        expect(settlementWithoutNote.note, isNull);
      });
    });
  });
}
