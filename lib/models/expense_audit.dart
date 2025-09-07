import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseAuditAction { created, updated, deleted }

class ExpenseAudit {
  final String id;
  final String expenseId;
  final String groupId;
  final ExpenseAuditAction action;
  final String performedBy;
  final DateTime performedAt;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final String? reason;

  const ExpenseAudit({
    required this.id,
    required this.expenseId,
    required this.groupId,
    required this.action,
    required this.performedBy,
    required this.performedAt,
    this.previousData,
    this.newData,
    this.reason,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseId': expenseId,
      'groupId': groupId,
      'action': action.name,
      'performedBy': performedBy,
      'performedAt': Timestamp.fromDate(performedAt),
      'previousData': previousData,
      'newData': newData,
      'reason': reason,
    };
  }

  factory ExpenseAudit.fromJson(Map<String, dynamic> json) {
    return ExpenseAudit(
      id: json['id'] ?? '',
      expenseId: json['expenseId'] ?? '',
      groupId: json['groupId'] ?? '',
      action: ExpenseAuditAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ExpenseAuditAction.created,
      ),
      performedBy: json['performedBy'] ?? '',
      performedAt:
          (json['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousData: json['previousData'] as Map<String, dynamic>?,
      newData: json['newData'] as Map<String, dynamic>?,
      reason: json['reason'] as String?,
    );
  }

  ExpenseAudit copyWith({
    String? id,
    String? expenseId,
    String? groupId,
    ExpenseAuditAction? action,
    String? performedBy,
    DateTime? performedAt,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
    String? reason,
  }) {
    return ExpenseAudit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      groupId: groupId ?? this.groupId,
      action: action ?? this.action,
      performedBy: performedBy ?? this.performedBy,
      performedAt: performedAt ?? this.performedAt,
      previousData: previousData ?? this.previousData,
      newData: newData ?? this.newData,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseAudit &&
        other.id == id &&
        other.expenseId == expenseId &&
        other.groupId == groupId &&
        other.action == action &&
        other.performedBy == performedBy &&
        other.performedAt == performedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        expenseId.hashCode ^
        groupId.hashCode ^
        action.hashCode ^
        performedBy.hashCode ^
        performedAt.hashCode;
  }
}
