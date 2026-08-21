// lib/services/sound/sound_service.dart

import 'package:devocional_nuevo/services/sound/audio_player_handle.dart';
import 'package:devocional_nuevo/services/sound/i_sound_service.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class SoundService implements ISoundService {
  SoundService({AudioPlayerHandle? player})
      : _player = player ?? JustAudioPlayerHandle();

  final AudioPlayerHandle _player;
  bool _isPlaying = false;

  /// Tracks an in-flight [toggle] call. [SoundService.toggle]'s "start
  /// playing" branch awaits network + player setup before flipping
  /// [_isPlaying], so a second call landing in that window would otherwise
  /// also see [_isPlaying] as false and start a duplicate playback instead
  /// of stopping the first. Concurrent callers await this future instead of
  /// racing, then act on the now-settled state.
  Future<void>? _pendingToggle;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> toggle(
    String cueKey, {
    required String encounterId,
    String? version,
  }) async {
    final pending = _pendingToggle;
    if (pending != null) {
      debugPrint('🔊 SoundService.toggle: awaiting in-flight toggle first');
      await pending;
    }

    if (_isPlaying) {
      debugPrint('🔊 SoundService.toggle: already playing "$cueKey" → stop()');
      await stop();
      return;
    }

    final operation = _startPlaying(cueKey, encounterId, version);
    _pendingToggle = operation;
    try {
      await operation;
    } finally {
      if (identical(_pendingToggle, operation)) {
        _pendingToggle = null;
      }
    }
  }

  Future<void> _startPlaying(
    String cueKey,
    String encounterId,
    String? version,
  ) async {
    try {
      final url = Constants.getEncounterAudioUrl(
        cueKey,
        encounterId: encounterId,
        version: version,
      );
      debugPrint('🔊 SoundService.toggle: loading "$cueKey" → $url');
      await _player.setUrl(url);
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
    final pending = _pendingToggle;
    if (pending != null) {
      debugPrint('🔊 SoundService.stop: awaiting in-flight toggle first');
      await pending;
    }

    if (!_isPlaying) {
      debugPrint('🔊 SoundService.stop: no-op — not playing');
      return;
    }
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
