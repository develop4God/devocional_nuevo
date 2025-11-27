import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsAudioController', () {
    late TtsAudioController controller;

    setUp(() {
      controller = TtsAudioController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is idle', () {
      print('Estado inicial: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('play sets state to playing', () {
      print('Antes de play: ${controller.state.value}');
      controller.play();
      print('Después de play: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.playing);
    });

    test('pause sets state to paused', () {
      controller.play();
      print('Antes de pause: ${controller.state.value}');
      controller.pause();
      print('Después de pause: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.paused);
    });

    test('stop sets state to idle', () {
      controller.play();
      print('Antes de stop: ${controller.state.value}');
      controller.stop();
      print('Después de stop: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('complete sets state to completed', () {
      controller.play();
      print('Antes de complete: ${controller.state.value}');
      controller.complete();
      print('Después de complete: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.completed);
    });

    test('error sets state to error', () {
      controller.play();
      print('Antes de error: ${controller.state.value}');
      controller.error();
      print('Después de error: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.error);
    });
  });
}
