// Example usage of GroupService
// This file demonstrates how to use the GroupService in your Flutter app

import 'package:flutter/material.dart';
import 'package:settle_up/services/group_service.dart';
import 'package:settle_up/models/group.dart';

class GroupServiceExample {
  final GroupService _groupService = GroupService();

  /// Example: Create a new group
  Future<void> createNewGroup() async {
    try {
      final group = await _groupService.createGroup(
        name: 'Weekend Trip',
        description: 'Expenses for our weekend getaway',
      );

      print('Group created successfully: ${group.name}');
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  /// Example: Invite members to a group
  Future<void> inviteMembersToGroup(String groupId) async {
    try {
      await _groupService.inviteMembers(
        groupId: groupId,
        emails: ['friend1@example.com', 'friend2@example.com'],
      );

      print('Invitations sent successfully');
    } catch (e) {
      print('Error sending invitations: $e');
    }
  }

  /// Example: Accept an invitation
  Future<void> acceptGroupInvitation(String groupId, String email) async {
    try {
      await _groupService.acceptInvitation(groupId: groupId, email: email);

      print('Invitation accepted successfully');
    } catch (e) {
      print('Error accepting invitation: $e');
    }
  }

  /// Example: Get all groups for current user
  Future<List<Group>> getUserGroups() async {
    try {
      final groups = await _groupService.getGroupsForUser();
      print('Found ${groups.length} groups');
      return groups;
    } catch (e) {
      print('Error fetching groups: $e');
      return [];
    }
  }

  /// Example: Listen to real-time group updates
  Stream<List<Group>> listenToGroupUpdates() {
    return _groupService.getGroupsStream();
  }

  /// Example: Get group members
  Future<void> getGroupMembersInfo(String groupId) async {
    try {
      final members = await _groupService.getGroupMembers(groupId);
      print('Group has ${members.length} members:');
      for (final member in members) {
        print('- ${member['name']} (${member['email']})');
      }
    } catch (e) {
      print('Error fetching group members: $e');
    }
  }
}

/// Example Widget showing how to use GroupService in a Flutter widget
class GroupListWidget extends StatefulWidget {
  const GroupListWidget({super.key});

  @override
  State<GroupListWidget> createState() => _GroupListWidgetState();
}

class _GroupListWidgetState extends State<GroupListWidget> {
  final GroupService _groupService = GroupService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Group>>(
        stream: _groupService.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(
              child: Text('No groups yet. Create your first group!'),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.name),
                subtitle: Text(group.description),
                trailing: Text('\$${group.totalExpenses.toStringAsFixed(2)}'),
                onTap: () => _navigateToGroupDetail(group),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter group description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                _createGroup(nameController.text, descriptionController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup(String name, String description) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    try {
      await _groupService.createGroup(name: name, description: description);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
      }
    }
  }

  void _navigateToGroupDetail(Group group) {
    // Navigate to group detail screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => GroupDetailScreen(group: group),
    // ));
  }
}

/// Example Widget for managing group invitations
class GroupInvitationWidget extends StatefulWidget {
  final String groupId;

  const GroupInvitationWidget({super.key, required this.groupId});

  @override
  State<GroupInvitationWidget> createState() => _GroupInvitationWidgetState();
}

class _GroupInvitationWidgetState extends State<GroupInvitationWidget> {
  final GroupService _groupService = GroupService();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Members')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter email to invite',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendInvitation,
              child: const Text('Send Invitation'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Group Members:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _groupService.getGroupMembers(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final members = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (member['name'] as String).isNotEmpty
                                ? member['name'][0].toUpperCase()
                                : member['email'][0].toUpperCase(),
                          ),
                        ),
                        title: Text(member['name'] ?? 'No name'),
                        subtitle: Text(member['email'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    try {
      await _groupService.inviteMembers(
        groupId: widget.groupId,
        emails: [email],
      );

      _emailController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully!')),
        );
        setState(() {}); // Refresh the member list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending invitation: $e')));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
