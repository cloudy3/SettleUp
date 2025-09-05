import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Service for handling notifications related to settlements and group activities
class NotificationService {
  // Protected getters for testing
  @protected
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @protected
  FirebaseAuth get auth => FirebaseAuth.instance;

  // Collection references
  CollectionReference get _notificationsCollection =>
      firestore.collection('notifications');
  CollectionReference get _usersCollection => firestore.collection('Users');

  /// Sends a settlement confirmation notification
  Future<void> sendSettlementNotification({
    required Settlement settlement,
    required String fromUserName,
    required String toUserName,
    required String groupName,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to send notifications');
    }

    // Create notification for the recipient (toUser)
    final notificationId = _notificationsCollection.doc().id;
    final notification = SettlementNotification(
      id: notificationId,
      userId: settlement.toUserId,
      type: NotificationType.settlementReceived,
      title: 'Payment Received',
      message:
          '$fromUserName paid you \$${settlement.amount.toStringAsFixed(2)} in $groupName',
      settlementId: settlement.id,
      groupId: settlement.groupId,
      fromUserId: settlement.fromUserId,
      amount: settlement.amount,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _notificationsCollection
        .doc(notificationId)
        .set(notification.toJson());

    // Create notification for the sender (fromUser) as confirmation
    final confirmationId = _notificationsCollection.doc().id;
    final confirmation = SettlementNotification(
      id: confirmationId,
      userId: settlement.fromUserId,
      type: NotificationType.settlementSent,
      title: 'Payment Confirmed',
      message:
          'Your payment of \$${settlement.amount.toStringAsFixed(2)} to $toUserName in $groupName has been recorded',
      settlementId: settlement.id,
      groupId: settlement.groupId,
      fromUserId: settlement.fromUserId,
      amount: settlement.amount,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _notificationsCollection
        .doc(confirmationId)
        .set(confirmation.toJson());
  }

  /// Gets notifications for the current user
  Future<List<SettlementNotification>> getUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to get notifications');
    }

    Query query = _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    final querySnapshot = await query.get();

    return querySnapshot.docs
        .map(
          (doc) => SettlementNotification.fromJson(
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Marks a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception(
        'User must be authenticated to mark notifications as read',
      );
    }

    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Marks all notifications as read for the current user
  Future<void> markAllNotificationsAsRead() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception(
        'User must be authenticated to mark notifications as read',
      );
    }

    final batch = firestore.batch();
    final unreadNotifications = await _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  /// Gets real-time stream of notifications for the current user
  Stream<List<SettlementNotification>> getUserNotificationsStream({
    int limit = 50,
    bool unreadOnly = false,
  }) {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream notifications');
    }

    Query query = _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => SettlementNotification.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  /// Gets count of unread notifications
  Future<int> getUnreadNotificationCount() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return 0;
    }

    final querySnapshot = await _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    return querySnapshot.docs.length;
  }

  /// Gets real-time stream of unread notification count
  Stream<int> getUnreadNotificationCountStream() {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Deletes old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to cleanup notifications');
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final oldNotifications = await _notificationsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final batch = firestore.batch();
    for (final doc in oldNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Gets user name by user ID (helper method)
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
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
