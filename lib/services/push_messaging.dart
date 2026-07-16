import 'package:firebase_messaging/firebase_messaging.dart';

abstract class IPushMessaging {
  Future<RemoteMessage?> getInitialMessage();

  Future<NotificationSettings> requestPermission();

  Stream<String> get onTokenRefresh;

  Future<String?> getToken();

  Stream<RemoteMessage> get onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp;
}

/// Pure pass-through wrapper around [FirebaseMessaging]. Must not catch or
/// translate exceptions — callers rely on the raw error text/type (e.g. the
/// SERVICE_NOT_AVAILABLE substring match and FirebaseException fields used
/// for retry/backoff and Crashlytics reporting in NotificationService).
class FirebaseCloudMessaging implements IPushMessaging {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  @override
  Future<NotificationSettings> requestPermission() =>
      _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
