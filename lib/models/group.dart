import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, declined }

class GroupInvitation {
  final String email;
  final String invitedBy;
  final DateTime invitedAt;
  final InvitationStatus status;

  const GroupInvitation({
    required this.email,
    required this.invitedBy,
    required this.invitedAt,
    required this.status,
  });

  // Validation
  bool get isValid {
    return email.isNotEmpty && email.contains('@') && invitedBy.isNotEmpty;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'invitedBy': invitedBy,
      'invitedAt': Timestamp.fromDate(invitedAt),
      'status': status.name,
    };
  }

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      email: json['email'] ?? '',
      invitedBy: json['invitedBy'] ?? '',
      invitedAt: (json['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
    );
  }

  GroupInvitation copyWith({
    String? email,
    String? invitedBy,
    DateTime? invitedAt,
    InvitationStatus? status,
  }) {
    return GroupInvitation(
      email: email ?? this.email,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedAt: invitedAt ?? this.invitedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupInvitation &&
        other.email == email &&
        other.invitedBy == invitedBy &&
        other.invitedAt == invitedAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        invitedBy.hashCode ^
        invitedAt.hashCode ^
        status.hashCode;
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> memberIds;
  final List<GroupInvitation> pendingInvitations;
  final double totalExpenses;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
    required this.pendingInvitations,
    required this.totalExpenses,
  });

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        name.trim().isNotEmpty &&
        createdBy.isNotEmpty &&
        memberIds.isNotEmpty &&
        memberIds.contains(createdBy) &&
        totalExpenses >= 0 &&
        pendingInvitations.every((invitation) => invitation.isValid);
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberIds': memberIds,
      'pendingInvitations': pendingInvitations
          .map((inv) => inv.toJson())
          .toList(),
      'totalExpenses': totalExpenses,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      pendingInvitations:
          (json['pendingInvitations'] as List<dynamic>?)
              ?.map(
                (inv) => GroupInvitation.fromJson(inv as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
    );
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? memberIds,
    List<GroupInvitation>? pendingInvitations,
    double? totalExpenses,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        _listEquals(other.memberIds, memberIds) &&
        _listEquals(other.pendingInvitations, pendingInvitations) &&
        other.totalExpenses == totalExpenses;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      createdBy,
      createdAt,
      memberIds,
      pendingInvitations,
      totalExpenses,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
