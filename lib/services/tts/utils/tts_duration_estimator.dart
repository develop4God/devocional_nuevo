// lib/services/tts/utils/tts_duration_estimator.dart

/// Estimates the total TTS playback duration for a given text and language.
///
/// Each language uses a rate calibrated to its typical TTS engine output:
/// - JA: character-based (logographic script, ~7 chars/sec)
/// - ZH: character-based (logographic script, ~5.5 chars/sec)
/// - AR: word-based, slower rate (~100 WPM — morphologically dense)
/// - All others: word-based, standard rate (~150 WPM)
///
/// Used by [TtsAudioController.setText] to set the UI timer before playback.
/// Intentionally decoupled from [TtsChunkProcessor] — duration estimation
/// applies to all texts regardless of whether chunking occurs.
class TtsDurationEstimator {
  const TtsDurationEstimator._();

  static const double _charsPerSecondJa = 3.0;
  static const double _charsPerSecondZh = 5.5;
  static const double _wpmStandard = 150.0;
  static const double _wpmArabic = 80.0;

  /// Returns the estimated [Duration] for [text] spoken in [languageCode].
  static Duration estimate(String text, String languageCode) {
    if (languageCode == 'ja') {
      final chars = text.replaceAll(RegExp(r'\s+'), '').length;
      return Duration(seconds: (chars / _charsPerSecondJa).round());
    }
    if (languageCode == 'zh') {
      final chars = text.replaceAll(RegExp(r'\s+'), '').length;
      return Duration(seconds: (chars / _charsPerSecondZh).round());
    }
    final words = text.trim().split(RegExp(r'\s+')).length;
    final wpm = languageCode == 'ar' ? _wpmArabic : _wpmStandard;
    return Duration(seconds: (words / (wpm / 60.0)).round());
  }
}
