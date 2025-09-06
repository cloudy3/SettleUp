import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:settle_up/models/group.dart";
import "package:settle_up/models/balance.dart";
import "package:settle_up/services/services.dart";
import "package:settle_up/providers/providers.dart";
import "package:settle_up/screens/group_detail_screen.dart";
import "package:settle_up/screens/create_group_screen.dart";

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final BalanceService _balanceService = BalanceService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text("Please log in to view groups"));
    }

    return Consumer2<AppStateProvider, OfflineProvider>(
      builder: (context, appState, offlineProvider, child) {
        // Use cached data when offline
        final groups = offlineProvider.isOnline
            ? appState.groups
            : offlineProvider.cachedGroups;

        // Cache data when online
        if (offlineProvider.isOnline && appState.groups.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            offlineProvider.cacheGroups(appState.groups);
          });
        }

        return Column(
          children: [
            _buildOverallBalanceHeader(appState, groups),
            Expanded(
              child: _buildGroupsList(
                appState,
                groups,
                offlineProvider.isOnline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupsList(
    AppStateProvider appState,
    List<Group> groups,
    bool isOnline,
  ) {
    // Show loading only when online and actually loading
    if (isOnline && appState.isLoadingGroups && groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error only when online
    if (isOnline && appState.error != null && groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text("Error: ${appState.error}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => appState.refreshGroups(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (groups.isEmpty) {
      return _buildEmptyState(isOnline);
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(group, isOnline);
      },
    );
  }

  Widget _buildOverallBalanceHeader(
    AppStateProvider appState,
    List<Group> groups,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FutureBuilder<double>(
              future: _calculateOverallBalance(groups),
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
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );

              // Refresh groups if a new group was created
              if (result == true) {
                appState.refreshGroups();
              }
            },
            icon: const Icon(Icons.add),
            tooltip: "Create Group",
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isOnline) {
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

  Widget _buildGroupCard(Group group, bool isOnline) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOnline)
              Icon(Icons.wifi_off, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
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

  Future<double> _calculateOverallBalance(List<Group> groups) async {
    try {
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
