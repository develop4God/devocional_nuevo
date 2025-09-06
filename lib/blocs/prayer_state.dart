// lib/blocs/prayer_state.dart

import 'package:devocional_nuevo/models/prayer_model.dart';

abstract class PrayerState {}

/// Initial state when the bloc is created
class PrayerInitial extends PrayerState {}

/// State when prayers are being loaded
class PrayerLoading extends PrayerState {}

/// State when prayers are successfully loaded
class PrayerLoaded extends PrayerState {
  final List<Prayer> prayers;
  final String? errorMessage;

  PrayerLoaded({
    required this.prayers,
    this.errorMessage,
  });

  /// Get only active prayers
  List<Prayer> get activePrayers => prayers.where((p) => p.isActive).toList();

  /// Get only answered prayers
  List<Prayer> get answeredPrayers =>
      prayers.where((p) => p.isAnswered).toList();

  /// Get total count of prayers
  int get totalPrayers => prayers.length;

  /// Get count of active prayers
  int get activePrayersCount => activePrayers.length;

  /// Get count of answered prayers
  int get answeredPrayersCount => answeredPrayers.length;

  /// Get statistics for display
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    var oldestActivePrayer = 0;

    if (activePrayers.isNotEmpty) {
      oldestActivePrayer = activePrayers
          .map((p) => now.difference(p.createdDate).inDays)
          .reduce((a, b) => a > b ? a : b);
    }

    return {
      'total': totalPrayers,
      'active': activePrayersCount,
      'answered': answeredPrayersCount,
      'oldestActiveDays': oldestActivePrayer,
    };
  }

  /// Create a copy of this state with updated values
  PrayerLoaded copyWith({
    List<Prayer>? prayers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrayerLoaded(
      prayers: prayers ?? this.prayers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// State when there's an error with prayers
class PrayerError extends PrayerState {
  final String message;

  PrayerError(this.message);
}
