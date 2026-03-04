// lib/repositories/prayer_wall_repository.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:devocional_nuevo/models/prayer_wall_entry.dart';
import 'package:devocional_nuevo/repositories/i_prayer_wall_repository.dart';
import 'package:flutter/foundation.dart';

/// Firestore implementation of [IPrayerWallRepository].
///
/// Collection: `prayers/{prayerId}`
/// Security rules ensure clients can only read `maskedText` — never `originalText`.
class PrayerWallRepository implements IPrayerWallRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'prayers';

  PrayerWallRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<PrayerWallEntry>> watchApprovedPrayers({
    required String userLanguage,
  }) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['prayerId'] = doc.id;
              return PrayerWallEntry.fromJson(data);
            } catch (e) {
              debugPrint('❌ [PrayerWallRepository] Parse error for ${doc.id}: $e');
              return null;
            }
          })
          .whereType<PrayerWallEntry>()
          .toList();

      // Sort: same-language prayers first, then by creation date (newest first)
      entries.sort((a, b) {
        final aIsMyLang = a.language == userLanguage ? 0 : 1;
        final bIsMyLang = b.language == userLanguage ? 0 : 1;
        if (aIsMyLang != bIsMyLang) return aIsMyLang - bIsMyLang;
        return b.createdAt.compareTo(a.createdAt);
      });

      return entries;
    });
  }

  @override
  Stream<PrayerWallEntry?> watchMyPendingPrayer({
    required String authorHash,
  }) {
    return _firestore
        .collection(_collection)
        .where('authorId', isEqualTo: authorHash)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      try {
        final doc = snapshot.docs.first;
        final data = Map<String, dynamic>.from(doc.data());
        data['prayerId'] = doc.id;
        return PrayerWallEntry.fromJson(data);
      } catch (e) {
        debugPrint('❌ [PrayerWallRepository] Error parsing pending prayer: $e');
        return null;
      }
    });
  }

  @override
  Future<String> submitPrayer({
    required String originalText,
    required String language,
    required bool isAnonymous,
    required String authorHash,
  }) async {
    final now = Timestamp.now();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 30)),
    );

    final docRef = await _firestore.collection(_collection).add({
      'originalText': originalText, // stored server-side, never sent to client
      'maskedText': '', // will be filled by Cloud Function after PII masking
      'language': language,
      'status': 'pending',
      'isAnonymous': isAnonymous,
      'authorId': authorHash,
      'prayCount': 0,
      'reportCount': 0,
      'moderationScore': 0.0,
      'moderationFlag': 'none',
      'moderationReason': '',
      'createdAt': now,
      'moderatedAt': null,
      'expiresAt': expiresAt,
    });

    return docRef.id;
  }

  @override
  Future<void> tapPrayHand({required String prayerId}) async {
    await _firestore.collection(_collection).doc(prayerId).update({
      'prayCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> reportPrayer({required String prayerId}) async {
    await _firestore.runTransaction((transaction) async {
      final ref = _firestore.collection(_collection).doc(prayerId);
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) return;

      final reportCount = (snapshot.data()?['reportCount'] as num?)?.toInt() ?? 0;
      final newReportCount = reportCount + 1;

      final updates = <String, dynamic>{
        'reportCount': newReportCount,
      };

      // After 3 reports → move to needs_review automatically
      if (newReportCount >= 3) {
        updates['status'] = 'needs_review';
      }

      transaction.update(ref, updates);
    });
  }

  @override
  Future<void> deletePrayer({
    required String prayerId,
    required String authorHash,
  }) async {
    final ref = _firestore.collection(_collection).doc(prayerId);
    final snapshot = await ref.get();

    if (!snapshot.exists) return;

    // Verify ownership before hard-deleting
    final storedAuthor = snapshot.data()?['authorId'] as String?;
    if (storedAuthor != authorHash) {
      throw Exception('Unauthorized: cannot delete another user\'s prayer.');
    }

    await ref.delete();
  }

  /// Utility: creates a one-way SHA-256 hash of a Firebase UID.
  /// Called once per session — never store the raw UID.
  static String hashUserId(String uid) {
    final bytes = utf8.encode(uid);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
