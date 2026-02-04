// test/multi_year_devotionals_test.dart

import 'package:devocional_nuevo/constants/devocional_years.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'utils'])
void main() {
  group('Multi-Year Devotionals Logic Tests', () {
    test('Devotionals from different years can be merged and sorted', () {
      // Create sample devotionals from 2025
      final dev2025_1 = Devocional(
        id: 'dev_2025_01_01',
        versiculo: 'John 3:16',
        reflexion: 'Reflection 2025-01',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime(2025, 1, 1),
        version: 'RVR1960',
        language: 'es',
      );

      final dev2025_2 = Devocional(
        id: 'dev_2025_12_31',
        versiculo: 'Psalm 23:1',
        reflexion: 'Reflection 2025-12',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime(2025, 12, 31),
        version: 'RVR1960',
        language: 'es',
      );

      // Create sample devotionals from 2026
      final dev2026_1 = Devocional(
        id: 'dev_2026_01_01',
        versiculo: 'Matthew 5:16',
        reflexion: 'Reflection 2026-01',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime(2026, 1, 1),
        version: 'RVR1960',
        language: 'es',
      );

      final dev2026_2 = Devocional(
        id: 'dev_2026_01_02',
        versiculo: 'Romans 8:28',
        reflexion: 'Reflection 2026-02',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime(2026, 1, 2),
        version: 'RVR1960',
        language: 'es',
      );

      // Merge devotionals from both years (simulating the fix)
      final allDevocionales = <Devocional>[
        dev2025_1,
        dev2025_2,
        dev2026_1,
        dev2026_2,
      ];

      // Sort by date
      allDevocionales.sort((a, b) => a.date.compareTo(b.date));

      // Verify sorting is correct
      expect(allDevocionales[0].id, 'dev_2025_01_01');
      expect(allDevocionales[1].id, 'dev_2025_12_31');
      expect(allDevocionales[2].id, 'dev_2026_01_01');
      expect(allDevocionales[3].id, 'dev_2026_01_02');

      // Verify both years are present
      final years = allDevocionales.map((d) => d.date.year).toSet();
      expect(years.contains(2025), true);
      expect(years.contains(2026), true);
    });

    test('Devotional IDs should be unique across years', () {
      final devocionales = <Devocional>[
        Devocional(
          id: 'dev_2025_01_01',
          versiculo: 'John 3:16',
          reflexion: 'Reflection',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2025, 1, 1),
          version: 'RVR1960',
          language: 'es',
        ),
        Devocional(
          id: 'dev_2026_01_01',
          versiculo: 'John 3:16',
          reflexion: 'Reflection',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2026, 1, 1),
          version: 'RVR1960',
          language: 'es',
        ),
      ];

      final ids = devocionales.map((d) => d.id).toList();
      final uniqueIds = ids.toSet();

      expect(ids.length, uniqueIds.length,
          reason: 'All devotional IDs should be unique');
    });

    test('Read devotionals filtering works across years', () {
      final allDevocionales = <Devocional>[
        Devocional(
          id: 'dev_2025_01_01',
          versiculo: 'John 3:16',
          reflexion: 'Reflection',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2025, 1, 1),
          version: 'RVR1960',
          language: 'es',
        ),
        Devocional(
          id: 'dev_2025_01_02',
          versiculo: 'Psalm 23:1',
          reflexion: 'Reflection',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2025, 1, 2),
          version: 'RVR1960',
          language: 'es',
        ),
        Devocional(
          id: 'dev_2026_01_01',
          versiculo: 'Matthew 5:16',
          reflexion: 'Reflection',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2026, 1, 1),
          version: 'RVR1960',
          language: 'es',
        ),
      ];

      // Simulate read devotionals from 2026
      final readIds = {'dev_2026_01_01'};

      // Filter unread devotionals
      final unread =
          allDevocionales.where((d) => !readIds.contains(d.id)).toList();

      // Verify that 2025 devotionals are still accessible
      expect(unread.length, 2);
      expect(unread.any((d) => d.date.year == 2025), true);
      expect(unread.any((d) => d.id == 'dev_2026_01_01'), false);
    });

    test('Years are loaded from constant list (no progressive data loss)', () {
      // This test verifies the logic of loading years from constant list
      final yearsToLoad = DevocionalYears.availableYears;

      expect(yearsToLoad.length, greaterThanOrEqualTo(2),
          reason: 'At least 2025 and 2026 should be available');
      expect(yearsToLoad.contains(2025), true,
          reason: '2025 should always be available');
      expect(yearsToLoad.contains(2026), true,
          reason: '2026 should always be available');

      // Verify years are in ascending order
      for (int i = 0; i < yearsToLoad.length - 1; i++) {
        expect(yearsToLoad[i] < yearsToLoad[i + 1], true,
            reason: 'Years should be in ascending order');
      }
    });
  });
}
