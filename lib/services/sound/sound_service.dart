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

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> toggle(String cueKey, {required String encounterId}) async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
      return;
    }

    try {
      final url = Constants.getEncounterAudioUrl(
        cueKey,
        encounterId: encounterId,
      );
      await _player.setUrl(url);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('⚠️ SoundService: Failed to play cue "$cueKey": $e');
      _isPlaying = false;
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _isPlaying = false;
  }
}
