// ignore_for_file: dangling_library_doc_comments
/// Abstract interface for Text-to-Speech service
/// This interface allows for dependency injection and provider-agnostic implementation
/// Can be used with BLoC, Riverpod, Provider, or any other state management solution
library;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/foundation.dart';

/// Abstract interface defining TTS service capabilities
abstract class ITtsService {
  // State streams
  Stream<TtsState> get stateStream;
  Stream<double> get progressStream;

  // State getters
  TtsState get currentState;
  String? get currentDevocionalId;
  bool get isPlaying;
  bool get isPaused;
  bool get isActive;
  bool get isDisposed;

  // Chunk navigation
  int get currentChunkIndex;
  int get totalChunks;
  VoidCallback? get previousChunk;
  VoidCallback? get nextChunk;
  Future<void> Function(int index)? get jumpToChunk;

  // Core playback methods
  Future<void> initialize();
  Future<void> speakDevotional(Devocional devocional);
  Future<void> speakText(String text);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();

  // Configuration methods
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  void setLanguageContext(String language, String version);
  Future<List<String>> getLanguages();
  Future<List<String>> getVoices();
  Future<List<String>> getVoicesForLanguage(String language);
  Future<void> setVoice(Map<String, String> voice);

  // Lifecycle methods
  Future<void> initializeTtsOnAppStart(String languageCode);
  Future<void> assignDefaultVoiceForLanguage(String languageCode);
  Future<void> dispose();

  // Testing support
  @visibleForTesting
  List<String> generateChunksForTesting(Devocional devocional);
  
  @visibleForTesting
  Map<String, String> getSectionHeadersForTesting(String language);
  
  @visibleForTesting
  String formatBibleBook(String reference);
}
