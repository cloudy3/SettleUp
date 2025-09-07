import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/app_error.dart';
import '../utils/retry_mechanism.dart';
import 'error_handling_service.dart';
import 'offline_manager.dart';

class GroupService with ErrorHandlingMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _usersCollection => _firestore.collection('Users');

  /// Creates a new group with the current user as creator and first member
  Future<Group> createGroup({
    required String name,
    required String description,
  }) async {
    return await executeWithErrorHandling<Group>(
      operation: () async {
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw AuthenticationError.notSignedIn();
        }

        if (name.trim().isEmpty) {
          throw ValidationError.required('Group name');
        }

        final now = DateTime.now();
        final groupId = _groupsCollection.doc().id;

        final group = Group(
          id: groupId,
          name: name.trim(),
          description: description.trim(),
          createdBy: currentUser.uid,
          createdAt: now,
          memberIds: [currentUser.uid],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        // Validate the group before saving
        if (!group.isValid) {
          throw ValidationError(
            message: 'Invalid group data',
            code: 'INVALID_GROUP_DATA',
          );
        }

        // Save group to Firestore
        await _groupsCollection.doc(groupId).set(group.toJson());

        // Update user's groups list
        await _usersCollection.doc(currentUser.uid).update({
          'groups': FieldValue.arrayUnion([groupId]),
        });

        return group;
      },
      operationName: 'createGroup',
      retryConfig: RetryConfig.conservative,
      offlineAction: OfflineAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: OfflineActionType.createGroup,
        data: {'name': name.trim(), 'description': description.trim()},
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Updates an existing group (only creator can update)
  Future<Group> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to update a group');
    }

    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);

    // Only creator can update group details
    if (group.createdBy != currentUser.uid) {
      throw Exception('Only group creator can update group details');
    }

    final updatedGroup = group.copyWith(
      name: name?.trim() ?? group.name,
      description: description?.trim() ?? group.description,
    );

    if (!updatedGroup.isValid) {
      throw ArgumentError('Invalid group data');
    }

    await _groupsCollection.doc(groupId).update({
      'name': updatedGroup.name,
      'description': updatedGroup.description,
    });

    return updatedGroup;
  }

  /// Fetches all groups for the current user
  Future<List<Group>> getGroupsForUser() async {
    return await executeWithErrorHandling<List<Group>>(
      operation: () async {
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw AuthenticationError.notSignedIn();
        }

        final querySnapshot = await _groupsCollection
            .where('memberIds', arrayContains: currentUser.uid)
            .get();

        return querySnapshot.docs
            .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      },
      operationName: 'getGroupsForUser',
      retryConfig: RetryConfig.network,
      fallbackValue: [], // Return empty list if offline
    );
  }

  /// Fetches a specific group by ID
  Future<Group?> getGroupById(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to fetch group');
    }

    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      return null;
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);

    // Check if user is a member of the group
    if (!group.memberIds.contains(currentUser.uid)) {
      throw Exception('Access denied: User is not a member of this group');
    }

    return group;
  }

  /// Sends invitations to join a group
  Future<void> inviteMembers({
    required String groupId,
    required List<String> emails,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to send invitations');
    }

    if (emails.isEmpty) {
      throw ArgumentError('Email list cannot be empty');
    }

    // Validate email formats
    for (final email in emails) {
      if (!_isValidEmail(email)) {
        throw ArgumentError('Invalid email format: $email');
      }
    }

    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);

    // Check if user is a member of the group
    if (!group.memberIds.contains(currentUser.uid)) {
      throw Exception('Only group members can send invitations');
    }

    final now = DateTime.now();
    final newInvitations = <GroupInvitation>[];

    for (final email in emails) {
      // Check if email is already invited or is a member
      final isAlreadyInvited = group.pendingInvitations.any(
        (inv) => inv.email == email && inv.status == InvitationStatus.pending,
      );

      if (isAlreadyInvited) {
        continue; // Skip already invited emails
      }

      // Check if user with this email is already a member
      final userQuery = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;
        if (group.memberIds.contains(userId)) {
          continue; // Skip users who are already members
        }
      }

      newInvitations.add(
        GroupInvitation(
          email: email,
          invitedBy: currentUser.uid,
          invitedAt: now,
          status: InvitationStatus.pending,
        ),
      );
    }

    if (newInvitations.isNotEmpty) {
      final updatedInvitations = [
        ...group.pendingInvitations,
        ...newInvitations,
      ];

      await _groupsCollection.doc(groupId).update({
        'pendingInvitations': updatedInvitations
            .map((inv) => inv.toJson())
            .toList(),
      });

      // Send notifications to invited users (if they have accounts)
      for (final invitation in newInvitations) {
        await _sendInvitationNotification(
          groupId: groupId,
          groupName: group.name,
          invitedEmail: invitation.email,
          invitedBy: currentUser.uid,
        );
      }
    }
  }

  /// Accepts a group invitation
  Future<void> acceptInvitation({
    required String groupId,
    required String email,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to accept invitation');
    }

    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);

    // Find the invitation
    final invitationIndex = group.pendingInvitations.indexWhere(
      (inv) => inv.email == email && inv.status == InvitationStatus.pending,
    );

    if (invitationIndex == -1) {
      throw Exception('Invitation not found or already processed');
    }

    // Check if current user's email matches the invitation
    if (currentUser.email != email) {
      throw Exception(
        'Email mismatch: Cannot accept invitation for different email',
      );
    }

    // Update invitation status and add user to group
    final updatedInvitations = List<GroupInvitation>.from(
      group.pendingInvitations,
    );
    updatedInvitations[invitationIndex] = updatedInvitations[invitationIndex]
        .copyWith(status: InvitationStatus.accepted);

    final updatedMemberIds = [...group.memberIds, currentUser.uid];

    // Update group document
    await _groupsCollection.doc(groupId).update({
      'memberIds': updatedMemberIds,
      'pendingInvitations': updatedInvitations
          .map((inv) => inv.toJson())
          .toList(),
    });

    // Update user's groups list
    await _usersCollection.doc(currentUser.uid).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });
  }

  /// Declines a group invitation
  Future<void> declineInvitation({
    required String groupId,
    required String email,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to decline invitation');
    }

    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);

    // Find the invitation
    final invitationIndex = group.pendingInvitations.indexWhere(
      (inv) => inv.email == email && inv.status == InvitationStatus.pending,
    );

    if (invitationIndex == -1) {
      throw Exception('Invitation not found or already processed');
    }

    // Check if current user's email matches the invitation
    if (currentUser.email != email) {
      throw Exception(
        'Email mismatch: Cannot decline invitation for different email',
      );
    }

    // Update invitation status
    final updatedInvitations = List<GroupInvitation>.from(
      group.pendingInvitations,
    );
    updatedInvitations[invitationIndex] = updatedInvitations[invitationIndex]
        .copyWith(status: InvitationStatus.declined);

    await _groupsCollection.doc(groupId).update({
      'pendingInvitations': updatedInvitations
          .map((inv) => inv.toJson())
          .toList(),
    });
  }

  /// Gets pending invitations for the current user
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to fetch invitations');
    }

    final querySnapshot = await _groupsCollection
        .where(
          'pendingInvitations',
          arrayContainsAny: [
            {'email': currentUser.email, 'status': 'pending'},
          ],
        )
        .get();

    final invitations = <Map<String, dynamic>>[];

    for (final doc in querySnapshot.docs) {
      final group = Group.fromJson(doc.data() as Map<String, dynamic>);

      for (final invitation in group.pendingInvitations) {
        if (invitation.email == currentUser.email &&
            invitation.status == InvitationStatus.pending) {
          invitations.add({
            'groupId': group.id,
            'groupName': group.name,
            'groupDescription': group.description,
            'invitation': invitation,
          });
        }
      }
    }

    return invitations;
  }

  /// Gets group members with their details
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to fetch group members');
    }

    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }

    final members = <Map<String, dynamic>>[];

    for (final memberId in group.memberIds) {
      final userDoc = await _usersCollection.doc(memberId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        members.add({
          'id': memberId,
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? '',
          'avatarName': userData['avatarName'] ?? '',
        });
      }
    }

    return members;
  }

  /// Removes a member from a group (only group creator can remove members)
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to remove members');
    }

    final groupDoc = await _groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }

    final group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);

    // Only group creator can remove members
    if (group.createdBy != currentUser.uid) {
      throw Exception('Only group creator can remove members');
    }

    // Cannot remove the group creator
    if (memberId == group.createdBy) {
      throw Exception('Cannot remove group creator');
    }

    // Check if member exists in the group
    if (!group.memberIds.contains(memberId)) {
      throw Exception('User is not a member of this group');
    }

    // Remove member from group
    final updatedMemberIds = group.memberIds
        .where((id) => id != memberId)
        .toList();

    await _groupsCollection.doc(groupId).update({
      'memberIds': updatedMemberIds,
    });

    // Remove group from user's groups list
    await _usersCollection.doc(memberId).update({
      'groups': FieldValue.arrayRemove([groupId]),
    });
  }

  /// Real-time stream of groups for the current user
  Stream<List<Group>> getGroupsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream groups');
    }

    return _groupsCollection
        .where('memberIds', arrayContains: currentUser.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Real-time stream of a specific group
  Stream<Group?> getGroupStream(String groupId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.error('User must be authenticated to stream group');
    }

    return _groupsCollection.doc(groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;

      final group = Group.fromJson(snapshot.data() as Map<String, dynamic>);

      // Check if user is a member
      if (!group.memberIds.contains(currentUser.uid)) {
        throw Exception('Access denied: User is not a member of this group');
      }

      return group;
    });
  }

  /// Helper method to validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Helper method to send invitation notification
  Future<void> _sendInvitationNotification({
    required String groupId,
    required String groupName,
    required String invitedEmail,
    required String invitedBy,
  }) async {
    try {
      // Check if user with this email exists
      final userQuery = await _usersCollection
          .where('email', isEqualTo: invitedEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;
        final inviterDoc = await _usersCollection.doc(invitedBy).get();
        final inviterName = inviterDoc.exists
            ? (inviterDoc.data() as Map<String, dynamic>)['name'] ?? 'Someone'
            : 'Someone';

        // Create notification document
        final notificationId = _firestore.collection('notifications').doc().id;
        await _firestore.collection('notifications').doc(notificationId).set({
          'id': notificationId,
          'userId': userId,
          'type': 'groupInvitation',
          'title': 'Group Invitation',
          'message': '$inviterName invited you to join "$groupName"',
          'createdAt': Timestamp.now(),
          'isRead': false,
          'readAt': null,
          'groupId': groupId,
          'groupName': groupName,
          'invitedBy': invitedBy,
        });
      }
    } catch (e) {
      // Silently handle notification errors - don't fail the invitation process
      print('Failed to send invitation notification: $e');
    }
  }
}
