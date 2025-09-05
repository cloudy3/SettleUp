import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('Settlement Functionality Tests', () {
    const String testUserId = 'test_user_123';
    const String testGroupId = 'test_group_123';
    const String otherUserId = 'other_user_456';
    const String settlementId = 'settlement_123';

    group('Settlement Model Tests', () {
      test('should create valid settlement', () {
        final settlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
          note: 'Test settlement',
        );

        expect(settlement.isValid, isTrue);
        expect(settlement.id, equals(settlementId));
        expect(settlement.groupId, equals(testGroupId));
        expect(settlement.fromUserId, equals(testUserId));
        expect(settlement.toUserId, equals(otherUserId));
        expect(settlement.amount, equals(50.0));
        expect(settlement.note, equals('Test settlement'));
      });

      test('should validate settlement correctly', () {
        // Valid settlement
        final validSettlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
          note: 'Valid settlement',
        );
        expect(validSettlement.isValid, isTrue);

        // Invalid settlement - empty id
        final invalidIdSettlement = Settlement(
          id: '',
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
        );
        expect(invalidIdSettlement.isValid, isFalse);

        // Invalid settlement - self settlement
        final selfSettlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: testUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
        );
        expect(selfSettlement.isValid, isFalse);

        // Invalid settlement - zero amount
        final zeroAmountSettlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 0.0,
          settledAt: DateTime.now(),
        );
        expect(zeroAmountSettlement.isValid, isFalse);

        // Invalid settlement - negative amount
        final negativeAmountSettlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: -10.0,
          settledAt: DateTime.now(),
        );
        expect(negativeAmountSettlement.isValid, isFalse);
      });

      test('should serialize and deserialize settlement correctly', () {
        final originalSettlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
          note: 'Test settlement',
        );

        final json = originalSettlement.toJson();
        final deserializedSettlement = Settlement.fromJson(json);

        expect(deserializedSettlement.id, equals(originalSettlement.id));
        expect(
          deserializedSettlement.groupId,
          equals(originalSettlement.groupId),
        );
        expect(
          deserializedSettlement.fromUserId,
          equals(originalSettlement.fromUserId),
        );
        expect(
          deserializedSettlement.toUserId,
          equals(originalSettlement.toUserId),
        );
        expect(
          deserializedSettlement.amount,
          equals(originalSettlement.amount),
        );
        expect(deserializedSettlement.note, equals(originalSettlement.note));
        expect(
          deserializedSettlement.settledAt.millisecondsSinceEpoch,
          closeTo(originalSettlement.settledAt.millisecondsSinceEpoch, 1000),
        );
      });

      test('should handle copyWith correctly', () {
        final originalSettlement = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
          note: 'Original note',
        );

        final copiedSettlement = originalSettlement.copyWith(
          amount: 75.0,
          note: 'Updated note',
        );

        expect(copiedSettlement.id, equals(originalSettlement.id));
        expect(copiedSettlement.groupId, equals(originalSettlement.groupId));
        expect(
          copiedSettlement.fromUserId,
          equals(originalSettlement.fromUserId),
        );
        expect(copiedSettlement.toUserId, equals(originalSettlement.toUserId));
        expect(copiedSettlement.amount, equals(75.0));
        expect(copiedSettlement.note, equals('Updated note'));
        expect(
          copiedSettlement.settledAt,
          equals(originalSettlement.settledAt),
        );
      });

      test('should handle equality correctly', () {
        final settlement1 = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: DateTime.now(),
          note: 'Test settlement',
        );

        final settlement2 = Settlement(
          id: settlementId,
          groupId: testGroupId,
          fromUserId: testUserId,
          toUserId: otherUserId,
          amount: 50.0,
          settledAt: settlement1.settledAt,
          note: 'Test settlement',
        );

        final settlement3 = settlement1.copyWith(amount: 75.0);

        expect(settlement1, equals(settlement2));
        expect(settlement1, isNot(equals(settlement3)));
        expect(settlement1.hashCode, equals(settlement2.hashCode));
        expect(settlement1.hashCode, isNot(equals(settlement3.hashCode)));
      });
    });

    group('Notification Model Tests', () {
      test('should create valid settlement notification', () {
        final notification = SettlementNotification(
          id: 'notification_123',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: settlementId,
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        expect(notification.isValid, isTrue);
        expect(notification.type, equals(NotificationType.settlementReceived));
        expect(notification.amount, equals(50.0));
        expect(notification.settlementId, equals(settlementId));
      });

      test('should validate notification correctly', () {
        // Valid notification
        final validNotification = SettlementNotification(
          id: 'notification_123',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: settlementId,
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(validNotification.isValid, isTrue);

        // Invalid notification - empty id
        final invalidNotification = SettlementNotification(
          id: '',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: settlementId,
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(invalidNotification.isValid, isFalse);

        // Invalid notification - zero amount
        final zeroAmountNotification = SettlementNotification(
          id: 'notification_123',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: settlementId,
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 0.0,
        );
        expect(zeroAmountNotification.isValid, isFalse);
      });

      test('should serialize and deserialize notification correctly', () {
        final originalNotification = SettlementNotification(
          id: 'notification_123',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: settlementId,
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        final json = originalNotification.toJson();
        final deserializedNotification = SettlementNotification.fromJson(json);

        expect(deserializedNotification.id, equals(originalNotification.id));
        expect(
          deserializedNotification.userId,
          equals(originalNotification.userId),
        );
        expect(
          deserializedNotification.type,
          equals(originalNotification.type),
        );
        expect(
          deserializedNotification.title,
          equals(originalNotification.title),
        );
        expect(
          deserializedNotification.message,
          equals(originalNotification.message),
        );
        expect(
          deserializedNotification.isRead,
          equals(originalNotification.isRead),
        );
        expect(
          deserializedNotification.settlementId,
          equals(originalNotification.settlementId),
        );
        expect(
          deserializedNotification.groupId,
          equals(originalNotification.groupId),
        );
        expect(
          deserializedNotification.fromUserId,
          equals(originalNotification.fromUserId),
        );
        expect(
          deserializedNotification.amount,
          equals(originalNotification.amount),
        );
      });

      test('should handle copyWith correctly', () {
        final originalNotification = SettlementNotification(
          id: 'notification_123',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: settlementId,
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        final copiedNotification = originalNotification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );

        expect(copiedNotification.id, equals(originalNotification.id));
        expect(copiedNotification.userId, equals(originalNotification.userId));
        expect(copiedNotification.isRead, isTrue);
        expect(copiedNotification.readAt, isNotNull);
        expect(copiedNotification.amount, equals(originalNotification.amount));
      });
    });

    group('Settlement Business Logic Tests', () {
      test('should handle settlement amount validation', () {
        // Test valid amounts
        expect(() => _validateSettlementAmount(50.0), returnsNormally);
        expect(() => _validateSettlementAmount(0.01), returnsNormally);
        expect(() => _validateSettlementAmount(1000.0), returnsNormally);

        // Test invalid amounts
        expect(() => _validateSettlementAmount(0.0), throwsArgumentError);
        expect(() => _validateSettlementAmount(-10.0), throwsArgumentError);
        expect(() => _validateSettlementAmount(-0.01), throwsArgumentError);
      });

      test('should handle settlement user validation', () {
        // Test valid users
        expect(
          () => _validateSettlementUsers('user1', 'user2'),
          returnsNormally,
        );

        // Test invalid users (same user)
        expect(
          () => _validateSettlementUsers('user1', 'user1'),
          throwsArgumentError,
        );
        expect(
          () => _validateSettlementUsers('', 'user2'),
          throwsArgumentError,
        );
        expect(
          () => _validateSettlementUsers('user1', ''),
          throwsArgumentError,
        );
      });

      test('should calculate settlement impact on balances', () {
        // Create initial balance where user1 owes user2 $100
        final initialBalance = Balance.create(
          userId: 'user1',
          groupId: testGroupId,
          owes: {'user2': 100.0},
          owedBy: {},
        );

        expect(initialBalance.netBalance, equals(-100.0));

        // Simulate settlement of $30
        final settlementAmount = 30.0;
        final newOwedAmount = initialBalance.owes['user2']! - settlementAmount;

        expect(newOwedAmount, equals(70.0));
        expect(newOwedAmount > 0, isTrue); // Still owes money

        // Simulate full settlement
        final fullSettlementAmount = 100.0;
        final finalOwedAmount =
            initialBalance.owes['user2']! - fullSettlementAmount;

        expect(finalOwedAmount, equals(0.0));
      });

      test('should handle settlement history tracking', () {
        final settlements = <Settlement>[];

        // Add settlements
        settlements.add(
          Settlement(
            id: 'settlement_1',
            groupId: testGroupId,
            fromUserId: 'user1',
            toUserId: 'user2',
            amount: 30.0,
            settledAt: DateTime.now().subtract(const Duration(days: 2)),
            note: 'First payment',
          ),
        );

        settlements.add(
          Settlement(
            id: 'settlement_2',
            groupId: testGroupId,
            fromUserId: 'user1',
            toUserId: 'user2',
            amount: 20.0,
            settledAt: DateTime.now().subtract(const Duration(days: 1)),
            note: 'Second payment',
          ),
        );

        // Sort by date (most recent first)
        settlements.sort((a, b) => b.settledAt.compareTo(a.settledAt));

        expect(settlements.length, equals(2));
        expect(settlements[0].amount, equals(20.0)); // Most recent
        expect(settlements[1].amount, equals(30.0)); // Older

        // Calculate total settled amount
        final totalSettled = settlements.fold<double>(
          0.0,
          (sum, settlement) => sum + settlement.amount,
        );
        expect(totalSettled, equals(50.0));
      });
    });
  });
}

// Helper functions for testing business logic
void _validateSettlementAmount(double amount) {
  if (amount <= 0) {
    throw ArgumentError('Settlement amount must be positive');
  }
}

void _validateSettlementUsers(String fromUserId, String toUserId) {
  if (fromUserId.isEmpty || toUserId.isEmpty) {
    throw ArgumentError('User IDs cannot be empty');
  }
  if (fromUserId == toUserId) {
    throw ArgumentError('Cannot settle with yourself');
  }
}
