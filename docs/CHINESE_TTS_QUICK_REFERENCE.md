# Chinese (zh) TTS - Quick Reference Guide

## For Developers

### Character-Based vs Word-Based Languages

#### Character-Based (Use character counting)
- **Chinese (zh)**: `languageCode == 'zh'`
- **Japanese (ja)**: `languageCode == 'ja'`
- **Formula**: `characters (no spaces) ÷ 7 chars/sec`

#### Word-Based (Use word counting)
- **English (en)**: `languageCode == 'en'`
- **Spanish (es)**: `languageCode == 'es'`
- **Portuguese (pt)**: `languageCode == 'pt'`
- **French (fr)**: `languageCode == 'fr'`
- **Formula**: `words ÷ 2.5 words/sec`

---

## Code Examples

### Setting Chinese Text for TTS

```dart
// In TtsAudioController or TtsPlayerWidget
controller.setText(
  chineseDevotionalText,
  languageCode: 'zh',  // Critical: specify zh for character-based calculation
);
```

### Getting TTS Locale for Chinese

```dart
// In LocalizationService.getTtsLocale()
case 'zh':
  return 'zh-CN';  // Simplified Chinese (mainland)
```

### Voice Selection for Chinese

```dart
// Auto-assign best Chinese voice
await provider.setTtsVoice({
  'name': 'Default',
  'locale': 'zh-CN',
});
```

---

## Testing Chinese TTS

### Manual Testing Steps

1. **Switch to Chinese**
   ```
   Settings → Application Language → 中文
   ```

2. **Load Chinese Devotional**
   ```
   Navigate to devotionals page
   Verify Chinese text displays correctly
   ```

3. **Test TTS Playback**
   ```
   Tap play button
   Verify:
   - Audio plays in Chinese
   - Progress bar advances smoothly
   - Duration is reasonable (~7 chars/sec)
   - Pause/resume works correctly
   ```

### Automated Testing

Run Chinese TTS tests:
```bash
flutter test test/controllers/tts_audio_controller_test.dart
```

Check specific Chinese tests:
```bash
flutter test test/controllers/tts_audio_controller_test.dart \
  --plain-name "Chinese"
```

---

## Common Issues & Solutions

### Issue: TTS Duration Too Fast/Slow

**Symptom**: Progress bar moves too quickly or slowly
**Cause**: Incorrect language code passed to `setText()`
**Solution**: Ensure `languageCode: 'zh'` is passed

```dart
// ❌ Wrong - will use word-based calculation
controller.setText(chineseText);  // defaults to 'es'

// ✅ Correct - uses character-based calculation
controller.setText(chineseText, languageCode: 'zh');
```

### Issue: Wrong Voice Selected

**Symptom**: English voice reads Chinese text
**Cause**: Locale not set to `zh-CN`
**Solution**: Set correct locale

```dart
// Ensure zh-CN locale is set
await ttsService.setLanguage('zh-CN');
```

### Issue: Progress Jumps on Resume

**Symptom**: Pause/resume causes progress to jump
**Cause**: Character vs word mismatch in position calculation
**Solution**: Already handled in controller - ensure `languageCode` is consistent

---

## Performance Metrics

### Expected TTS Duration

| Text Length | Expected Duration | Notes |
|-------------|------------------|-------|
| 50 chars | ~7 seconds | Short verse |
| 200 chars | ~29 seconds | Medium devotional |
| 500 chars | ~71 seconds | Full devotional |
| 1000 chars | ~143 seconds | Long devotional |

**Formula**: `duration = characters ÷ 7`

### Character Counting Method

```dart
// Remove spaces before counting
final chars = text.replaceAll(RegExp(r'\s+'), '').length;
```

**Why remove spaces?**
- Chinese doesn't use spaces between words
- Spaces only appear in punctuation/formatting
- Actual reading time is based on characters only

---

## Debugging Tips

### Enable Debug Logging

Look for these log messages:

```
📝 [TTS Controller] Idioma zh (caracteres): 156 caracteres -> 22 segundos estimados
```

If you see "Palabras:" instead, the wrong calculation is being used.

### Verify Character Count

```dart
// Quick check in Flutter DevTools console
final text = '你的中文文本';
final chars = text.replaceAll(RegExp(r'\s+'), '').length;
print('Characters: $chars, Expected duration: ${chars / 7}s');
```

---

## Best Practices

1. **Always Pass Language Code**
   ```dart
   // Don't rely on defaults
   controller.setText(text, languageCode: currentLanguage);
   ```

2. **Use Consistent Locales**
   ```dart
   // For Chinese, always use zh-CN
   const chineseLocale = 'zh-CN';
   ```

3. **Test with Real Content**
   ```dart
   // Use actual devotional text in tests
   const realDevotional = '约翰福音 3:16...';
   ```

4. **Handle Edge Cases**
   ```dart
   // Empty text, very short text, very long text
   if (text.isEmpty) return;
   ```

---

## Related Files

- **Controller**: `lib/controllers/tts_audio_controller.dart`
- **Tests**: `test/controllers/tts_audio_controller_test.dart`
- **Service**: `lib/services/tts_service.dart`
- **Widget**: `lib/widgets/tts_player_widget.dart`

---

## Support

For issues with Chinese TTS:
1. Check language code is 'zh'
2. Verify locale is 'zh-CN'
3. Run tests to verify character calculation
4. Check debug logs for duration estimation

---

**Last Updated**: December 22, 2025  
**Version**: 1.0.0  
**Status**: Production Ready

