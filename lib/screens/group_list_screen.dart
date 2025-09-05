import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:settle_up/models/group.dart";
import "package:settle_up/models/balance.dart";
import "package:settle_up/services/group_service.dart";
import "package:settle_up/services/balance_service.dart";
import "package:settle_up/screens/group_detail_screen.dart";
import "package:settle_up/screens/create_group_screen.dart";

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final GroupService _groupService = GroupService();
  final BalanceService _balanceService = BalanceService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text("Please log in to view groups"));
    }

    return Column(
      children: [
        _buildOverallBalanceHeader(),
        Expanded(
          child: StreamBuilder<List<Group>>(
            stream: _groupService.getGroupsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text("Error: ${snapshot.error}"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              final groups = snapshot.data ?? [];

              if (groups.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _buildGroupCard(group);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverallBalanceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FutureBuilder<double>(
              future: _calculateOverallBalance(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                final isOwed = balance > 0;
                final isOwing = balance < 0;

                String text;
                Color color;

                if (isOwed) {
                  text =
                      "Overall, you are owed \$${balance.toStringAsFixed(2)}";
                  color = Colors.green;
                } else if (isOwing) {
                  text = "Overall, you owe \$${(-balance).toStringAsFixed(2)}";
                  color = Colors.red;
                } else {
                  text = "You are all settled up!";
                  color = Colors.grey;
                }

                return Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: "Create Group",
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No groups yet",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first group to start\nsharing expenses with friends",
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Create Group"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            group.name.isNotEmpty ? group.name[0].toUpperCase() : "G",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          group.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            FutureBuilder<Balance?>(
              future: _getUserBalanceForGroup(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final balance = snapshot.data;
                if (balance == null) {
                  return Text(
                    "No expenses yet",
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }

                if (balance.isSettledUp) {
                  return Text(
                    "Settled up",
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }

                final netBalance = balance.netBalance;
                if (netBalance > 0) {
                  return Text(
                    "You are owed \$${netBalance.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.green),
                  );
                } else {
                  return Text(
                    "You owe \$${(-netBalance).toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(groupId: group.id),
            ),
          );
        },
      ),
    );
  }

  Future<double> _calculateOverallBalance() async {
    try {
      final groups = await _groupService.getGroupsForUser();
      double totalBalance = 0.0;

      for (final group in groups) {
        final balance = await _balanceService.getUserBalance(
          _currentUserId!,
          group.id,
        );
        totalBalance += balance.netBalance;
      }

      return totalBalance;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Balance?> _getUserBalanceForGroup(String groupId) async {
    try {
      return await _balanceService.getUserBalance(_currentUserId!, groupId);
    } catch (e) {
      return null;
    }
  }
}
