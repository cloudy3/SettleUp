import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:settle_up/screens/account_screen.dart";
import "package:settle_up/screens/group_list_screen.dart";
import "package:settle_up/screens/invitation_screen.dart";
import "package:settle_up/screens/create_group_screen.dart";
import "package:settle_up/services/group_service.dart";
import "package:settle_up/widgets/notification_widget.dart";
import "package:settle_up/widgets/offline_indicator.dart";
import "package:settle_up/widgets/activity_feed_widget.dart";
import "package:settle_up/providers/providers.dart";
import "package:settle_up/models/models.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track the selected tab index
  final GroupService _groupService = GroupService();
  int _pendingInvitationsCount = 0;

  // Pages for each tab
  final List<Widget> _pages = [
    const GroupListScreen(),
    const Center(child: Text("Friends Page")),
    const ActivityFeedWidget(),
    const AccountScreen(),
  ];

  // Declare user details
  String? avatarName;
  String userName = "";

  // Fetch user data from Firestore
  Future<void> fetchUserData(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        userName = userDoc["name"] ?? "User";
        avatarName =
            userDoc["avatarName"]; // Fetch avatar name saved in Firestore
      });
    }
  }

  // Fetch pending invitations count
  Future<void> _fetchPendingInvitationsCount() async {
    try {
      final invitations = await _groupService.getPendingInvitations();
      if (mounted) {
        setState(() {
          _pendingInvitationsCount = invitations.length;
        });
      }
    } catch (e) {
      // Silently handle errors for invitation count
      if (mounted) {
        setState(() {
          _pendingInvitationsCount = 0;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    String userId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    fetchUserData(userId);
    _fetchPendingInvitationsCount();
  }

  /// Show options for adding expense - either create new group or select existing group
  void _showAddExpenseOptions(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final groups = appState.groups;

    if (groups.isEmpty) {
      // No groups available, prompt to create one
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Groups Available'),
          content: const Text(
            'You need to create a group first before adding expenses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
              child: const Text('Create Group'),
            ),
          ],
        ),
      );
      return;
    }

    // Show group selection bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a group to add expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...groups.map(
              (group) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(group.name),
                subtitle: Text('${group.memberIds.length} members'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/add-expense/${group.id}');
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) => Scaffold(
        appBar: AppBar(
          title: const Text("Settle Up"),
          actions: [
            // Invitations button with badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.mail_outline),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const InvitationScreen(),
                      ),
                    );
                    // Refresh invitation count after returning
                    if (result == true || result == null) {
                      _fetchPendingInvitationsCount();
                    }
                  },
                  tooltip: 'Group Invitations',
                ),
                if (_pendingInvitationsCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
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
                        '$_pendingInvitationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const NotificationWidget(),
          ],
        ),
        body: Column(
          children: [
            const OfflineIndicator(),
            // Show group shortcuts and recent activity on Groups tab
            if (_currentIndex == 0) ...[
              _buildGroupShortcuts(context, appState),
              _buildRecentActivity(context, appState),
            ],
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: "Groups",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Friends",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: "Activity",
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage(
                  "$avatarName",
                ), // Display the selected avatar
                backgroundColor: Colors.blue.shade100,
              ),
              label: "Account",
            ),
          ],
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  _showAddExpenseOptions(context);
                },
                label: const Text("Add Expense"),
                icon: const Icon(Icons.add),
              )
            : null, // Show FAB only on Groups Page
      ),
    );
  }

  /// Build group shortcuts section
  Widget _buildGroupShortcuts(BuildContext context, AppStateProvider appState) {
    final recentGroups = appState.groups.take(3).toList();

    if (recentGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Switch to groups tab if not already there
                  setState(() {
                    _currentIndex = 0;
                  });
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentGroups.length,
              itemBuilder: (context, index) {
                final group = recentGroups[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/group/${group.id}');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                group.name.isNotEmpty
                                    ? group.name[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent activity section
  Widget _buildRecentActivity(BuildContext context, AppStateProvider appState) {
    final recentNotifications = appState.notifications.take(3).toList();

    if (recentNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Switch to activity tab
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentNotifications.map(
            (notification) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getNotificationColor(notification.type),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  notification.message,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: !notification.isRead
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  if (!notification.isRead) {
                    appState.markNotificationAsRead(notification.id);
                  }
                  // Switch to activity tab to show full details
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get notification icon based on type
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

  /// Get notification color based on type
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
}
