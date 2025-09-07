import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for different types of notifications
enum NotificationType {
  settlementReceived,
  settlementSent,
  expenseAdded,
  groupInvitation,
}

/// Base notification class
abstract class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.readAt,
  });

  Map<String, dynamic> toJson();

  bool get isValid {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        title.isNotEmpty &&
        message.isNotEmpty;
  }
}

/// Group invitation notification
class GroupInvitationNotification extends AppNotification {
  final String groupId;
  final String groupName;
  final String invitedBy;

  const GroupInvitationNotification({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    required super.createdAt,
    required super.isRead,
    super.readAt,
    required this.groupId,
    required this.groupName,
    required this.invitedBy,
  });

  @override
  bool get isValid {
    return super.isValid &&
        groupId.isNotEmpty &&
        groupName.isNotEmpty &&
        invitedBy.isNotEmpty;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'groupId': groupId,
      'groupName': groupName,
      'invitedBy': invitedBy,
    };
  }

  factory GroupInvitationNotification.fromJson(Map<String, dynamic> json) {
    return GroupInvitationNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.groupInvitation,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      readAt: (json['readAt'] as Timestamp?)?.toDate(),
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      invitedBy: json['invitedBy'] ?? '',
    );
  }

  GroupInvitationNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? groupId,
    String? groupName,
    String? invitedBy,
  }) {
    return GroupInvitationNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupInvitationNotification &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.isRead == isRead &&
        other.readAt == readAt &&
        other.groupId == groupId &&
        other.groupName == groupName &&
        other.invitedBy == invitedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        createdAt.hashCode ^
        isRead.hashCode ^
        readAt.hashCode ^
        groupId.hashCode ^
        groupName.hashCode ^
        invitedBy.hashCode;
  }
}

/// Settlement-specific notification
class SettlementNotification extends AppNotification {
  final String settlementId;
  final String groupId;
  final String fromUserId;
  final double amount;

  const SettlementNotification({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    required super.createdAt,
    required super.isRead,
    super.readAt,
    required this.settlementId,
    required this.groupId,
    required this.fromUserId,
    required this.amount,
  });

  @override
  bool get isValid {
    return super.isValid &&
        settlementId.isNotEmpty &&
        groupId.isNotEmpty &&
        fromUserId.isNotEmpty &&
        amount > 0;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'settlementId': settlementId,
      'groupId': groupId,
      'fromUserId': fromUserId,
      'amount': amount,
    };
  }

  factory SettlementNotification.fromJson(Map<String, dynamic> json) {
    return SettlementNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.settlementReceived,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      readAt: (json['readAt'] as Timestamp?)?.toDate(),
      settlementId: json['settlementId'] ?? '',
      groupId: json['groupId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  SettlementNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Object? readAt = _sentinel,
    String? settlementId,
    String? groupId,
    String? fromUserId,
    double? amount,
  }) {
    return SettlementNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt == _sentinel ? this.readAt : readAt as DateTime?,
      settlementId: settlementId ?? this.settlementId,
      groupId: groupId ?? this.groupId,
      fromUserId: fromUserId ?? this.fromUserId,
      amount: amount ?? this.amount,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettlementNotification &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.isRead == isRead &&
        other.readAt == readAt &&
        other.settlementId == settlementId &&
        other.groupId == groupId &&
        other.fromUserId == fromUserId &&
        other.amount == amount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        createdAt.hashCode ^
        isRead.hashCode ^
        readAt.hashCode ^
        settlementId.hashCode ^
        groupId.hashCode ^
        fromUserId.hashCode ^
        amount.hashCode;
  }
}
