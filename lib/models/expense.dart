import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType { equal, custom, percentage, shares }

enum ExpenseCategory {
  general,
  food,
  transportation,
  utilities,
  entertainment,
  shopping,
  health,
  other;

  static ExpenseCategory fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return ExpenseCategory.general;
    for (final c in ExpenseCategory.values) {
      if (c.name == raw) return c;
    }
    return ExpenseCategory.general;
  }

  String get label {
    switch (this) {
      case ExpenseCategory.general:
        return 'General';
      case ExpenseCategory.food:
        return 'Food & dining';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

class ExpenseSplit {
  final SplitType type;
  final List<String> participants;
  final Map<String, double> shares; // userId -> amount or percentage

  const ExpenseSplit({
    required this.type,
    required this.participants,
    required this.shares,
  });

  // Validation
  bool get isValid {
    if (participants.isEmpty || shares.isEmpty) return false;

    // All participants should have shares
    for (String participant in participants) {
      if (!shares.containsKey(participant)) return false;
      if (shares[participant]! < 0) return false;
    }

    // For percentage splits, total should be 100
    if (type == SplitType.percentage) {
      double total = shares.values.fold(0, (acc, value) => acc + value);
      return (total - 100.0).abs() < 0.01; // Allow small floating point errors
    }

    if (type == SplitType.shares) {
      for (final participant in participants) {
        final w = shares[participant] ?? 0;
        if (w <= 0) return false;
      }
      return true;
    }

    return true;
  }

  // Calculate actual amounts for each participant
  Map<String, double> calculateAmounts(double totalAmount) {
    Map<String, double> amounts = {};

    switch (type) {
      case SplitType.equal:
        double amountPerPerson = totalAmount / participants.length;
        for (String participant in participants) {
          amounts[participant] = amountPerPerson;
        }
        break;
      case SplitType.custom:
        amounts = Map.from(shares);
        break;
      case SplitType.percentage:
        for (String participant in participants) {
          amounts[participant] = totalAmount * (shares[participant]! / 100.0);
        }
        break;
      case SplitType.shares:
        final totalWeight = participants.fold<double>(
          0,
          (sum, p) => sum + (shares[p] ?? 0),
        );
        if (totalWeight <= 0) break;
        for (final participant in participants) {
          amounts[participant] =
              totalAmount * ((shares[participant] ?? 0) / totalWeight);
        }
        break;
    }

    return amounts;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {'type': type.name, 'participants': participants, 'shares': shares};
  }

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      type: SplitType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SplitType.equal,
      ),
      participants: List<String>.from(json['participants'] ?? []),
      shares: Map<String, double>.from(
        (json['shares'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
    );
  }

  ExpenseSplit copyWith({
    SplitType? type,
    List<String>? participants,
    Map<String, double>? shares,
  }) {
    return ExpenseSplit(
      type: type ?? this.type,
      participants: participants ?? this.participants,
      shares: shares ?? this.shares,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseSplit &&
        other.type == type &&
        _listEquals(other.participants, participants) &&
        _mapEquals(other.shares, shares);
  }

  @override
  int get hashCode {
    return Object.hash(type, participants, shares);
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (K key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final ExpenseSplit split;
  final String createdBy;
  final DateTime createdAt;
  final String? note;
  final ExpenseCategory category;
  final String? receiptUrl;

  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.split,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.category = ExpenseCategory.general,
    this.receiptUrl,
  });

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        groupId.isNotEmpty &&
        description.trim().isNotEmpty &&
        amount > 0 &&
        paidBy.isNotEmpty &&
        createdBy.isNotEmpty &&
        split.isValid &&
        split.participants.contains(paidBy);
  }

  // Get the amount each participant owes
  Map<String, double> get participantAmounts {
    return split.calculateAmounts(amount);
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'date': Timestamp.fromDate(date),
      'split': split.toJson(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (note != null && note!.isNotEmpty) 'note': note,
      'category': category.name,
      if (receiptUrl != null && receiptUrl!.isNotEmpty) 'receiptUrl': receiptUrl,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paidBy: json['paidBy'] ?? '',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      split: ExpenseSplit.fromJson(json['split'] ?? {}),
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: json['note'] as String?,
      category: ExpenseCategory.fromStorage(json['category'] as String?),
      receiptUrl: json['receiptUrl'] as String?,
    );
  }

  Expense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? paidBy,
    DateTime? date,
    ExpenseSplit? split,
    String? createdBy,
    DateTime? createdAt,
    String? note,
    ExpenseCategory? category,
    String? receiptUrl,
    bool clearNote = false,
    bool clearReceiptUrl = false,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      split: split ?? this.split,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      note: clearNote ? null : (note ?? this.note),
      category: category ?? this.category,
      receiptUrl:
          clearReceiptUrl ? null : (receiptUrl ?? this.receiptUrl),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.groupId == groupId &&
        other.description == description &&
        other.amount == amount &&
        other.paidBy == paidBy &&
        other.date == date &&
        other.split == split &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.note == note &&
        other.category == category &&
        other.receiptUrl == receiptUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      description,
      amount,
      paidBy,
      date,
      split,
      createdBy,
      createdAt,
      note,
      category,
      receiptUrl,
    );
  }
}
