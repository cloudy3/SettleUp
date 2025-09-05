import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('NotificationService Tests', () {
    const String testUserId = 'test_user_123';
    const String otherUserId = 'other_user_456';
    const String testGroupId = 'test_group_123';
    const String notificationId = 'notification_123';

    group('Notification Model Tests', () {
      test('should create valid settlement notification', () {
        final notification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        expect(notification.isValid, isTrue);
        expect(notification.id, equals(notificationId));
        expect(notification.type, equals(NotificationType.settlementReceived));
        expect(notification.amount, equals(50.0));
      });

      test('should validate notification types correctly', () {
        // Test all notification types
        final receivedNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'You received a payment',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(
          receivedNotification.type,
          equals(NotificationType.settlementReceived),
        );

        final sentNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementSent,
          title: 'Payment Sent',
          message: 'Your payment was recorded',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: testUserId,
          amount: 50.0,
        );
        expect(sentNotification.type, equals(NotificationType.settlementSent));
      });

      test('should validate notification data correctly', () {
        // Valid notification
        final validNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(validNotification.isValid, isTrue);

        // Invalid - empty ID
        final invalidIdNotification = SettlementNotification(
          id: '',
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(invalidIdNotification.isValid, isFalse);

        // Invalid - empty title
        final invalidTitleNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: '',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(invalidTitleNotification.isValid, isFalse);

        // Invalid - zero amount
        final zeroAmountNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 0.0,
        );
        expect(zeroAmountNotification.isValid, isFalse);

        // Invalid - empty settlement ID
        final invalidSettlementIdNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: '',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );
        expect(invalidSettlementIdNotification.isValid, isFalse);
      });

      test('should serialize and deserialize notification correctly', () {
        final originalNotification = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
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
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        final readAt = DateTime.now();
        final copiedNotification = originalNotification.copyWith(
          isRead: true,
          readAt: readAt,
        );

        expect(copiedNotification.id, equals(originalNotification.id));
        expect(copiedNotification.userId, equals(originalNotification.userId));
        expect(copiedNotification.type, equals(originalNotification.type));
        expect(copiedNotification.title, equals(originalNotification.title));
        expect(
          copiedNotification.message,
          equals(originalNotification.message),
        );
        expect(copiedNotification.isRead, isTrue);
        expect(copiedNotification.readAt, equals(readAt));
        expect(
          copiedNotification.settlementId,
          equals(originalNotification.settlementId),
        );
        expect(
          copiedNotification.groupId,
          equals(originalNotification.groupId),
        );
        expect(
          copiedNotification.fromUserId,
          equals(originalNotification.fromUserId),
        );
        expect(copiedNotification.amount, equals(originalNotification.amount));
      });

      test('should handle equality correctly', () {
        final notification1 = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        final notification2 = SettlementNotification(
          id: notificationId,
          userId: testUserId,
          type: NotificationType.settlementReceived,
          title: 'Payment Received',
          message: 'Test message',
          createdAt: notification1.createdAt,
          isRead: false,
          settlementId: 'settlement_123',
          groupId: testGroupId,
          fromUserId: otherUserId,
          amount: 50.0,
        );

        final notification3 = notification1.copyWith(amount: 75.0);

        expect(notification1, equals(notification2));
        expect(notification1, isNot(equals(notification3)));
        expect(notification1.hashCode, equals(notification2.hashCode));
        expect(notification1.hashCode, isNot(equals(notification3.hashCode)));
      });
    });

    group('Notification Business Logic Tests', () {
      test('should generate correct notification messages', () {
        final settlement = Settlement(
          id: 'settlement_123',
          groupId: testGroupId,
          fromUserId: 'user1',
          toUserId: 'user2',
          amount: 50.0,
          settledAt: DateTime.now(),
          note: 'Test settlement',
        );

        // Test received notification message
        final receivedMessage = _generateReceivedNotificationMessage(
          fromUserName: 'John Doe',
          amount: settlement.amount,
          groupName: 'Test Group',
        );
        expect(receivedMessage, contains('John Doe'));
        expect(receivedMessage, contains('\$50.00'));
        expect(receivedMessage, contains('Test Group'));

        // Test sent notification message
        final sentMessage = _generateSentNotificationMessage(
          toUserName: 'Jane Smith',
          amount: settlement.amount,
          groupName: 'Test Group',
        );
        expect(sentMessage, contains('Jane Smith'));
        expect(sentMessage, contains('\$50.00'));
        expect(sentMessage, contains('Test Group'));
      });

      test('should handle notification filtering', () {
        final notifications = <SettlementNotification>[
          SettlementNotification(
            id: 'notification_1',
            userId: testUserId,
            type: NotificationType.settlementReceived,
            title: 'Payment Received',
            message: 'Test message 1',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: false,
            settlementId: 'settlement_1',
            groupId: testGroupId,
            fromUserId: otherUserId,
            amount: 50.0,
          ),
          SettlementNotification(
            id: 'notification_2',
            userId: testUserId,
            type: NotificationType.settlementSent,
            title: 'Payment Sent',
            message: 'Test message 2',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: true,
            settlementId: 'settlement_2',
            groupId: testGroupId,
            fromUserId: testUserId,
            amount: 30.0,
          ),
          SettlementNotification(
            id: 'notification_3',
            userId: testUserId,
            type: NotificationType.settlementReceived,
            title: 'Payment Received',
            message: 'Test message 3',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            isRead: false,
            settlementId: 'settlement_3',
            groupId: testGroupId,
            fromUserId: otherUserId,
            amount: 25.0,
          ),
        ];

        // Filter unread notifications
        final unreadNotifications = notifications
            .where((n) => !n.isRead)
            .toList();
        expect(unreadNotifications.length, equals(2));

        // Filter by type
        final receivedNotifications = notifications
            .where((n) => n.type == NotificationType.settlementReceived)
            .toList();
        expect(receivedNotifications.length, equals(2));

        // Sort by date (most recent first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        expect(notifications[0].id, equals('notification_1')); // Most recent
        expect(notifications[2].id, equals('notification_3')); // Oldest
      });

      test('should calculate notification statistics', () {
        final notifications = <SettlementNotification>[
          SettlementNotification(
            id: 'notification_1',
            userId: testUserId,
            type: NotificationType.settlementReceived,
            title: 'Payment Received',
            message: 'Test message 1',
            createdAt: DateTime.now(),
            isRead: false,
            settlementId: 'settlement_1',
            groupId: testGroupId,
            fromUserId: otherUserId,
            amount: 50.0,
          ),
          SettlementNotification(
            id: 'notification_2',
            userId: testUserId,
            type: NotificationType.settlementReceived,
            title: 'Payment Received',
            message: 'Test message 2',
            createdAt: DateTime.now(),
            isRead: true,
            settlementId: 'settlement_2',
            groupId: testGroupId,
            fromUserId: otherUserId,
            amount: 30.0,
          ),
          SettlementNotification(
            id: 'notification_3',
            userId: testUserId,
            type: NotificationType.settlementSent,
            title: 'Payment Sent',
            message: 'Test message 3',
            createdAt: DateTime.now(),
            isRead: false,
            settlementId: 'settlement_3',
            groupId: testGroupId,
            fromUserId: testUserId,
            amount: 25.0,
          ),
        ];

        // Count unread notifications
        final unreadCount = notifications.where((n) => !n.isRead).length;
        expect(unreadCount, equals(2));

        // Calculate total amount from received notifications
        final totalReceived = notifications
            .where((n) => n.type == NotificationType.settlementReceived)
            .fold<double>(0.0, (sum, n) => sum + n.amount);
        expect(totalReceived, equals(80.0));

        // Calculate total amount from sent notifications
        final totalSent = notifications
            .where((n) => n.type == NotificationType.settlementSent)
            .fold<double>(0.0, (sum, n) => sum + n.amount);
        expect(totalSent, equals(25.0));
      });
    });
  });
}

// Helper functions for testing notification business logic
String _generateReceivedNotificationMessage({
  required String fromUserName,
  required double amount,
  required String groupName,
}) {
  return '$fromUserName paid you \$${amount.toStringAsFixed(2)} in $groupName';
}

String _generateSentNotificationMessage({
  required String toUserName,
  required double amount,
  required String groupName,
}) {
  return 'Your payment of \$${amount.toStringAsFixed(2)} to $toUserName in $groupName has been recorded';
}
