import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/expense_audit.dart';

void main() {
  group('ExpenseAudit', () {
    test('should create ExpenseAudit with all properties', () {
      final now = DateTime.now();
      final audit = ExpenseAudit(
        id: 'audit_123',
        expenseId: 'expense_456',
        groupId: 'group_789',
        action: ExpenseAuditAction.created,
        performedBy: 'user_123',
        performedAt: now,
        newData: {'amount': 100.0},
      );

      expect(audit.id, 'audit_123');
      expect(audit.expenseId, 'expense_456');
      expect(audit.groupId, 'group_789');
      expect(audit.action, ExpenseAuditAction.created);
      expect(audit.performedBy, 'user_123');
      expect(audit.performedAt, now);
      expect(audit.newData, {'amount': 100.0});
      expect(audit.previousData, null);
      expect(audit.reason, null);
    });

    test('should serialize to JSON correctly', () {
      final now = DateTime.now();
      final audit = ExpenseAudit(
        id: 'audit_123',
        expenseId: 'expense_456',
        groupId: 'group_789',
        action: ExpenseAuditAction.updated,
        performedBy: 'user_123',
        performedAt: now,
        previousData: {'amount': 50.0},
        newData: {'amount': 100.0},
        reason: 'Amount correction',
      );

      final json = audit.toJson();

      expect(json['id'], 'audit_123');
      expect(json['expenseId'], 'expense_456');
      expect(json['groupId'], 'group_789');
      expect(json['action'], 'updated');
      expect(json['performedBy'], 'user_123');
      expect(json['performedAt'], isA<Timestamp>());
      expect(json['previousData'], {'amount': 50.0});
      expect(json['newData'], {'amount': 100.0});
      expect(json['reason'], 'Amount correction');
    });

    test('should deserialize from JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'audit_123',
        'expenseId': 'expense_456',
        'groupId': 'group_789',
        'action': 'deleted',
        'performedBy': 'user_123',
        'performedAt': Timestamp.fromDate(now),
        'previousData': {'amount': 100.0},
        'newData': null,
        'reason': 'Duplicate expense',
      };

      final audit = ExpenseAudit.fromJson(json);

      expect(audit.id, 'audit_123');
      expect(audit.expenseId, 'expense_456');
      expect(audit.groupId, 'group_789');
      expect(audit.action, ExpenseAuditAction.deleted);
      expect(audit.performedBy, 'user_123');
      expect(
        audit.performedAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(audit.previousData, {'amount': 100.0});
      expect(audit.newData, null);
      expect(audit.reason, 'Duplicate expense');
    });

    test('should handle missing fields in JSON', () {
      final json = {
        'id': 'audit_123',
        'expenseId': 'expense_456',
        'groupId': 'group_789',
        'action': 'created',
        'performedBy': 'user_123',
      };

      final audit = ExpenseAudit.fromJson(json);

      expect(audit.id, 'audit_123');
      expect(audit.action, ExpenseAuditAction.created);
      expect(audit.previousData, null);
      expect(audit.newData, null);
      expect(audit.reason, null);
      expect(audit.performedAt, isA<DateTime>());
    });

    test('should create copy with updated fields', () {
      final original = ExpenseAudit(
        id: 'audit_123',
        expenseId: 'expense_456',
        groupId: 'group_789',
        action: ExpenseAuditAction.created,
        performedBy: 'user_123',
        performedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        action: ExpenseAuditAction.updated,
        reason: 'Updated reason',
      );

      expect(updated.id, original.id);
      expect(updated.expenseId, original.expenseId);
      expect(updated.action, ExpenseAuditAction.updated);
      expect(updated.reason, 'Updated reason');
      expect(updated.performedBy, original.performedBy);
    });

    test('should handle equality correctly', () {
      final now = DateTime.now();
      final audit1 = ExpenseAudit(
        id: 'audit_123',
        expenseId: 'expense_456',
        groupId: 'group_789',
        action: ExpenseAuditAction.created,
        performedBy: 'user_123',
        performedAt: now,
      );

      final audit2 = ExpenseAudit(
        id: 'audit_123',
        expenseId: 'expense_456',
        groupId: 'group_789',
        action: ExpenseAuditAction.created,
        performedBy: 'user_123',
        performedAt: now,
      );

      final audit3 = audit1.copyWith(id: 'different_id');

      expect(audit1, equals(audit2));
      expect(audit1, isNot(equals(audit3)));
      expect(audit1.hashCode, equals(audit2.hashCode));
    });
  });
}
