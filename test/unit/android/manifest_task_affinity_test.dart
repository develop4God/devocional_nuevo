@Tags(['critical', 'unit', 'utils'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Returns the opening tag of the `.MainActivity` element in [manifest].
String mainActivityTag(String manifest) {
  final match = RegExp(
    '''<activity\\b[^>]*android:name=["']\\.MainActivity["'][^>]*>''',
  ).firstMatch(manifest);
  if (match == null) fail('MainActivity declaration not found in manifest');
  return match.group(0)!;
}

/// True when [tag] declares any android:taskAffinity (empty, blank or custom).
bool declaresTaskAffinity(String tag) =>
    RegExp(r'android:taskAffinity\s*=').hasMatch(tag);

void main() {
  group('declaresTaskAffinity helper', () {
    test('detects empty, blank, single-quoted and custom values', () {
      for (final value in ['""', '" "', "''", '"a.b"']) {
        expect(
          declaresTaskAffinity(
            '<activity android:name=".MainActivity" '
            'android:taskAffinity=$value>',
          ),
          isTrue,
          reason: 'value $value must be detected',
        );
      }
    });

    test('ignores a tag without taskAffinity', () {
      expect(
        declaresTaskAffinity('<activity android:name=".MainActivity">'),
        isFalse,
      );
    });
  });

  group('AndroidManifest', () {
    late String manifest;

    setUpAll(() {
      manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
    });

    test('MainActivity keeps the default task affinity (Play relaunch)', () {
      expect(declaresTaskAffinity(mainActivityTag(manifest)), isFalse);
    });

    test('MainActivity keeps launchMode singleTop', () {
      expect(
        mainActivityTag(manifest),
        contains('android:launchMode="singleTop"'),
      );
    });
  });
}
