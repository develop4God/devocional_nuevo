// test/prayer_functionality_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/providers/prayer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Prayer Model Tests', () {
    test('should create prayer with all required fields', () {
      final prayer = Prayer(
        id: '1',
        text: 'Señor, ayúdame en este día',
        createdDate: DateTime(2024, 1, 1),
        status: PrayerStatus.active,
      );

      expect(prayer.id, equals('1'));
      expect(prayer.text, equals('Señor, ayúdame en este día'));
      expect(prayer.isActive, isTrue);
      expect(prayer.isAnswered, isFalse);
    });

    test('should calculate days old correctly', () {
      final prayer = Prayer(
        id: '1',
        text: 'Test prayer',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        status: PrayerStatus.active,
      );

      expect(prayer.daysOld, equals(5));
    });

    test('should serialize and deserialize correctly', () {
      final originalPrayer = Prayer(
        id: '1',
        text: 'Test prayer for JSON',
        createdDate: DateTime(2024, 1, 1),
        status: PrayerStatus.active,
      );

      final json = originalPrayer.toJson();
      final deserializedPrayer = Prayer.fromJson(json);

      expect(deserializedPrayer.id, equals(originalPrayer.id));
      expect(deserializedPrayer.text, equals(originalPrayer.text));
      expect(deserializedPrayer.status, equals(originalPrayer.status));
      expect(
          deserializedPrayer.createdDate, equals(originalPrayer.createdDate));
    });

    test('should copy with different values', () {
      final originalPrayer = Prayer(
        id: '1',
        text: 'Original text',
        createdDate: DateTime(2024, 1, 1),
        status: PrayerStatus.active,
      );

      final copiedPrayer = originalPrayer.copyWith(
        status: PrayerStatus.answered,
        answeredDate: DateTime(2024, 1, 2),
      );

      expect(copiedPrayer.id, equals(originalPrayer.id));
      expect(copiedPrayer.text, equals(originalPrayer.text));
      expect(copiedPrayer.status, equals(PrayerStatus.answered));
      expect(copiedPrayer.answeredDate, isNotNull);
    });
  });

  group('PrayerStatus Tests', () {
    test('should convert from string correctly', () {
      expect(PrayerStatus.fromString('active'), equals(PrayerStatus.active));
      expect(
          PrayerStatus.fromString('answered'), equals(PrayerStatus.answered));
      expect(PrayerStatus.fromString('invalid'),
          equals(PrayerStatus.active)); // Default fallback
    });

    test('should convert to string correctly', () {
      expect(PrayerStatus.active.toString(), equals('active'));
      expect(PrayerStatus.answered.toString(), equals('answered'));
    });

    test('should have correct display names', () {
      expect(PrayerStatus.active.displayName, equals('Activa'));
      expect(PrayerStatus.answered.displayName, equals('Respondida'));
    });
  });

  group('PrayerProvider Tests', () {
    late PrayerProvider prayerProvider;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      prayerProvider = PrayerProvider();

      // Wait a bit for initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('should start with empty prayers list', () {
      expect(prayerProvider.prayers, isEmpty);
      expect(prayerProvider.activePrayers, isEmpty);
      expect(prayerProvider.answeredPrayers, isEmpty);
      expect(prayerProvider.totalPrayers, equals(0));
    });

    test('should add prayer correctly', () async {
      expect(prayerProvider.prayers, isEmpty);

      await prayerProvider.addPrayer('Test prayer');

      expect(prayerProvider.prayers, hasLength(1));
      expect(prayerProvider.activePrayers, hasLength(1));
      expect(prayerProvider.answeredPrayers, isEmpty);
      expect(prayerProvider.prayers.first.text, equals('Test prayer'));
      expect(prayerProvider.prayers.first.isActive, isTrue);
    });

    test('should not add empty prayer', () async {
      await prayerProvider.addPrayer('   '); // Only whitespace

      expect(prayerProvider.prayers, isEmpty);
      expect(prayerProvider.errorMessage, isNotNull);
    });

    test('should mark prayer as answered', () async {
      await prayerProvider.addPrayer('Test prayer');
      final prayerId = prayerProvider.prayers.first.id;

      await prayerProvider.markPrayerAsAnswered(prayerId);

      expect(prayerProvider.activePrayers, isEmpty);
      expect(prayerProvider.answeredPrayers, hasLength(1));
      expect(prayerProvider.prayers.first.isAnswered, isTrue);
      expect(prayerProvider.prayers.first.answeredDate, isNotNull);
    });

    test('should mark prayer as active again', () async {
      await prayerProvider.addPrayer('Test prayer');
      final prayerId = prayerProvider.prayers.first.id;

      await prayerProvider.markPrayerAsAnswered(prayerId);
      await prayerProvider.markPrayerAsActive(prayerId);

      expect(prayerProvider.activePrayers, hasLength(1));
      expect(prayerProvider.answeredPrayers, isEmpty);
      expect(prayerProvider.prayers.first.isActive, isTrue);
      expect(prayerProvider.prayers.first.answeredDate, isNull);
    });

    test('should edit prayer text', () async {
      await prayerProvider.addPrayer('Original text');
      final prayerId = prayerProvider.prayers.first.id;

      await prayerProvider.editPrayer(prayerId, 'Edited text');

      expect(prayerProvider.prayers.first.text, equals('Edited text'));
    });

    test('should delete prayer', () async {
      await prayerProvider.addPrayer('Prayer to delete');
      final prayerId = prayerProvider.prayers.first.id;

      await prayerProvider.deletePrayer(prayerId);

      expect(prayerProvider.prayers, isEmpty);
    });

    test('should get correct stats', () async {
      await prayerProvider.addPrayer('Active prayer 1');
      await prayerProvider.addPrayer('Active prayer 2');
      final prayerId = prayerProvider.prayers.first.id;
      await prayerProvider.markPrayerAsAnswered(prayerId);

      final stats = prayerProvider.getStats();

      expect(stats['total'], equals(2));
      expect(stats['active'], equals(1));
      expect(stats['answered'], equals(1));
    });
  });
}
