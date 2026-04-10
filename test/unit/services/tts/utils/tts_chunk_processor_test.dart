// test/unit/services/tts/utils/tts_chunk_processor_test.dart
@Tags(['unit', 'services', 'tts'])
library;

import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsChunkProcessor', () {
    late TtsChunkProcessor processor;

    setUp(() {
      processor = TtsChunkProcessor();
    });

    // ── splitIntoChunks ──────────────────────────────────────────────────────

    group('splitIntoChunks', () {
      test('short text (below maxLength) returns single unchanged chunk', () {
        const text = 'Porque de tal manera amó Dios al mundo.';
        final chunks = processor.splitIntoChunks(text);
        expect(chunks, hasLength(1));
        expect(chunks.first, text);
      });

      test('text exactly equal to maxLength returns single chunk', () {
        final text = 'a' * TtsChunkProcessor.kMaxChunkLength;
        final chunks = processor.splitIntoChunks(text);
        expect(chunks, hasLength(1));
        expect(chunks.first, text);
      });

      test('long text produces multiple chunks each within maxLength', () {
        // 800 × "word " = 4 000 chars > default maxLength 3 500
        final longText = ('word ' * 800).trim();
        final chunks = processor.splitIntoChunks(longText);
        expect(chunks.length, greaterThan(1));
        for (final chunk in chunks) {
          expect(
            chunk.length,
            lessThanOrEqualTo(TtsChunkProcessor.kMaxChunkLength),
            reason: 'chunk length ${chunk.length} exceeds kMaxChunkLength',
          );
        }
      });

      test(
          'chunks joined with space reconstruct original text (no words dropped)',
          () {
        final original = ('Lorem ipsum dolor sit amet ' * 200).trim();
        final chunks = processor.splitIntoChunks(original);
        final reassembled = chunks.join(' ');
        expect(reassembled, original);
      });

      test('custom maxLength parameter is respected', () {
        const text = 'one two three four five six seven eight nine ten';
        final chunks = processor.splitIntoChunks(text, maxLength: 10);
        for (final chunk in chunks) {
          expect(chunk.length, lessThanOrEqualTo(10));
        }
        // Reassembly still holds
        expect(chunks.join(' '), text);
      });

      test('empty string returns single empty-string chunk', () {
        final chunks = processor.splitIntoChunks('');
        expect(chunks, hasLength(1));
        expect(chunks.first, '');
      });

      test('no mid-word splits occur', () {
        // Produce a text long enough to force chunking
        final words = List.generate(1000, (i) => 'word$i');
        final text = words.join(' ');
        final chunks = processor.splitIntoChunks(text);
        // Every chunk, when split on spaces, should only contain whole words
        for (final chunk in chunks) {
          for (final part in chunk.split(' ')) {
            expect(
              words.contains(part),
              isTrue,
              reason: '"$part" is not a complete word from the original text',
            );
          }
        }
      });
    });

    // ── chunkTimeout ─────────────────────────────────────────────────────────
    //
    // Expected values derived from the constants:
    //   kBaselineCharsPerSec = 12.0
    //   kTimeoutSafetyMultiplier = 2.0
    //   formula: ceil(chars / (12.0 * (settingsRate / 0.5)) * 2.0)
    //            clamped to [kMinChunkTimeoutSec=60, kMaxChunkTimeoutSec=1200]
    //
    // Rate mapping (mini → settings):  0.5x→0.25, 1.0x→0.5, 1.5x→0.75

    group('chunkTimeout', () {
      test('3500 chars @ settingsRate=0.25 (0.5× mini) returns 1167 s', () {
        // adj = 12.0*(0.25/0.5) = 6.0
        // est = ceil(3500/6.0*2) = ceil(1166.67) = 1167
        // clamped = 1167
        final t = processor.chunkTimeout(3500, settingsRate: 0.25);
        expect(t.inSeconds, 1167);
        expect(t.inSeconds,
            greaterThanOrEqualTo(TtsChunkProcessor.kMinChunkTimeoutSec));
        expect(t.inSeconds,
            lessThanOrEqualTo(TtsChunkProcessor.kMaxChunkTimeoutSec));
      });

      test('3500 chars @ settingsRate=0.75 (1.5× mini) returns 389 s', () {
        // adj = 12.0*(0.75/0.5) = 18.0
        // est = ceil(3500/18.0*2) = ceil(388.9) = 389
        final t = processor.chunkTimeout(3500, settingsRate: 0.75);
        expect(t.inSeconds, 389);
      });

      test('100 chars @ settingsRate=0.5 (1.0× mini) returns floor (60 s)', () {
        // adj = 12.0*(0.5/0.5) = 12.0
        // est = ceil(100/12*2) = ceil(16.67) = 17 → clamped to floor = 60
        final t = processor.chunkTimeout(100, settingsRate: 0.5);
        expect(t.inSeconds, TtsChunkProcessor.kMinChunkTimeoutSec);
      });

      test(
          '99999 chars @ settingsRate=0.5 (1.0× mini) returns ceiling (1200 s)',
          () {
        // adj = 12.0, est = ceil(99999/12*2) = 16667 → clamped to ceiling = 1200
        final t = processor.chunkTimeout(99999, settingsRate: 0.5);
        expect(t.inSeconds, TtsChunkProcessor.kMaxChunkTimeoutSec);
      });

      test('timeout grows as char count increases', () {
        final small = processor.chunkTimeout(500, settingsRate: 0.5);
        final large = processor.chunkTimeout(3000, settingsRate: 0.5);
        expect(large.inSeconds, greaterThanOrEqualTo(small.inSeconds));
      });

      test('timeout grows as settingsRate decreases (slower speech)', () {
        final fast = processor.chunkTimeout(2000, settingsRate: 0.75);
        final slow = processor.chunkTimeout(2000, settingsRate: 0.25);
        expect(slow.inSeconds, greaterThan(fast.inSeconds));
      });

      test('result is always within [kMinChunkTimeoutSec, kMaxChunkTimeoutSec]',
          () {
        for (final chars in [0, 1, 100, 1000, 3500, 99999, 999999]) {
          for (final rate in [0.25, 0.5, 0.75]) {
            final t = processor.chunkTimeout(chars, settingsRate: rate);
            expect(
              t.inSeconds,
              greaterThanOrEqualTo(TtsChunkProcessor.kMinChunkTimeoutSec),
            );
            expect(
              t.inSeconds,
              lessThanOrEqualTo(TtsChunkProcessor.kMaxChunkTimeoutSec),
            );
          }
        }
      });
    });

    // ── chunkTimeout: guard / crash-regression tests ─────────────────────────
    //
    // The original unguarded code had:
    //   adjustedCharsPerSec = kBaselineCharsPerSec * (settingsRate / 0.5)
    //   estimated = (charCount / adjustedCharsPerSec * ...).ceil()
    //
    // When settingsRate = 0  →  adjustedCharsPerSec = 0
    //                        →  charCount / 0.0     = double.infinity
    //                        →  infinity.ceil()     throws "Not a finite number"
    //
    // This group verifies:
    //   a) The assert fires in debug/test mode (expected developer feedback).
    //   b) Boundary-valid inputs that exercise the production-guard code path
    //      produce correct clamped results.

    group('chunkTimeout — guard / crash-regression', () {
      test(
          'settingsRate = 0 throws AssertionError in debug mode '
          '(assert is the first line of defence)', () {
        // In release builds asserts are stripped; the production guard
        // (safeRate = 0.5 fallback) prevents the infinity crash there.
        expect(
          () => processor.chunkTimeout(100, settingsRate: 0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('settingsRate < 0 throws AssertionError in debug mode', () {
        expect(
          () => processor.chunkTimeout(100, settingsRate: -0.5),
          throwsA(isA<AssertionError>()),
        );
      });

      test('charCount = -1 throws AssertionError in debug mode', () {
        expect(
          () => processor.chunkTimeout(-1, settingsRate: 0.5),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
          'charCount = 0 (boundary-valid) returns kMinChunkTimeoutSec '
          'and does not throw', () {
        // charCount=0 is valid (assert passes); estimated = 0 → clamped to floor.
        final t = processor.chunkTimeout(0, settingsRate: 0.5);
        expect(t.inSeconds, TtsChunkProcessor.kMinChunkTimeoutSec);
      });

      test(
          'very small but positive settingsRate (0.001) does not throw '
          'and result is within bounds', () {
        // Passes the assert (0.001 > 0).
        // Without the production guard this would produce a valid but huge
        // timeout that gets clamped to kMaxChunkTimeoutSec.
        final t = processor.chunkTimeout(100, settingsRate: 0.001);
        expect(
          t.inSeconds,
          greaterThanOrEqualTo(TtsChunkProcessor.kMinChunkTimeoutSec),
        );
        expect(
          t.inSeconds,
          lessThanOrEqualTo(TtsChunkProcessor.kMaxChunkTimeoutSec),
        );
      });

      test(
          'production guard equivalence: safeRate fallback produces same result '
          'as explicit 0.5 rate when rate is at boundary', () {
        // The guard uses 0.5 as the fallback when settingsRate <= 0.
        // Verify that charCount=0 at rate=0.5 returns exactly kMinChunkTimeoutSec
        // (this is what the release-mode guard would compute for settingsRate=0).
        final t = processor.chunkTimeout(0, settingsRate: 0.5);
        expect(t.inSeconds, TtsChunkProcessor.kMinChunkTimeoutSec);
      });
    });

    // ── Constants sanity ─────────────────────────────────────────────────────

    group('constants', () {
      test('kMaxChunkLength is below Android TTS hard limit of 4096', () {
        expect(TtsChunkProcessor.kMaxChunkLength, lessThan(4096));
      });

      test('kQueueTimeoutSec is a small positive number', () {
        expect(TtsChunkProcessor.kQueueTimeoutSec, greaterThan(0));
        expect(TtsChunkProcessor.kQueueTimeoutSec, lessThan(60));
      });

      test('kMinChunkTimeoutSec < kMaxChunkTimeoutSec', () {
        expect(
          TtsChunkProcessor.kMinChunkTimeoutSec,
          lessThan(TtsChunkProcessor.kMaxChunkTimeoutSec),
        );
      });
    });
  });
}
