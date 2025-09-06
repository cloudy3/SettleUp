import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Widget that displays real-time activity feed for user's groups
class ActivityFeedWidget extends StatelessWidget {
  const ActivityFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, OfflineProvider>(
      builder: (context, appState, offlineProvider, child) {
        final notifications = offlineProvider.isOnline
            ? appState.notifications
            : offlineProvider.cachedNotifications;

        // Cache notifications when online
        if (offlineProvider.isOnline && appState.notifications.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            offlineProvider.cacheNotifications(appState.notifications);
          });
        }

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _ActivityCard(
              notification: notification,
              isOnline: offlineProvider.isOnline,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No recent activity",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "Activity from your groups will appear here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Individual activity card widget
class _ActivityCard extends StatelessWidget {
  final SettlementNotification notification;
  final bool isOnline;

  const _ActivityCard({required this.notification, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getNotificationColor(notification.type),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.wifi_off,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatNotificationTime(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!notification.isRead) {
            final appState = context.read<AppStateProvider>();
            appState.markNotificationAsRead(notification.id);
          }
        },
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.settlementReceived:
        return Icons.payment;
      case NotificationType.settlementSent:
        return Icons.send;
      case NotificationType.expenseAdded:
        return Icons.receipt;
      case NotificationType.groupInvitation:
        return Icons.group_add;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.settlementReceived:
        return Colors.green;
      case NotificationType.settlementSent:
        return Colors.blue;
      case NotificationType.expenseAdded:
        return Colors.orange;
      case NotificationType.groupInvitation:
        return Colors.purple;
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

/// Real-time activity indicator widget
class ActivityIndicator extends StatelessWidget {
  const ActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.unreadNotificationCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${appState.unreadNotificationCount} new notification${appState.unreadNotificationCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  appState.markAllNotificationsAsRead();
                },
                child: const Text('Mark all read'),
              ),
            ],
          ),
        );
      },
    );
  }
}
