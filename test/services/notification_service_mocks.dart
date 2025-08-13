// test/services/notification_service_mocks.dart
// Mock classes and setup utilities for NotificationService tests

import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Firebase Auth Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

// Firestore Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference<T> extends Mock implements CollectionReference<T> {}

class MockDocumentReference<T> extends Mock implements DocumentReference<T> {}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {}

class MockQueryDocumentSnapshot<T> extends Mock implements QueryDocumentSnapshot<T> {}

// Firebase Messaging Mocks
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockRemoteNotification extends Mock implements RemoteNotification {}

// SharedPreferences Mock
class MockSharedPreferences extends Mock implements SharedPreferences {}

// Flutter Local Notifications Mock
class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock implements IOSFlutterLocalNotificationsPlugin {}

// Permission Handler Mock
class MockPermission extends Mock implements Permission {}

// Common setup utilities
class NotificationServiceTestHelper {
  // Create a test-friendly NotificationService instance with mocks
  static NotificationService createTestNotificationService({
    required MockFlutterLocalNotificationsPlugin localNotificationsPlugin,
    required MockFirebaseMessaging firebaseMessaging,
    required MockFirebaseFirestore firestore,
    required MockFirebaseAuth auth,
  }) {
    return NotificationService.forTesting(
      localNotificationsPlugin: localNotificationsPlugin,
      firebaseMessaging: firebaseMessaging,
      firestore: firestore,
      auth: auth,
    );
  }

  static void setupFirebaseAuthMocks(
    MockFirebaseAuth mockAuth,
    MockUser mockUser, {
    String userId = 'test_user_123',
    bool isAuthenticated = true,
  }) {
    if (isAuthenticated) {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(userId);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
    } else {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    }
  }

  static void setupFirestoreMocks(
    MockFirebaseFirestore mockFirestore,
    MockCollectionReference mockUsersCollection,
    MockDocumentReference mockUserDoc,
    MockCollectionReference mockSettingsCollection,
    MockDocumentReference mockNotificationDoc,
    MockDocumentSnapshot mockDocSnapshot, {
    bool docExists = true,
    Map<String, dynamic>? docData,
  }) {
    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection('settings')).thenReturn(mockSettingsCollection);
    when(() => mockSettingsCollection.doc('notifications')).thenReturn(mockNotificationDoc);
    when(() => mockNotificationDoc.set(any(), any())).thenAnswer((_) async => {});
    when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async => {});
    when(() => mockNotificationDoc.get()).thenAnswer((_) async => mockDocSnapshot);
    
    when(() => mockDocSnapshot.exists).thenReturn(docExists);
    when(() => mockDocSnapshot.data()).thenReturn(docData);
  }

  static void setupSharedPreferencesMocks(
    MockSharedPreferences mockPrefs, {
    bool notificationsEnabled = true,
    String notificationTime = '09:00',
    String? fcmToken,
  }) {
    when(() => mockPrefs.getBool('notifications_enabled')).thenReturn(notificationsEnabled);
    when(() => mockPrefs.getString('notification_time')).thenReturn(notificationTime);
    when(() => mockPrefs.getString('fcm_token')).thenReturn(fcmToken);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
  }

  static void setupFCMMocks(
    MockFirebaseMessaging mockMessaging,
    MockNotificationSettings mockSettings, {
    String fcmToken = 'mock_fcm_token_123',
    AuthorizationStatus authStatus = AuthorizationStatus.authorized,
  }) {
    when(() => mockMessaging.requestPermission(
      alert: any(named: 'alert'),
      announcement: any(named: 'announcement'),
      badge: any(named: 'badge'),
      carPlay: any(named: 'carPlay'),
      criticalAlert: any(named: 'criticalAlert'),
      provisional: any(named: 'provisional'),
      sound: any(named: 'sound'),
    )).thenAnswer((_) async => mockSettings);
    
    when(() => mockSettings.authorizationStatus).thenReturn(authStatus);
    when(() => mockMessaging.getToken()).thenAnswer((_) async => fcmToken);
    when(() => mockMessaging.getInitialMessage()).thenAnswer((_) async => null);
    when(() => mockMessaging.onTokenRefresh).thenAnswer((_) => Stream.value(fcmToken));
  }

  static void setupLocalNotificationsMocks(
    MockFlutterLocalNotificationsPlugin mockPlugin,
    MockIOSFlutterLocalNotificationsPlugin mockIOSPlugin, {
    bool initializeResult = true,
    bool iOSPermissionResult = true,
  }) {
    when(() => mockPlugin.initialize(
      any(),
      onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
      onDidReceiveBackgroundNotificationResponse: any(named: 'onDidReceiveBackgroundNotificationResponse'),
    )).thenAnswer((_) async => initializeResult);
    
    when(() => mockPlugin.show(any(), any(), any(), any(), payload: any(named: 'payload')))
        .thenAnswer((_) async => {});
    
    when(() => mockPlugin.cancelAll()).thenAnswer((_) async => {});
    
    when(() => mockPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>())
        .thenReturn(mockIOSPlugin);
    
    when(() => mockIOSPlugin.requestPermissions(
      alert: any(named: 'alert'),
      badge: any(named: 'badge'),
      sound: any(named: 'sound'),
    )).thenAnswer((_) async => iOSPermissionResult);
  }

  static Map<String, dynamic> createFirestoreNotificationSettings({
    bool notificationsEnabled = true,
    String notificationTime = '09:00',
    String userTimezone = 'America/Panama',
  }) {
    return {
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': notificationTime,
      'userTimezone': userTimezone,
      'lastUpdated': 'mock_timestamp',
    };
  }
}