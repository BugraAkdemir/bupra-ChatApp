import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // This function must be top-level and cannot be inside a class
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize notification service
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      await _saveTokenToFirestore();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(token: newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore({String? token}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final fcmToken = token ?? await _messaging.getToken();
    if (fcmToken == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': fcmToken,
      });
    } catch (e) {
      // Handle error silently
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    // You can show a local notification or update UI
    // For now, we'll just handle it silently
    // In a production app, you might want to show an in-app notification
  }

  /// Handle background messages (when app is opened from notification)
  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle navigation or other actions when user taps notification
    // This will be handled in the main app navigation
  }

  /// Send notification to specific user
  /// Note: In production, this should be done via Cloud Functions
  /// For now, we'll use a simple HTTP call to FCM REST API
  Future<void> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This is a simplified version
    // In production, use Cloud Functions to send notifications
    // For now, we'll store notification data in Firestore
    // and let Cloud Functions handle the actual sending

    // Alternative: Use http package to call FCM REST API
    // But this requires server key which should not be in client code
    // So we'll use Firestore trigger approach instead
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

