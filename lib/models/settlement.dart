import 'package:cloud_firestore/cloud_firestore.dart';

class Settlement {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime settledAt;
  final String? note;

  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.settledAt,
    this.note,
  });

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        groupId.isNotEmpty &&
        fromUserId.isNotEmpty &&
        toUserId.isNotEmpty &&
        fromUserId != toUserId &&
        amount > 0;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'settledAt': Timestamp.fromDate(settledAt),
      'note': note,
    };
  }

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      settledAt: (json['settledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: json['note'],
    );
  }

  Settlement copyWith({
    String? id,
    String? groupId,
    String? fromUserId,
    String? toUserId,
    double? amount,
    DateTime? settledAt,
    Object? note = _sentinel,
  }) {
    return Settlement(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      settledAt: settledAt ?? this.settledAt,
      note: note == _sentinel ? this.note : note as String?,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settlement &&
        other.id == id &&
        other.groupId == groupId &&
        other.fromUserId == fromUserId &&
        other.toUserId == toUserId &&
        other.amount == amount &&
        other.settledAt == settledAt &&
        other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        groupId.hashCode ^
        fromUserId.hashCode ^
        toUserId.hashCode ^
        amount.hashCode ^
        settledAt.hashCode ^
        note.hashCode;
  }
}
