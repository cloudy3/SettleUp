class Balance {
  final String userId;
  final String groupId;
  final Map<String, double> owes; // userId -> amount owed to them
  final Map<String, double> owedBy; // userId -> amount they owe you
  final double netBalance;

  const Balance({
    required this.userId,
    required this.groupId,
    required this.owes,
    required this.owedBy,
    required this.netBalance,
  });

  // Validation
  bool get isValid {
    return userId.isNotEmpty &&
        groupId.isNotEmpty &&
        owes.values.every((amount) => amount >= 0) &&
        owedBy.values.every((amount) => amount >= 0);
  }

  // Calculate net balance from owes and owedBy maps
  static double calculateNetBalance(
    Map<String, double> owes,
    Map<String, double> owedBy,
  ) {
    double totalOwed = owedBy.values.fold(0, (sum, amount) => sum + amount);
    double totalOwing = owes.values.fold(0, (sum, amount) => sum + amount);
    return totalOwed - totalOwing;
  }

  // Get simplified debt relationships (who owes whom)
  Map<String, double> get simplifiedDebts {
    Map<String, double> debts = {};

    // Add amounts this user owes to others
    owes.forEach((otherUserId, amount) {
      if (amount > 0) {
        debts[otherUserId] = amount;
      }
    });

    return debts;
  }

  // Get simplified credit relationships (who owes this user)
  Map<String, double> get simplifiedCredits {
    Map<String, double> credits = {};

    // Add amounts others owe to this user
    owedBy.forEach((otherUserId, amount) {
      if (amount > 0) {
        credits[otherUserId] = amount;
      }
    });

    return credits;
  }

  // Check if user is settled up (no debts or credits)
  bool get isSettledUp {
    return netBalance.abs() < 0.01; // Allow for small floating point errors
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'groupId': groupId,
      'owes': owes,
      'owedBy': owedBy,
      'netBalance': netBalance,
    };
  }

  factory Balance.fromJson(Map<String, dynamic> json) {
    Map<String, double> owes = Map<String, double>.from(
      (json['owes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
    );

    Map<String, double> owedBy = Map<String, double>.from(
      (json['owedBy'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
    );

    return Balance(
      userId: json['userId'] ?? '',
      groupId: json['groupId'] ?? '',
      owes: owes,
      owedBy: owedBy,
      netBalance: (json['netBalance'] ?? calculateNetBalance(owes, owedBy))
          .toDouble(),
    );
  }

  // Create a new Balance with calculated net balance
  factory Balance.create({
    required String userId,
    required String groupId,
    required Map<String, double> owes,
    required Map<String, double> owedBy,
  }) {
    return Balance(
      userId: userId,
      groupId: groupId,
      owes: owes,
      owedBy: owedBy,
      netBalance: calculateNetBalance(owes, owedBy),
    );
  }

  Balance copyWith({
    String? userId,
    String? groupId,
    Map<String, double>? owes,
    Map<String, double>? owedBy,
    double? netBalance,
  }) {
    Map<String, double> newOwes = owes ?? this.owes;
    Map<String, double> newOwedBy = owedBy ?? this.owedBy;

    return Balance(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      owes: newOwes,
      owedBy: newOwedBy,
      netBalance: netBalance ?? calculateNetBalance(newOwes, newOwedBy),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Balance &&
        other.userId == userId &&
        other.groupId == groupId &&
        _mapEquals(other.owes, owes) &&
        _mapEquals(other.owedBy, owedBy) &&
        (other.netBalance - netBalance).abs() < 0.01;
  }

  @override
  int get hashCode {
    return Object.hash(userId, groupId, owes, owedBy, netBalance);
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (K key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
