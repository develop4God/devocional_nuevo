// lib/services/sound/sound_service.dart

import 'dart:async';

import 'package:devocional_nuevo/services/sound/audio_player_handle.dart';
import 'package:devocional_nuevo/services/sound/i_sound_service.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';

/// Ambient sound cues are prefetched to disk ahead of time by
/// EncounterBloc (mirroring its image prefetch), so in the common case
/// [toggle] resolves to a local file and starts near-instantly. [state]
/// reflects the player's real, platform-reported playing state — never a
/// value tracked by hand — so [isPlaying] can't drift out of sync with
/// what's actually playing, same modeling as TtsState in tts_service.dart.
/// [stop] is a hard, unconditional brake: it always calls the player
/// directly, same as the TTS controller's stop, with no flags gating
/// whether it's allowed to run.
class SoundService implements ISoundService {
  SoundService({
    required BaseCacheManager cacheManager,
    AudioPlayerHandle? player,
  })  : _cacheManager = cacheManager,
        _player = player ?? JustAudioPlayerHandle();

  final AudioPlayerHandle _player;
  final BaseCacheManager _cacheManager;

  /// Set only on a failed toggle()/stop() — cleared as soon as the real
  /// player reports playing again. [state] always prefers the player's
  /// live signal over this when they'd disagree that playback is active.
  bool _hadError = false;

  @override
  SoundState get state {
    if (_player.isPlaying) return SoundState.playing;
    if (_hadError) return SoundState.error;
    return SoundState.idle;
  }

  @override
  bool get isPlaying => state == SoundState.playing;

  @override
  Future<void> toggle(
    String cueKey, {
    required String encounterId,
    String? version,
  }) async {
    if (isPlaying) {
      debugPrint('🔊 SoundService.toggle: already playing "$cueKey" → stop()');
      await stop();
      return;
    }

    final url = Constants.getEncounterAudioUrl(
      cueKey,
      encounterId: encounterId,
      version: version,
    );
    final cacheKey = Constants.encounterAudioCacheKey(
      encounterId: encounterId,
      cueKey: cueKey,
      version: version,
    );

    try {
      final cached = await _cacheManager.getFileFromCache(cacheKey);
      if (cached != null) {
        debugPrint(
            '🔊 SoundService.toggle: cache hit "$cueKey" → ${cached.file.path}');
        await _player.setFilePath(cached.file.path);
      } else {
        debugPrint('🔊 SoundService.toggle: cache miss "$cueKey" → $url');
        await _player.setUrl(url);
        // Warm the cache for next time — fire-and-forget, non-fatal.
        unawaited(
          _cacheManager
              .downloadFile(url, key: cacheKey)
              .then((_) {})
              .catchError((_) {}),
        );
      }
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
      _hadError = false;
      debugPrint('🔊 SoundService.toggle: playing "$cueKey"');
    } catch (e) {
      _hadError = true;
      debugPrint('⚠️ SoundService: Failed to play cue "$cueKey": $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      _hadError = false;
      debugPrint('🔊 SoundService.stop: stopped');
    } catch (e) {
      _hadError = true;
      debugPrint('⚠️ SoundService: Failed to stop playback: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
