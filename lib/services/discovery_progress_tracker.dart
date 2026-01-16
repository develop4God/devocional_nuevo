// lib/services/discovery_progress_tracker.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track progress for Discovery studies.
class DiscoveryProgressTracker {
  static const String _progressKeyPrefix = 'discovery_progress_';

  /// Get progress for a specific study
  Future<DiscoveryProgress> getProgress(String studyId, [String? languageCode]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Use languageCode in key to keep progress separate per language
      final key = _getStudyKey(studyId, languageCode);
      final progressJson = prefs.getString(key);

      if (progressJson != null && progressJson.isNotEmpty) {
        final json = jsonDecode(progressJson) as Map<String, dynamic>;
        return DiscoveryProgress.fromJson(json);
      }

      return DiscoveryProgress(studyId: studyId, languageCode: languageCode);
    } catch (e) {
      debugPrint('Error loading progress for $studyId: $e');
      return DiscoveryProgress(studyId: studyId, languageCode: languageCode);
    }
  }

  /// Mark a section as completed
  Future<void> markSectionCompleted(String studyId, int sectionIndex, [String? languageCode]) async {
    try {
      final progress = await getProgress(studyId, languageCode);
      if (!progress.completedSections.contains(sectionIndex)) {
        final updatedSections = [...progress.completedSections, sectionIndex];
        final updatedProgress = progress.copyWith(
          completedSections: updatedSections,
        );
        await _saveProgress(updatedProgress);
      }
    } catch (e) {
      debugPrint('Error marking section completed: $e');
    }
  }

  /// Save an answer to a discovery question
  Future<void> answerQuestion(
    String studyId,
    int questionIndex,
    String answer, [
    String? languageCode,
  ]) async {
    try {
      final progress = await getProgress(studyId, languageCode);
      final updatedAnswers = Map<int, String>.from(progress.answeredQuestions);
      updatedAnswers[questionIndex] = answer;

      final updatedProgress = progress.copyWith(
        answeredQuestions: updatedAnswers,
      );
      await _saveProgress(updatedProgress);
    } catch (e) {
      debugPrint('Error saving question answer: $e');
    }
  }

  /// Mark a study as completed
  Future<void> completeStudy(String studyId, [String? languageCode]) async {
    try {
      final progress = await getProgress(studyId, languageCode);
      if (!progress.isCompleted) {
        final updatedProgress = progress.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _saveProgress(updatedProgress);
      }
    } catch (e) {
      debugPrint('Error completing study: $e');
    }
  }

  /// NEW: Clears progress for a specific study so user can "do it again"
  Future<void> resetStudyProgress(String studyId, [String? languageCode]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStudyKey(studyId, languageCode);
      await prefs.remove(key);
      debugPrint('♻️ Discovery: Progress reset for study $studyId ($languageCode)');
    } catch (e) {
      debugPrint('Error resetting study progress: $e');
    }
  }

  /// Calculate completion percentage for a study
  Future<double> getCompletionPercentage(
    String studyId,
    int totalSections, [
    String? languageCode,
  ]) async {
    try {
      final progress = await getProgress(studyId, languageCode);
      if (totalSections == 0) return 0.0;
      return progress.completedSections.length / totalSections;
    } catch (e) {
      debugPrint('Error calculating completion percentage: $e');
      return 0.0;
    }
  }

  String _getStudyKey(String studyId, String? languageCode) {
    if (languageCode != null && languageCode.isNotEmpty) {
      return '$_progressKeyPrefix${studyId}_$languageCode';
    }
    return '$_progressKeyPrefix$studyId';
  }

  /// Save progress to SharedPreferences
  Future<void> _saveProgress(DiscoveryProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStudyKey(progress.studyId, progress.languageCode);
      final json = jsonEncode(progress.toJson());
      await prefs.setString(key, json);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  /// Clear all progress (useful for testing)
  Future<void> clearAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_progressKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing progress: $e');
    }
  }
}

/// Model to track progress for a Discovery study
class DiscoveryProgress {
  final String studyId;
  final String? languageCode;
  final List<int> completedSections;
  final Map<int, String> answeredQuestions;
  final bool isCompleted;
  final DateTime? completedAt;

  DiscoveryProgress({
    required this.studyId,
    this.languageCode,
    List<int>? completedSections,
    Map<int, String>? answeredQuestions,
    this.isCompleted = false,
    this.completedAt,
  })  : completedSections = completedSections ?? [],
        answeredQuestions = answeredQuestions ?? {};

  /// Create from JSON
  factory DiscoveryProgress.fromJson(Map<String, dynamic> json) {
    return DiscoveryProgress(
      studyId: json['studyId'] as String? ?? '',
      languageCode: json['languageCode'] as String?,
      completedSections: (json['completedSections'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      answeredQuestions:
          (json['answeredQuestions'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(int.parse(key), value as String),
              ) ??
              {},
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'studyId': studyId,
      'languageCode': languageCode,
      'completedSections': completedSections,
      'answeredQuestions': answeredQuestions.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Copy with updated fields
  DiscoveryProgress copyWith({
    String? studyId,
    String? languageCode,
    List<int>? completedSections,
    Map<int, String>? answeredQuestions,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DiscoveryProgress(
      studyId: studyId ?? this.studyId,
      languageCode: languageCode ?? this.languageCode,
      completedSections: completedSections ?? this.completedSections,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Get completion percentage
  double getCompletionPercentage(int totalSections) {
    if (totalSections == 0) return 0.0;
    return completedSections.length / totalSections;
  }
}
