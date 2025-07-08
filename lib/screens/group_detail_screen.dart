import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String imageUrl;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Groups")
                  .doc(groupId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Group not found"));
                }

                final groupData = snapshot.data!.data() as Map<String, dynamic>;
                final expenses = List<Map<String, dynamic>>.from(
                  groupData["expenses"] ?? [],
                );

                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _expenseTile(expense);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _groupSummary(groupId), // Displays "Who owes who"
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to "Add Expense" screen
        },
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _expenseTile(Map<String, dynamic> expense) {
    final date = expense["date"] ?? "Unknown Date";
    final payer = expense["payerId"] ?? "Unknown";
    final payee = expense["payeeId"] ?? "Unknown";
    final amount = expense["amount"] ?? 0.0;
    final currency = expense["currency"] ?? "USD";
    final description = expense["description"] ?? "";

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Text(
          payer[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text("$payer paid $payee $currency$amount"),
      subtitle: Text("$date - $description"),
    );
  }

  Widget _groupSummary(String groupId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection("Groups").doc(groupId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final expenses = List<Map<String, dynamic>>.from(
          groupData["expenses"] ?? [],
        );

        final balances = _calculateBalances(expenses);
        if (balances.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("All balances are settled!"),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: balances.entries.map((entry) {
              final user = entry.key;
              final balance = entry.value;
              final status = balance > 0 ? "is owed" : "owes";
              return Text(
                "$user $status ${balance.abs()}",
                style: const TextStyle(fontSize: 16),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Map<String, double> _calculateBalances(List<Map<String, dynamic>> expenses) {
    final Map<String, double> balances = {};

    for (var expense in expenses) {
      final payer = expense["payerId"];
      final payee = expense["payeeId"];
      final amount = expense["amount"]?.toDouble() ?? 0.0;

      balances[payer] = (balances[payer] ?? 0) + amount;
      balances[payee] = (balances[payee] ?? 0) - amount;
    }

    return balances;
  }
}
