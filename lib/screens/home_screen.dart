import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:settle_up/screens/account_screen.dart";
import "package:settle_up/screens/group_list_screen.dart";
import "package:settle_up/screens/invitation_screen.dart";
import "package:settle_up/services/group_service.dart";
import "package:settle_up/widgets/notification_widget.dart";
import "package:settle_up/widgets/offline_indicator.dart";
import "package:settle_up/widgets/activity_feed_widget.dart";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                // TODO: Navigate to Add Expense screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Add Expense feature coming soon!"),
                  ),
                );
              },
              label: const Text("Add Expense"),
              icon: const Icon(Icons.add),
            )
          : null, // Show FAB only on Groups Page
    );
  }
}
