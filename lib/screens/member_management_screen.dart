import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';
import '../models/group.dart';

class MemberManagementScreen extends StatefulWidget {
  final String groupId;
  final Group group;

  const MemberManagementScreen({
    super.key,
    required this.groupId,
    required this.group,
  });

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _emailController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isSendingInvite = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _groupService.getGroupMembers(widget.groupId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSendingInvite = true;
    });

    try {
      await _groupService.inviteMembers(
        groupId: widget.groupId,
        emails: [email],
      );
      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the screen to show updated pending invitations
        Navigator.of(context).pop(true); // Return true to indicate changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingInvite = false;
        });
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Only group creator can remove members
    if (widget.group.createdBy != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only group creator can remove members'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cannot remove the group creator
    if (memberId == widget.group.createdBy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove group creator'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remove member from group
        await _groupService.removeMember(
          groupId: widget.groupId,
          memberId: memberId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$memberName removed from group'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMembers(); // Refresh the member list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = widget.group.createdBy == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invite new members section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_add,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Invite New Member',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'Enter email to invite',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isSendingInvite,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSendingInvite
                                  ? null
                                  : _sendInvitation,
                              child: _isSendingInvite
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Send Invitation'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current members section
                  Text(
                    'Current Members (${_members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._members.map(
                    (member) => _MemberCard(
                      member: member,
                      group: widget.group,
                      isCreator: isCreator,
                      currentUserId: currentUserId ?? '',
                      onRemove: () => _removeMember(
                        member['id'],
                        member['name'] ?? member['email'],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pending invitations section
                  if (widget.group.pendingInvitations.isNotEmpty) ...[
                    Text(
                      'Pending Invitations (${widget.group.pendingInvitations.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.group.pendingInvitations.map(
                      (invitation) =>
                          _PendingInvitationCard(invitation: invitation),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final Group group;
  final bool isCreator;
  final String currentUserId;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.group,
    required this.isCreator,
    required this.currentUserId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isGroupCreator = member['id'] == group.createdBy;
    final isCurrentUser = member['id'] == currentUserId;
    final canRemove = isCreator && !isGroupCreator && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            (member['name']?.isNotEmpty == true
                    ? member['name'][0]
                    : member['email'][0])
                .toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(member['name'] ?? member['email']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['email']),
            if (isGroupCreator)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: const Text('Creator', style: TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        trailing: canRemove
            ? IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Remove member',
              )
            : null,
      ),
    );
  }
}

class _PendingInvitationCard extends StatelessWidget {
  final GroupInvitation invitation;

  const _PendingInvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.schedule, color: Colors.white),
        ),
        title: Text(invitation.email),
        subtitle: Text('Invited ${_formatDate(invitation.invitedAt)}'),
        trailing: Chip(
          label: Text(
            invitation.status.name.toUpperCase(),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getStatusColor(
            invitation.status,
          ).withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.declined:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
