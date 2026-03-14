# TTS & Hindi Critical Issues - Implementation Plan

**Date:** February 17, 2026

## Issues to Fix

### 1. ✅ Date not translated to Hindi - FIXED

**Status:** COMPLETED  
**File:** `lib/utils/localized_date_formatter.dart`

- Added Hindi case with debug logging
- Added import for debugPrint

### 2. Voice selector showing empty for Hindi

**Problem:** Voice list is empty because no Hindi voices on device OR filtering too strict  
**Solution:** Add fallback to show ALL voices when language-specific list is empty

### 3. TTS Modal not closing on complete

**Problem:** Modal stays open after audio completes  
**Root Cause:** Modal close logic in `devocionales_page.dart` line 1082 triggers correctly, but
Navigator.pop might not work if modal context changed

### 4. Voice selector button should pause first

**Problem:** Clicking voice selector while playing doesn't pause  
**Solution:** Already implemented in line 128 of `devocional_tts_miniplayer_presenter.dart`:

```dart
if (state == TtsPlayerState.playing) {
await ttsAudioController.pause();
}
```

### 5. TTS completion not recording "heard" stats

**Problem:** Stats not being recorded when TTS completes  
**Root Cause:** `onCompleted` callback in TTS widget fires but might not be connected properly

---

## Implementation

### Fix 2: Voice Selector - Show All Voices as Fallback for Hindi

**File:** `lib/widgets/voice_selector_dialog.dart`

Need to modify `_loadVoices()` to show ALL voices if language-specific list is empty.

### Fix 3: TTS Modal Close on Complete

**File:** `lib/widgets/devocionales/devocional_tts_miniplayer_presenter.dart`

Modal already has logic to close on completed (line 51), but needs debug logging to verify it works.

### Fix 5: Record "Heard" Stats on TTS Complete

**File:** `lib/widgets/tts_player_widget.dart`

Already implemented in lines 59-84, but need to verify `onCompleted` callback is properly wired.

---

## Debug Logging Additions

All fixes include comprehensive debug logging to track:

1. When date formatter is called and what locale it uses
2. When voice list loads and how many voices found
3. When TTS completes and whether stats are recorded
4. When modal closes and why

---

## Testing Checklist

- [ ] Hindi date displays correctly
- [ ] Voice selector shows voices for Hindi (or all voices as fallback)
- [ ] TTS modal closes automatically when audio completes
- [ ] Voice selector button pauses audio before opening
- [ ] TTS completion records "heard" in stats
- [ ] Logs show all debug information clearly

---

## Priority Order

1. **HIGH** - Voice selector empty (blocks users from selecting voice)
2. **HIGH** - TTS modal not closing (bad UX)
3. **MEDIUM** - Stats not recording (affects gamification)
4. **COMPLETED** - Date formatting


