import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
