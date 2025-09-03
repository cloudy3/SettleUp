import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/models.dart';

void main() {
  group('Settlement', () {
    test('should create valid Settlement', () {
      final settlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: DateTime.now(),
        note: 'Dinner payment',
      );

      expect(settlement.isValid, true);
      expect(settlement.id, 'settlement123');
      expect(settlement.groupId, 'group123');
      expect(settlement.fromUserId, 'user1');
      expect(settlement.toUserId, 'user2');
      expect(settlement.amount, 50.0);
      expect(settlement.note, 'Dinner payment');
    });

    test('should create valid Settlement without note', () {
      final settlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: DateTime.now(),
      );

      expect(settlement.isValid, true);
      expect(settlement.note, null);
    });

    test('should validate required fields', () {
      final invalidSettlement = Settlement(
        id: '',
        groupId: '',
        fromUserId: '',
        toUserId: '',
        amount: 50.0,
        settledAt: DateTime.now(),
      );

      expect(invalidSettlement.isValid, false);
    });

    test('should validate different from and to users', () {
      final invalidSettlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user1', // Same as fromUserId
        amount: 50.0,
        settledAt: DateTime.now(),
      );

      expect(invalidSettlement.isValid, false);
    });

    test('should validate positive amount', () {
      final invalidSettlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 0.0, // Zero amount
        settledAt: DateTime.now(),
      );

      expect(invalidSettlement.isValid, false);

      final negativeSettlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: -50.0, // Negative amount
        settledAt: DateTime.now(),
      );

      expect(negativeSettlement.isValid, false);
    });

    test('should serialize to and from JSON', () {
      final settlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: DateTime(2025, 1, 16, 9, 0),
        note: 'Hotel payment settled',
      );

      final json = settlement.toJson();
      final fromJson = Settlement.fromJson(json);

      expect(fromJson.id, settlement.id);
      expect(fromJson.groupId, settlement.groupId);
      expect(fromJson.fromUserId, settlement.fromUserId);
      expect(fromJson.toUserId, settlement.toUserId);
      expect(fromJson.amount, settlement.amount);
      expect(fromJson.note, settlement.note);
      // Note: Timestamp conversion may have slight differences, so we check date components
      expect(fromJson.settledAt.year, settlement.settledAt.year);
      expect(fromJson.settledAt.month, settlement.settledAt.month);
      expect(fromJson.settledAt.day, settlement.settledAt.day);
    });

    test('should serialize to and from JSON without note', () {
      final settlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: DateTime(2025, 1, 16, 9, 0),
      );

      final json = settlement.toJson();
      final fromJson = Settlement.fromJson(json);

      expect(fromJson.id, settlement.id);
      expect(fromJson.note, null);
    });

    test('should support copyWith', () {
      final settlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: DateTime.now(),
        note: 'Original note',
      );

      final updated = settlement.copyWith(amount: 75.0, note: 'Updated note');

      expect(updated.amount, 75.0);
      expect(updated.note, 'Updated note');
      expect(updated.id, settlement.id);
      expect(updated.fromUserId, settlement.fromUserId);
      expect(updated.toUserId, settlement.toUserId);
    });

    test('should support copyWith with null note', () {
      final settlement = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: DateTime.now(),
        note: 'Original note',
      );

      final updated = settlement.copyWith(note: null);

      expect(updated.note, null);
      expect(updated.amount, settlement.amount);
    });

    test('should implement equality correctly', () {
      final date = DateTime.now();
      final settlement1 = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: date,
        note: 'Test note',
      );

      final settlement2 = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: date,
        note: 'Test note',
      );

      expect(settlement1, equals(settlement2));
      expect(settlement1.hashCode, equals(settlement2.hashCode));
    });

    test('should implement equality correctly with null notes', () {
      final date = DateTime.now();
      final settlement1 = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: date,
      );

      final settlement2 = Settlement(
        id: 'settlement123',
        groupId: 'group123',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 50.0,
        settledAt: date,
      );

      expect(settlement1, equals(settlement2));
      expect(settlement1.hashCode, equals(settlement2.hashCode));
    });
  });
}
