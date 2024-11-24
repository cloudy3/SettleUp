import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track the selected tab index

  // Pages for each tab
  final List<Widget> _pages = [
    const Center(
        child: Text("Groups Page")), // Replace with actual Group screen
    const Center(
        child: Text("Friends Page")), // Replace with actual Friends screen
    const Center(
        child: Text("Activity Page")), // Replace with actual Activity screen
    const Center(
        child: Text("Account Page")), // Replace with actual Account screen
  ];

  // Helper method to get initials from name
  String getInitials(String name) {
    List<String> nameParts = name.split(" ");
    if (nameParts.length == 1) {
      return nameParts[0][0]; // Single-word name
    }
    return nameParts[0][0] + nameParts[1][0]; // Two-word name
  }

  // Declare user details
  String? profileImageUrl;
  String userName = "";

  // Fetch user data from Firestore
  Future<void> fetchUserData(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        userName = userDoc['name'] ?? "User";
        profileImageUrl = userDoc['profileImageUrl'];
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
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile/settings
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected tab index
          });
        },
        items: [
          // Groups Tab
          const BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Groups",
          ),
          // Friends Tab
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Friends",
          ),
          // Activity Tab
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Activity",
          ),
          // Account Tab
          // Account Tab
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 12, // Adjust size as needed
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!) // Use actual profile picture
                  : null, // No profile picture
              backgroundColor:
                  Colors.blue.shade100, // Fallback background color
              child: profileImageUrl == null
                  ? Text(
                      getInitials(userName).toUpperCase(), // Display initials
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            label: "Account",
          ),
        ],
        type: BottomNavigationBarType.fixed, // Fixed layout for labels/icons
        selectedItemColor: Colors.blueAccent, // Color for selected tab
        unselectedItemColor: Colors.grey, // Color for unselected tabs
        showUnselectedLabels: true, // Show labels for unselected tabs
      ),
      body: Column(
        children: [
          // Balance Summary Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem("Total Balance", "\$120.00", Colors.white),
                _summaryItem("You Owe", "\$50.00", Colors.red[200]!),
                _summaryItem("Owed to You", "\$70.00", Colors.green[200]!),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Friends and Groups Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Friends and Groups",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle view all
                  },
                  child: const Text("View All"),
                ),
              ],
            ),
          ),
          Expanded(
            // Friends and Groups List
            child: ListView.builder(
              itemCount: 10, // Replace with your actual list count
              itemBuilder: (context, index) {
                return _friendGroupItem(
                  name: "Group $index", // Replace with actual name
                  balance:
                      index % 2 == 0 ? "+\$${index * 10}" : "-\$${index * 5}",
                  isPositive: index % 2 == 0,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Handle adding an expense
        },
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryItem(String label, String amount, Color amountColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _friendGroupItem({
    required String name,
    required String balance,
    required bool isPositive,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Text(
          name[0], // First letter of name
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: const Text("Settle expenses together"),
      trailing: Text(
        balance,
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Navigate to group/friend details
      },
    );
  }
}
