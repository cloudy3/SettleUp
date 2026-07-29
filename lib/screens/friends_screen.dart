import 'package:flutter/material.dart';

import 'package:settle_up/services/group_service.dart';

/// Non-group-style expenses: one ledger per friend via deduplicated pair groups.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final GroupService _groupService = GroupService();
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _groupService.getFriendsWithProfiles();
  }

  void _reload() {
    setState(() {
      _friendsFuture = _groupService.getFriendsWithProfiles();
    });
  }

  Future<void> _openAddExpense(String friendId) async {
    try {
      final group = await _groupService.getOrCreatePairGroup(otherUserId: friendId);
      if (!mounted) return;
      await Navigator.of(context).pushNamed('/add-expense/${group.id}');
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open expense: $e')),
      );
    }
  }

  Future<void> _showAddFriendDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'friend@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      controller.dispose();
      return;
    }

    final email = controller.text.trim();
    controller.dispose();

    if (email.isEmpty) return;

    try {
      await _groupService.addFriendByEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend added')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _friendsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }

            final friends = snapshot.data ?? [];
            if (friends.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.people_outline, size: 72, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'Add friends by email to split expenses outside a group.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _showAddFriendDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add friend'),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: friends.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'Tap a friend to add an expense in your shared ledger.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }
                final f = friends[index - 1];
                final name = f['name'] as String;
                final email = f['email'] as String;
                final id = f['id'] as String;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(name.isNotEmpty ? name : 'Unknown'),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.add_card),
                  onTap: () => _openAddExpense(id),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add friend'),
      ),
    );
  }
}
