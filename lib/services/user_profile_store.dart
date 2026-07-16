import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IUserProfileStore {
  Future<void> updateLastLogin(String uid);

  Future<Map<String, dynamic>?> getNotificationSettings(String uid);

  Future<void> saveNotificationSettings(
    String uid, {
    required bool notificationsEnabled,
    required String notificationTime,
    required String userTimezone,
    required String preferredLanguage,
  });

  Future<void> saveFcmToken(String uid, String token,
      {required String platform});
}

class FirestoreUserProfileStore implements IUserProfileStore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>?> getNotificationSettings(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .get();
    return doc.data();
  }

  @override
  Future<void> saveNotificationSettings(
    String uid, {
    required bool notificationsEnabled,
    required String notificationTime,
    required String userTimezone,
    required String preferredLanguage,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set({
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': notificationTime,
      'userTimezone': userTimezone,
      'lastUpdated': FieldValue.serverTimestamp(),
      'preferredLanguage': preferredLanguage,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveFcmToken(
    String uid,
    String token, {
    required String platform,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': platform,
    }, SetOptions(merge: true));
  }
}
