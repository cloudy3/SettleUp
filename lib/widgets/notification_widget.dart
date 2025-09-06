import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Widget for displaying notifications with real-time updates
class NotificationWidget extends StatelessWidget {
  const NotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return PopupMenuButton<String>(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_none),
              if (appState.unreadNotificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${appState.unreadNotificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onSelected: (value) {
            if (value == 'view_all') {
              _showNotificationsDialog(context, appState);
            } else if (value == 'mark_all_read') {
              appState.markAllNotificationsAsRead();
            }
          },
          itemBuilder: (context) {
            final notifications = appState.notifications.take(5).toList();

            return [
              if (notifications.isEmpty)
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text('No notifications'),
                )
              else
                ...notifications.map(
                  (notification) => PopupMenuItem<String>(
                    value: notification.id,
                    child: _buildNotificationItem(notification),
                    onTap: () {
                      if (!notification.isRead) {
                        appState.markNotificationAsRead(notification.id);
                      }
                    },
                  ),
                ),

              if (notifications.isNotEmpty) ...[
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'view_all',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 18),
                      SizedBox(width: 8),
                      Text('View All'),
                    ],
                  ),
                ),
                if (appState.unreadNotificationCount > 0)
                  const PopupMenuItem<String>(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, size: 18),
                        SizedBox(width: 8),
                        Text('Mark All Read'),
                      ],
                    ),
                  ),
              ],
            ];
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(SettlementNotification notification) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                size: 16,
                color: notification.isRead ? Colors.grey : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            notification.message,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _formatNotificationTime(notification.createdAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
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

  void _showNotificationsDialog(
    BuildContext context,
    AppStateProvider appState,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: appState.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No notifications yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: appState.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = appState.notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getNotificationIcon(notification.type),
                          color: notification.isRead
                              ? Colors.grey
                              : Colors.blue,
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
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              _formatNotificationTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: !notification.isRead
                            ? IconButton(
                                icon: const Icon(
                                  Icons.mark_email_read,
                                  size: 18,
                                ),
                                onPressed: () {
                                  appState.markNotificationAsRead(
                                    notification.id,
                                  );
                                },
                              )
                            : null,
                        onTap: () {
                          if (!notification.isRead) {
                            appState.markNotificationAsRead(notification.id);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (appState.unreadNotificationCount > 0)
            TextButton(
              onPressed: () {
                appState.markAllNotificationsAsRead();
              },
              child: const Text('Mark All Read'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
