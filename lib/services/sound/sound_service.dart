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
/// [toggle] resolves to a local file and starts near-instantly — the
/// network-latency window that used to make toggle()/stop() race each
/// other barely exists any more. [stop] is still a hard, unconditional
/// brake regardless: it always calls the player directly, same as the
/// TTS controller's stop, with no flags gating whether it's allowed to run.
class SoundService implements ISoundService {
  SoundService({
    required BaseCacheManager cacheManager,
    AudioPlayerHandle? player,
  })  : _cacheManager = cacheManager,
        _player = player ?? JustAudioPlayerHandle();

  final AudioPlayerHandle _player;
  final BaseCacheManager _cacheManager;
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> toggle(
    String cueKey, {
    required String encounterId,
    String? version,
  }) async {
    if (_isPlaying) {
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
      _isPlaying = true;
      debugPrint('🔊 SoundService.toggle: playing "$cueKey"');
    } catch (e) {
      debugPrint('⚠️ SoundService: Failed to play cue "$cueKey": $e');
      _isPlaying = false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      debugPrint('🔊 SoundService.stop: stopped');
    } catch (e) {
      debugPrint('⚠️ SoundService: Failed to stop playback: $e');
    } finally {
      _isPlaying = false;
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _isPlaying = false;
  }
}
