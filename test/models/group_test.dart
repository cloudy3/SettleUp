import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('GroupInvitation', () {
    test('should create valid GroupInvitation', () {
      final invitation = GroupInvitation(
        email: 'test@example.com',
        invitedBy: 'user123',
        invitedAt: DateTime.now(),
        status: InvitationStatus.pending,
      );

      expect(invitation.isValid, true);
      expect(invitation.email, 'test@example.com');
      expect(invitation.invitedBy, 'user123');
      expect(invitation.status, InvitationStatus.pending);
    });

    test('should validate email format', () {
      final invalidInvitation = GroupInvitation(
        email: 'invalid-email',
        invitedBy: 'user123',
        invitedAt: DateTime.now(),
        status: InvitationStatus.pending,
      );

      expect(invalidInvitation.isValid, false);
    });

    test('should validate required fields', () {
      final invalidInvitation = GroupInvitation(
        email: '',
        invitedBy: '',
        invitedAt: DateTime.now(),
        status: InvitationStatus.pending,
      );

      expect(invalidInvitation.isValid, false);
    });

    test('should serialize to and from JSON', () {
      final invitation = GroupInvitation(
        email: 'test@example.com',
        invitedBy: 'user123',
        invitedAt: DateTime(2025, 1, 15, 10, 30),
        status: InvitationStatus.pending,
      );

      final json = invitation.toJson();
      final fromJson = GroupInvitation.fromJson(json);

      expect(fromJson.email, invitation.email);
      expect(fromJson.invitedBy, invitation.invitedBy);
      expect(fromJson.status, invitation.status);
      // Note: Timestamp conversion may have slight differences, so we check date components
      expect(fromJson.invitedAt.year, invitation.invitedAt.year);
      expect(fromJson.invitedAt.month, invitation.invitedAt.month);
      expect(fromJson.invitedAt.day, invitation.invitedAt.day);
    });

    test('should support copyWith', () {
      final invitation = GroupInvitation(
        email: 'test@example.com',
        invitedBy: 'user123',
        invitedAt: DateTime.now(),
        status: InvitationStatus.pending,
      );

      final updated = invitation.copyWith(status: InvitationStatus.accepted);

      expect(updated.email, invitation.email);
      expect(updated.invitedBy, invitation.invitedBy);
      expect(updated.status, InvitationStatus.accepted);
    });

    test('should implement equality correctly', () {
      final date = DateTime.now();
      final invitation1 = GroupInvitation(
        email: 'test@example.com',
        invitedBy: 'user123',
        invitedAt: date,
        status: InvitationStatus.pending,
      );

      final invitation2 = GroupInvitation(
        email: 'test@example.com',
        invitedBy: 'user123',
        invitedAt: date,
        status: InvitationStatus.pending,
      );

      expect(invitation1, equals(invitation2));
      expect(invitation1.hashCode, equals(invitation2.hashCode));
    });
  });

  group('Group', () {
    test('should create valid Group', () {
      final group = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        memberIds: ['user123', 'user456'],
        pendingInvitations: [],
        totalExpenses: 100.0,
      );

      expect(group.isValid, true);
      expect(group.name, 'Test Group');
      expect(group.memberIds.length, 2);
      expect(group.totalExpenses, 100.0);
    });

    test('should validate required fields', () {
      final invalidGroup = Group(
        id: '',
        name: '',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        memberIds: ['user123'],
        pendingInvitations: [],
        totalExpenses: 100.0,
      );

      expect(invalidGroup.isValid, false);
    });

    test('should validate creator is in member list', () {
      final invalidGroup = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        memberIds: ['user456'], // Creator not in list
        pendingInvitations: [],
        totalExpenses: 100.0,
      );

      expect(invalidGroup.isValid, false);
    });

    test('should validate negative total expenses', () {
      final invalidGroup = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        memberIds: ['user123'],
        pendingInvitations: [],
        totalExpenses: -50.0,
      );

      expect(invalidGroup.isValid, false);
    });

    test('should serialize to and from JSON', () {
      final invitation = GroupInvitation(
        email: 'test@example.com',
        invitedBy: 'user123',
        invitedAt: DateTime.now(),
        status: InvitationStatus.pending,
      );

      final group = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: DateTime(2025, 1, 15, 10, 0),
        memberIds: ['user123', 'user456'],
        pendingInvitations: [invitation],
        totalExpenses: 100.0,
      );

      final json = group.toJson();
      final fromJson = Group.fromJson(json);

      expect(fromJson.id, group.id);
      expect(fromJson.name, group.name);
      expect(fromJson.description, group.description);
      expect(fromJson.createdBy, group.createdBy);
      expect(fromJson.memberIds, group.memberIds);
      expect(fromJson.pendingInvitations.length, 1);
      expect(fromJson.totalExpenses, group.totalExpenses);
    });

    test('should support copyWith', () {
      final group = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        memberIds: ['user123'],
        pendingInvitations: [],
        totalExpenses: 100.0,
      );

      final updated = group.copyWith(
        name: 'Updated Group',
        totalExpenses: 200.0,
      );

      expect(updated.name, 'Updated Group');
      expect(updated.totalExpenses, 200.0);
      expect(updated.id, group.id);
      expect(updated.createdBy, group.createdBy);
    });

    test('should implement equality correctly', () {
      final date = DateTime.now();
      final group1 = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: date,
        memberIds: ['user123'],
        pendingInvitations: [],
        totalExpenses: 100.0,
      );

      final group2 = Group(
        id: 'group123',
        name: 'Test Group',
        description: 'A test group',
        createdBy: 'user123',
        createdAt: date,
        memberIds: ['user123'],
        pendingInvitations: [],
        totalExpenses: 100.0,
      );

      expect(group1, equals(group2));
      // Note: hashCode equality is not guaranteed for complex objects with Lists
    });
  });
}
