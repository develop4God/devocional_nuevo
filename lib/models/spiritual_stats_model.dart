// lib/models/spiritual_stats_model.dart

import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/service_locator.dart';

/// Model to track user's spiritual progress and achievements
class SpiritualStats {
  final int totalDevocionalesRead;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final List<Achievement> unlockedAchievements;
  final int favoritesCount;
  final List<String> readDevocionalIds; // Track unique IDs of read devotionals

  SpiritualStats({
    this.totalDevocionalesRead = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.unlockedAchievements = const [],
    this.favoritesCount = 0,
    this.readDevocionalIds = const [],
  });

  factory SpiritualStats.fromJson(Map<String, dynamic> json) {
    return SpiritualStats(
      totalDevocionalesRead: json['totalDevocionalesRead'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'])
          : null,
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)
              ?.map(
                  (item) => Achievement.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      favoritesCount: json['favoritesCount'] ?? 0,
      readDevocionalIds: (json['readDevocionalIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDevocionalesRead': totalDevocionalesRead,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'unlockedAchievements':
          unlockedAchievements.map((a) => a.toJson()).toList(),
      'favoritesCount': favoritesCount,
      'readDevocionalIds': readDevocionalIds,
    };
  }

  SpiritualStats copyWith({
    int? totalDevocionalesRead,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    List<Achievement>? unlockedAchievements,
    int? favoritesCount,
    List<String>? readDevocionalIds,
  }) {
    return SpiritualStats(
      totalDevocionalesRead:
          totalDevocionalesRead ?? this.totalDevocionalesRead,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      readDevocionalIds: readDevocionalIds ?? this.readDevocionalIds,
    );
  }
}

/// Model for achievements/badges
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int threshold;
  final AchievementType type;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.threshold,
    required this.type,
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: _iconFromCodePoint(json['iconCodePoint'] ?? Icons.star.codePoint),
      color: Color(json['colorValue'] ?? 0xFFFFC107),
      // Colors.amber equivalent
      threshold: json['threshold'] ?? 0,
      type: AchievementType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => AchievementType.reading),
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'colorValue': _colorToInt(color),
      'threshold': threshold,
      'type': type.toString(),
      'isUnlocked': isUnlocked,
    };
  }

  // Helper method para convertir Color a int sin warnings
  static int _colorToInt(Color color) {
    return (color.a * 255).round() << 24 |
        (color.r * 255).round() << 16 |
        (color.g * 255).round() << 8 |
        (color.b * 255).round();
  }

  // CÓDIGO CORREGIDO: Map constante con los code points de tus iconos actuales
  static const Map<int, IconData> _iconMap = {
    // Code points de los iconos que ya usas en PredefinedAchievements
    0xe2bd: Icons.auto_stories,
    // Icons.auto_stories.codePoint
    0xe8df: Icons.calendar_view_week,
    // Icons.calendar_view_week.codePoint
    0xe8b5: Icons.calendar_month,
    // Icons.calendar_month.codePoint
    0xe913: Icons.local_fire_department,
    // Icons.local_fire_department.codePoint
    0xe87c: Icons.whatshot,
    // Icons.whatshot.codePoint
    0xe3b8: Icons.emoji_events,
    // Icons.emoji_events.codePoint
    0xe3c9: Icons.favorite,
    // Icons.favorite.codePoint
    0xe90a: Icons.bookmark,
    // Icons.bookmark.codePoint
    0xe53f: Icons.star,
    // Icons.star.codePoint (fallback)
  };

  static IconData _iconFromCodePoint(int codePoint) {
    return _iconMap[codePoint] ??
        Icons.star; // Mantiene Icons.star como fallback
  }

  Achievement copyWith({bool? isUnlocked}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      threshold: threshold,
      type: type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// Types of achievements
enum AchievementType {
  reading, // Based on total devotionals read
  streak, // Based on consecutive days
  favorites, // Based on favorites count
}

/// Predefined achievements
class PredefinedAchievements {
  static List<Achievement> get all => [
        Achievement(
          id: 'first_read',
          title: getService<LocalizationService>()
              .translate('achievements.first_read_title'),
          description: getService<LocalizationService>()
              .translate('achievements.first_read_description'),
          icon: Icons.auto_stories,
          color: Colors.green,
          threshold: 1,
          type: AchievementType.reading,
        ),
        Achievement(
          id: 'week_reader',
          title: getService<LocalizationService>()
              .translate('achievements.week_reader_title'),
          description: getService<LocalizationService>()
              .translate('achievements.week_reader_description'),
          icon: Icons.calendar_view_week,
          color: Colors.blue,
          threshold: 7,
          type: AchievementType.reading,
        ),
        Achievement(
          id: 'month_reader',
          title: getService<LocalizationService>()
              .translate('achievements.month_reader_title'),
          description: getService<LocalizationService>()
              .translate('achievements.month_reader_description'),
          icon: Icons.calendar_month,
          color: Colors.purple,
          threshold: 30,
          type: AchievementType.reading,
        ),
        Achievement(
          id: 'streak_3',
          title: getService<LocalizationService>()
              .translate('achievements.streak_3_title'),
          description: getService<LocalizationService>()
              .translate('achievements.streak_3_description'),
          icon: Icons.local_fire_department,
          color: Colors.orange,
          threshold: 3,
          type: AchievementType.streak,
        ),
        Achievement(
          id: 'streak_7',
          title: getService<LocalizationService>()
              .translate('achievements.streak_7_title'),
          description: getService<LocalizationService>()
              .translate('achievements.streak_7_description'),
          icon: Icons.whatshot,
          color: Colors.red,
          threshold: 7,
          type: AchievementType.streak,
        ),
        Achievement(
          id: 'streak_30',
          title: getService<LocalizationService>()
              .translate('achievements.streak_30_title'),
          description: getService<LocalizationService>()
              .translate('achievements.streak_30_description'),
          icon: Icons.emoji_events,
          color: Colors.amber,
          threshold: 30,
          type: AchievementType.streak,
        ),
        Achievement(
          id: 'first_favorite',
          title: getService<LocalizationService>()
              .translate('achievements.first_favorite_title'),
          description: getService<LocalizationService>()
              .translate('achievements.first_favorite_description'),
          icon: Icons.favorite,
          color: Colors.pink,
          threshold: 1,
          type: AchievementType.favorites,
        ),
        Achievement(
          id: 'collector',
          title: getService<LocalizationService>()
              .translate('achievements.collector_title'),
          description: getService<LocalizationService>()
              .translate('achievements.collector_description'),
          icon: Icons.bookmark,
          color: Colors.indigo,
          threshold: 10,
          type: AchievementType.favorites,
        ),
      ];
}
