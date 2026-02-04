// test/unit/blocs/prayer_bloc_update_answered_comment_test.dart

import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'blocs'])
void main() {
  group('PrayerBloc - UpdateAnsweredComment Event', () {
    test('UpdateAnsweredComment event should exist and be callable', () {
      // Arrange & Act
      final event = UpdateAnsweredComment('test-id', comment: 'Test comment');

      // Assert
      expect(event, isA<PrayerEvent>());
      expect(event.prayerId, equals('test-id'));
      expect(event.comment, equals('Test comment'));
    });

    test('UpdateAnsweredComment with null comment should work', () {
      // Arrange & Act
      final event = UpdateAnsweredComment('test-id', comment: null);

      // Assert
      expect(event, isA<PrayerEvent>());
      expect(event.prayerId, equals('test-id'));
      expect(event.comment, isNull);
    });

    test('UpdateAnsweredComment with empty comment should work', () {
      // Arrange & Act
      final event = UpdateAnsweredComment('test-id', comment: '');

      // Assert
      expect(event, isA<PrayerEvent>());
      expect(event.prayerId, equals('test-id'));
      expect(event.comment, equals(''));
    });
  });
}
