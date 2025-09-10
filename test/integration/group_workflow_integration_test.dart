import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('Group Workflow Integration Tests', () {
    const String testUserId = 'test_user_123';
    const String testUserEmail = 'test@example.com';
    const String otherUserId = 'other_user_456';
    const String otherUserEmail = 'other@example.com';
    const String thirdUserId = 'third_user_789';
    const String thirdUserEmail = 'third@example.com';
    const String testGroupId = 'test_group_123';

    group('Complete Group Creation Flow', () {
      testWidgets('should create group with proper validation', (tester) async {
        // Step 1: Create group
        final group = Group(
          id: testGroupId,
          name: 'Vacation Group',
          description: 'Summer vacation expenses',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        // Validate group creation
        expect(group.isValid, isTrue);
        expect(group.memberIds.contains(testUserId), isTrue);
        expect(group.createdBy, testUserId);
        expect(group.pendingInvitations.isEmpty, isTrue);
        expect(group.totalExpenses, 0.0);

        // Step 2: Verify creator is automatically added as member
        expect(group.memberIds.length, 1);
        expect(group.memberIds.first, testUserId);

        // Step 3: Verify group can be serialized/deserialized
        final groupJson = group.toJson();
        final deserializedGroup = Group.fromJson(groupJson);
        expect(deserializedGroup, group);
      });

      testWidgets('should validate group creation requirements', (
        tester,
      ) async {
        // Test invalid group names
        final invalidGroups = [
          Group(
            id: testGroupId,
            name: '', // Empty name
            description: 'Test',
            createdBy: testUserId,
            createdAt: DateTime.now(),
            memberIds: [testUserId],
            pendingInvitations: [],
            totalExpenses: 0.0,
          ),
          Group(
            id: testGroupId,
            name: '   ', // Whitespace only
            description: 'Test',
            createdBy: testUserId,
            createdAt: DateTime.now(),
            memberIds: [testUserId],
            pendingInvitations: [],
            totalExpenses: 0.0,
          ),
          Group(
            id: testGroupId,
            name: 'Valid Name',
            description: 'Test',
            createdBy: testUserId,
            createdAt: DateTime.now(),
            memberIds: [], // Empty member list
            pendingInvitations: [],
            totalExpenses: 0.0,
          ),
          Group(
            id: testGroupId,
            name: 'Valid Name',
            description: 'Test',
            createdBy: testUserId,
            createdAt: DateTime.now(),
            memberIds: [otherUserId], // Creator not in members
            pendingInvitations: [],
            totalExpenses: 0.0,
          ),
        ];

        for (final group in invalidGroups) {
          expect(group.isValid, isFalse);
        }
      });
    });

    group('Member Invitation Flow', () {
      testWidgets('should handle single member invitation', (tester) async {
        // Initial group
        final group = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test Description',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        // Step 1: Create invitation
        final invitation = GroupInvitation(
          email: otherUserEmail,
          invitedBy: testUserId,
          invitedAt: DateTime.now(),
          status: InvitationStatus.pending,
        );

        expect(invitation.isValid, isTrue);
        expect(invitation.status, InvitationStatus.pending);

        // Step 2: Add invitation to group
        final groupWithInvitation = group.copyWith(
          pendingInvitations: [invitation],
        );

        expect(groupWithInvitation.pendingInvitations.length, 1);
        expect(
          groupWithInvitation.pendingInvitations.first.email,
          otherUserEmail,
        );
        expect(
          groupWithInvitation.pendingInvitations.first.invitedBy,
          testUserId,
        );

        // Step 3: Accept invitation
        final acceptedInvitation = invitation.copyWith(
          status: InvitationStatus.accepted,
        );

        final groupWithNewMember = groupWithInvitation.copyWith(
          memberIds: [testUserId, otherUserId],
          pendingInvitations: [acceptedInvitation],
        );

        expect(groupWithNewMember.memberIds.length, 2);
        expect(groupWithNewMember.memberIds.contains(otherUserId), isTrue);
        expect(
          groupWithNewMember.pendingInvitations.first.status,
          InvitationStatus.accepted,
        );

        // Step 4: Verify final group state
        expect(groupWithNewMember.isValid, isTrue);
      });

      testWidgets('should handle multiple member invitations', (tester) async {
        final group = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test Description',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        // Step 1: Create multiple invitations
        final invitations = [
          GroupInvitation(
            email: otherUserEmail,
            invitedBy: testUserId,
            invitedAt: DateTime.now(),
            status: InvitationStatus.pending,
          ),
          GroupInvitation(
            email: thirdUserEmail,
            invitedBy: testUserId,
            invitedAt: DateTime.now(),
            status: InvitationStatus.pending,
          ),
        ];

        final groupWithInvitations = group.copyWith(
          pendingInvitations: invitations,
        );

        expect(groupWithInvitations.pendingInvitations.length, 2);

        // Step 2: Accept first invitation
        final updatedInvitations = List<GroupInvitation>.from(invitations);
        updatedInvitations[0] = updatedInvitations[0].copyWith(
          status: InvitationStatus.accepted,
        );

        final groupWithFirstAccepted = groupWithInvitations.copyWith(
          memberIds: [testUserId, otherUserId],
          pendingInvitations: updatedInvitations,
        );

        expect(groupWithFirstAccepted.memberIds.length, 2);
        expect(
          groupWithFirstAccepted.pendingInvitations[0].status,
          InvitationStatus.accepted,
        );
        expect(
          groupWithFirstAccepted.pendingInvitations[1].status,
          InvitationStatus.pending,
        );

        // Step 3: Decline second invitation
        updatedInvitations[1] = updatedInvitations[1].copyWith(
          status: InvitationStatus.declined,
        );

        final finalGroup = groupWithFirstAccepted.copyWith(
          pendingInvitations: updatedInvitations,
        );

        expect(finalGroup.memberIds.length, 2);
        expect(finalGroup.memberIds.contains(thirdUserId), isFalse);
        expect(
          finalGroup.pendingInvitations[1].status,
          InvitationStatus.declined,
        );
      });

      testWidgets('should validate invitation data', (tester) async {
        // Test invalid invitations
        final invalidInvitations = [
          GroupInvitation(
            email: '', // Empty email
            invitedBy: testUserId,
            invitedAt: DateTime.now(),
            status: InvitationStatus.pending,
          ),
          GroupInvitation(
            email: 'invalid-email', // Invalid email format
            invitedBy: testUserId,
            invitedAt: DateTime.now(),
            status: InvitationStatus.pending,
          ),
          GroupInvitation(
            email: otherUserEmail,
            invitedBy: '', // Empty inviter
            invitedAt: DateTime.now(),
            status: InvitationStatus.pending,
          ),
        ];

        for (final invitation in invalidInvitations) {
          expect(invitation.isValid, isFalse);
        }

        // Test valid invitation
        final validInvitation = GroupInvitation(
          email: otherUserEmail,
          invitedBy: testUserId,
          invitedAt: DateTime.now(),
          status: InvitationStatus.pending,
        );

        expect(validInvitation.isValid, isTrue);
      });

      testWidgets('should handle invitation status transitions', (
        tester,
      ) async {
        final invitation = GroupInvitation(
          email: otherUserEmail,
          invitedBy: testUserId,
          invitedAt: DateTime.now(),
          status: InvitationStatus.pending,
        );

        // Test status transitions
        final acceptedInvitation = invitation.copyWith(
          status: InvitationStatus.accepted,
        );
        expect(acceptedInvitation.status, InvitationStatus.accepted);

        final declinedInvitation = invitation.copyWith(
          status: InvitationStatus.declined,
        );
        expect(declinedInvitation.status, InvitationStatus.declined);

        // Verify other properties remain unchanged
        expect(acceptedInvitation.email, invitation.email);
        expect(acceptedInvitation.invitedBy, invitation.invitedBy);
        expect(acceptedInvitation.invitedAt, invitation.invitedAt);
      });
    });

    group('Group Member Management', () {
      testWidgets('should handle member removal', (tester) async {
        // Group with multiple members
        final group = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test Description',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId, otherUserId, thirdUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        expect(group.memberIds.length, 3);

        // Remove a member (not the creator)
        final updatedMemberIds = group.memberIds
            .where((id) => id != otherUserId)
            .toList();

        final groupWithRemovedMember = group.copyWith(
          memberIds: updatedMemberIds,
        );

        expect(groupWithRemovedMember.memberIds.length, 2);
        expect(groupWithRemovedMember.memberIds.contains(otherUserId), isFalse);
        expect(groupWithRemovedMember.memberIds.contains(testUserId), isTrue);
        expect(groupWithRemovedMember.memberIds.contains(thirdUserId), isTrue);

        // Verify group is still valid
        expect(groupWithRemovedMember.isValid, isTrue);
      });

      testWidgets('should prevent creator removal', (tester) async {
        final group = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test Description',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId, otherUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        // Attempt to remove creator
        final updatedMemberIds = group.memberIds
            .where((id) => id != testUserId)
            .toList();

        final groupWithoutCreator = group.copyWith(memberIds: updatedMemberIds);

        // Group should be invalid without creator
        expect(groupWithoutCreator.isValid, isFalse);
      });

      testWidgets('should handle group with single member', (tester) async {
        final singleMemberGroup = Group(
          id: testGroupId,
          name: 'Solo Group',
          description: 'Just me',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );

        expect(singleMemberGroup.isValid, isTrue);
        expect(singleMemberGroup.memberIds.length, 1);
        expect(singleMemberGroup.memberIds.first, testUserId);
      });
    });

    group('Group Data Integrity', () {
      testWidgets('should maintain data consistency during updates', (
        tester,
      ) async {
        final originalGroup = Group(
          id: testGroupId,
          name: 'Original Name',
          description: 'Original Description',
          createdBy: testUserId,
          createdAt: DateTime(2025, 1, 1),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: 100.0,
        );

        // Update only name
        final updatedGroup = originalGroup.copyWith(name: 'New Name');

        expect(updatedGroup.name, 'New Name');
        expect(updatedGroup.description, originalGroup.description);
        expect(updatedGroup.createdBy, originalGroup.createdBy);
        expect(updatedGroup.createdAt, originalGroup.createdAt);
        expect(updatedGroup.memberIds, originalGroup.memberIds);
        expect(updatedGroup.totalExpenses, originalGroup.totalExpenses);

        // Update multiple fields
        final multiUpdatedGroup = originalGroup.copyWith(
          name: 'Multi Update Name',
          description: 'Multi Update Description',
          totalExpenses: 200.0,
        );

        expect(multiUpdatedGroup.name, 'Multi Update Name');
        expect(multiUpdatedGroup.description, 'Multi Update Description');
        expect(multiUpdatedGroup.totalExpenses, 200.0);
        expect(multiUpdatedGroup.createdBy, originalGroup.createdBy);
        expect(multiUpdatedGroup.memberIds, originalGroup.memberIds);
      });

      testWidgets('should handle serialization and deserialization correctly', (
        tester,
      ) async {
        final group = Group(
          id: testGroupId,
          name: 'Serialization Test',
          description: 'Testing JSON conversion',
          createdBy: testUserId,
          createdAt: DateTime(2025, 1, 15, 10, 30, 45),
          memberIds: [testUserId, otherUserId],
          pendingInvitations: [
            GroupInvitation(
              email: thirdUserEmail,
              invitedBy: testUserId,
              invitedAt: DateTime(2025, 1, 15, 11, 0, 0),
              status: InvitationStatus.pending,
            ),
          ],
          totalExpenses: 150.75,
        );

        // Serialize to JSON
        final json = group.toJson();

        // Verify JSON structure
        expect(json['id'], testGroupId);
        expect(json['name'], 'Serialization Test');
        expect(json['description'], 'Testing JSON conversion');
        expect(json['createdBy'], testUserId);
        expect(json['memberIds'], [testUserId, otherUserId]);
        expect(json['totalExpenses'], 150.75);
        expect(json['pendingInvitations'], isA<List>());
        expect(json['pendingInvitations'].length, 1);

        // Deserialize from JSON
        final deserializedGroup = Group.fromJson(json);

        // Verify deserialized group matches original
        expect(deserializedGroup.id, group.id);
        expect(deserializedGroup.name, group.name);
        expect(deserializedGroup.description, group.description);
        expect(deserializedGroup.createdBy, group.createdBy);
        expect(deserializedGroup.memberIds, group.memberIds);
        expect(deserializedGroup.totalExpenses, group.totalExpenses);
        expect(deserializedGroup.pendingInvitations.length, 1);
        expect(
          deserializedGroup.pendingInvitations.first.email,
          thirdUserEmail,
        );
      });

      testWidgets('should handle edge cases in group data', (tester) async {
        // Test with maximum reasonable values
        final largeGroup = Group(
          id: testGroupId,
          name: 'A' * 100, // Long name
          description: 'B' * 500, // Long description
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [
            testUserId,
            ...List.generate(49, (index) => 'user_$index'),
          ], // Many members including creator
          pendingInvitations: List.generate(
            20,
            (index) => GroupInvitation(
              email: 'user$index@example.com',
              invitedBy: testUserId,
              invitedAt: DateTime.now(),
              status: InvitationStatus.pending,
            ),
          ),
          totalExpenses: 999999.99, // Large expense total
        );

        expect(largeGroup.isValid, isTrue);
        expect(largeGroup.memberIds.length, 50);
        expect(largeGroup.pendingInvitations.length, 20);

        // Test serialization of large group
        final json = largeGroup.toJson();
        final deserializedGroup = Group.fromJson(json);
        expect(deserializedGroup.memberIds.length, 50);
        expect(deserializedGroup.pendingInvitations.length, 20);
      });
    });

    group('Group Validation Rules', () {
      testWidgets('should enforce business rules', (tester) async {
        // Rule: Group name cannot be empty or whitespace
        final emptyNameGroup = Group(
          id: testGroupId,
          name: '',
          description: 'Test',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );
        expect(emptyNameGroup.isValid, isFalse);

        // Rule: Creator must be in member list
        final creatorNotMemberGroup = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [otherUserId],
          pendingInvitations: [],
          totalExpenses: 0.0,
        );
        expect(creatorNotMemberGroup.isValid, isFalse);

        // Rule: Total expenses cannot be negative
        final negativeExpensesGroup = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [],
          totalExpenses: -100.0,
        );
        expect(negativeExpensesGroup.isValid, isFalse);

        // Rule: All invitations must be valid
        final invalidInvitationGroup = Group(
          id: testGroupId,
          name: 'Test Group',
          description: 'Test',
          createdBy: testUserId,
          createdAt: DateTime.now(),
          memberIds: [testUserId],
          pendingInvitations: [
            GroupInvitation(
              email: 'invalid-email',
              invitedBy: testUserId,
              invitedAt: DateTime.now(),
              status: InvitationStatus.pending,
            ),
          ],
          totalExpenses: 0.0,
        );
        expect(invalidInvitationGroup.isValid, isFalse);
      });

      testWidgets('should validate invitation business rules', (tester) async {
        // Rule: Email must be valid format
        final invalidEmailInvitation = GroupInvitation(
          email: 'not-an-email',
          invitedBy: testUserId,
          invitedAt: DateTime.now(),
          status: InvitationStatus.pending,
        );
        expect(invalidEmailInvitation.isValid, isFalse);

        // Rule: Inviter cannot be empty
        final emptyInviterInvitation = GroupInvitation(
          email: otherUserEmail,
          invitedBy: '',
          invitedAt: DateTime.now(),
          status: InvitationStatus.pending,
        );
        expect(emptyInviterInvitation.isValid, isFalse);

        // Valid invitation
        final validInvitation = GroupInvitation(
          email: otherUserEmail,
          invitedBy: testUserId,
          invitedAt: DateTime.now(),
          status: InvitationStatus.pending,
        );
        expect(validInvitation.isValid, isTrue);
      });
    });
  });
}
