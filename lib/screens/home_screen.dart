import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:settle_up/screens/account_screen.dart";
import "package:settle_up/screens/group_list_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track the selected tab index

  // Pages for each tab
  final List<Widget> _pages = [
    const GroupListScreen(),
    const Center(child: Text("Friends Page")),
    const Center(child: Text("Activity Page")),
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

  @override
  void initState() {
    super.initState();
    String userId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    fetchUserData(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settle Up"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
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
