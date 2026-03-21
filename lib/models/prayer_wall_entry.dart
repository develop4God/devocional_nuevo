// lib/models/prayer_wall_entry.dart

import 'package:flutter/foundation.dart';

/// Status of a prayer wall entry in the moderation pipeline.
enum PrayerWallStatus {
  pending,
  approved,
  rejected,
  needsReview,
  pastoral,
}

/// Immutable data model for a Prayer Wall entry displayed on the client.
///
/// Privacy by design:
/// - [originalText] is NEVER included — only [maskedText] is sent to clients.
/// - [authorId] is NEVER sent to the client; stored as a one-way hash server-side.
@immutable
class PrayerWallEntry {
  final String id;

  /// PII-masked version of the prayer — safe to display publicly.
  final String maskedText;

  /// BCP-47 language code: en | es | pt | fr | hi | ja | zh
  final String language;

  final PrayerWallStatus status;
  final bool isAnonymous;
  final int prayCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  const PrayerWallEntry({
    required this.id,
    required this.maskedText,
    required this.language,
    required this.status,
    required this.isAnonymous,
    required this.prayCount,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PrayerWallEntry.fromJson(Map<String, dynamic> json) {
    return PrayerWallEntry(
      id: json['prayerId'] as String? ?? json['id'] as String? ?? '',
      maskedText: json['maskedText'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      status: _parseStatus(json['status'] as String?),
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      prayCount: (json['prayCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
      expiresAt: _parseTimestamp(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prayerId': id,
      'maskedText': maskedText,
      'language': language,
      'status': _statusToString(status),
      'isAnonymous': isAnonymous,
      'prayCount': prayCount,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  PrayerWallEntry copyWith({
    String? id,
    String? maskedText,
    String? language,
    PrayerWallStatus? status,
    bool? isAnonymous,
    int? prayCount,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return PrayerWallEntry(
      id: id ?? this.id,
      maskedText: maskedText ?? this.maskedText,
      language: language ?? this.language,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      prayCount: prayCount ?? this.prayCount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static PrayerWallStatus _parseStatus(String? value) {
    switch (value) {
      case 'approved':
        return PrayerWallStatus.approved;
      case 'rejected':
        return PrayerWallStatus.rejected;
      case 'needs_review':
        return PrayerWallStatus.needsReview;
      case 'pastoral':
        return PrayerWallStatus.pastoral;
      default:
        return PrayerWallStatus.pending;
    }
  }

  static String _statusToString(PrayerWallStatus status) {
    switch (status) {
      case PrayerWallStatus.approved:
        return 'approved';
      case PrayerWallStatus.rejected:
        return 'rejected';
      case PrayerWallStatus.needsReview:
        return 'needs_review';
      case PrayerWallStatus.pastoral:
        return 'pastoral';
      case PrayerWallStatus.pending:
        return 'pending';
    }
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    // Firestore Timestamp — access seconds via dynamic
    try {
      final seconds = (value as dynamic).seconds as int;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerWallEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          prayCount == other.prayCount &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ prayCount.hashCode ^ status.hashCode;
}
