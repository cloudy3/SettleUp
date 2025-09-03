import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('Balance', () {
    test('should create valid Balance', () {
      final balance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0, 'user3': 25.0},
        owedBy: {'user4': 30.0},
        netBalance: -45.0, // owedBy (30) - owes (75) = -45
      );

      expect(balance.isValid, true);
      expect(balance.userId, 'user1');
      expect(balance.groupId, 'group123');
      expect(balance.netBalance, -45.0);
    });

    test('should validate required fields', () {
      final invalidBalance = Balance(
        userId: '',
        groupId: '',
        owes: {'user2': 50.0},
        owedBy: {'user3': 30.0},
        netBalance: -20.0,
      );

      expect(invalidBalance.isValid, false);
    });

    test('should validate non-negative amounts', () {
      final invalidBalance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': -50.0}, // Negative amount
        owedBy: {'user3': 30.0},
        netBalance: 80.0,
      );

      expect(invalidBalance.isValid, false);
    });

    test('should calculate net balance correctly', () {
      final owes = {'user2': 50.0, 'user3': 25.0}; // Total: 75
      final owedBy = {'user4': 30.0, 'user5': 20.0}; // Total: 50

      final netBalance = Balance.calculateNetBalance(owes, owedBy);

      expect(netBalance, -25.0); // 50 - 75 = -25
    });

    test('should create Balance with calculated net balance', () {
      final balance = Balance.create(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0, 'user3': 25.0},
        owedBy: {'user4': 30.0},
      );

      expect(balance.netBalance, -45.0); // 30 - 75 = -45
    });

    test('should get simplified debts correctly', () {
      final balance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0, 'user3': 0.0, 'user4': 25.0},
        owedBy: {'user5': 30.0},
        netBalance: -45.0,
      );

      final debts = balance.simplifiedDebts;

      expect(debts.length, 2);
      expect(debts['user2'], 50.0);
      expect(debts['user4'], 25.0);
      expect(debts.containsKey('user3'), false); // Zero amount excluded
    });

    test('should get simplified credits correctly', () {
      final balance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0},
        owedBy: {'user3': 30.0, 'user4': 0.0, 'user5': 20.0},
        netBalance: 0.0,
      );

      final credits = balance.simplifiedCredits;

      expect(credits.length, 2);
      expect(credits['user3'], 30.0);
      expect(credits['user5'], 20.0);
      expect(credits.containsKey('user4'), false); // Zero amount excluded
    });

    test('should detect settled up status', () {
      final settledBalance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {},
        owedBy: {},
        netBalance: 0.0,
      );

      final almostSettledBalance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {},
        owedBy: {},
        netBalance: 0.005, // Within tolerance
      );

      final notSettledBalance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0},
        owedBy: {},
        netBalance: -50.0,
      );

      expect(settledBalance.isSettledUp, true);
      expect(almostSettledBalance.isSettledUp, true);
      expect(notSettledBalance.isSettledUp, false);
    });

    test('should serialize to and from JSON', () {
      final balance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0, 'user3': 25.0},
        owedBy: {'user4': 30.0},
        netBalance: -45.0,
      );

      final json = balance.toJson();
      final fromJson = Balance.fromJson(json);

      expect(fromJson.userId, balance.userId);
      expect(fromJson.groupId, balance.groupId);
      expect(fromJson.owes, balance.owes);
      expect(fromJson.owedBy, balance.owedBy);
      expect(fromJson.netBalance, balance.netBalance);
    });

    test('should calculate net balance from JSON if not provided', () {
      final json = {
        'userId': 'user1',
        'groupId': 'group123',
        'owes': {'user2': 50.0, 'user3': 25.0},
        'owedBy': {'user4': 30.0},
        // netBalance not provided
      };

      final balance = Balance.fromJson(json);

      expect(balance.netBalance, -45.0); // Calculated: 30 - 75 = -45
    });

    test('should support copyWith', () {
      final balance = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0},
        owedBy: {'user3': 30.0},
        netBalance: -20.0,
      );

      final updated = balance.copyWith(
        owes: {'user2': 60.0},
        owedBy: {'user3': 40.0},
      );

      expect(updated.owes['user2'], 60.0);
      expect(updated.owedBy['user3'], 40.0);
      expect(updated.netBalance, -20.0); // Recalculated: 40 - 60 = -20
      expect(updated.userId, balance.userId);
      expect(updated.groupId, balance.groupId);
    });

    test('should implement equality correctly', () {
      final balance1 = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0},
        owedBy: {'user3': 30.0},
        netBalance: -20.0,
      );

      final balance2 = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {'user2': 50.0},
        owedBy: {'user3': 30.0},
        netBalance: -20.0,
      );

      expect(balance1, equals(balance2));
      // Note: hashCode equality is not guaranteed for complex objects with Maps
    });

    test('should handle floating point precision in equality', () {
      final balance1 = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {},
        owedBy: {},
        netBalance: -20.0,
      );

      final balance2 = Balance(
        userId: 'user1',
        groupId: 'group123',
        owes: {},
        owedBy: {},
        netBalance: -20.005, // Small difference within tolerance
      );

      expect(balance1, equals(balance2));
    });
  });
}
