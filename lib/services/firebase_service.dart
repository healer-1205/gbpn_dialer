import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gbpn_dealer/services/storage_service.dart';

@pragma('vm:entry-point')
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final StorageService _storage = StorageService();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await requestPermission();
    _handleTokenRefresh();
    _listenToMessages();
  }

  /// Request permission for iOS & Android notifications
  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      getFCMToken();
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Get the FCM token
  Future<String?> getFCMToken() async {
    String? fcmToken =
        await _storage.getFCMToken() ?? await _firebaseMessaging.getToken();
    await _storage.saveFCMToken(fcmToken!);
    // return await _firebaseMessaging.getToken();
    return fcmToken;
  }

  /// Handle FCM Token Refresh
  void _handleTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token refreshed: $newToken");
      await _storage.saveFCMToken(newToken!);
      // TODO: Send this token to your server if needed
    });
  }

  /// Listen for background & terminated notifications
  void _listenToMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🔔 Notification tapped: ${message.toString()}");
      // TODO: Navigate user to a specific screen if required
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔔 Background message received: ${message.notification?.title}");
}
