import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
// flutter imports intentionally reduced to keep this service UI-agnostic
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_model.dart';

// Top-level background message handler required by firebase_messaging
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final service = NotificationService();
  await service._storeNotificationFromRemoteMessage(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _notificationsCollection = 'notifications';

  // Initialize notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    await _updateFCMToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Register the top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // Handle notification when app is terminated
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpenedApp(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_updateUserToken);
  }

  // Update FCM token in Firestore (use merge to avoid failures)
  Future<void> _updateFCMToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM token updated: $token');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Update user token when it refreshes (use merge)
  Future<void> _updateUserToken(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('FCM token refreshed: $token');
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    await _showLocalNotification(message);

    // Store notification in Firestore
    await _storeNotificationFromRemoteMessage(message);
  }

  // Handle notification opened app
  Future<void> _handleNotificationOpenedApp(RemoteMessage message) async {
    print('A new onMessageOpenedApp event was published!');
    // Navigate to specific page based on notification data
    // This would typically be handled by the main app
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'utem_reporter_channel',
      'UTeM Reporter Notifications',
      channelDescription: 'Notifications for UTeM Reporter app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      final Map<String, dynamic> data = jsonDecode(payload);
      // Handle navigation based on notification data
      print('Notification tapped with data: $data');
    }
  }

  // Store notification from remote message
  // NOTE: This method is now background-safe and does not depend on Auth being available.
  Future<void> _storeNotificationFromRemoteMessage(
      RemoteMessage message) async {
    try {
      // Use assignedTo from message data when present (server/cloud function should include it)
      final String? assignedTo = message.data['assignedTo'] as String? ??
          message.data['recipient'] as String? ??
          message.data['userId'] as String?;

      if (assignedTo == null || assignedTo.isEmpty) {
        // If there's no recipient/assignedTo in payload, we skip storing to avoid polluting notifications
        print('Skipping storing notification: no assignedTo in message.data');
        return;
      }

      // Build a Firestore map directly (avoid relying on FirebaseAuth in background)
      final Map<String, dynamic> map = <String, dynamic>{
        'title': message.notification?.title ?? 'New Notification',
        'message': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'systemAnnouncement',
        'priority': message.data['priority'] ?? 'normal',
        'userId': message.data['userId'] ?? null,
        'reportId': message.data['reportId'] ?? null,
        'isRead': false,
        'data': message.data,
        'assignedTo': assignedTo,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_notificationsCollection).add(map);
      print('Notification stored for assignedTo=$assignedTo');
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  // Create and send notification
  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String userId,
    required String assignedTo, // <- require assigned staff uid
    String? reportId,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Firestore will generate
        title: title,
        message: message,
        type: type,
        priority: priority,
        userId: userId,
        reportId: reportId,
        assignedTo: assignedTo,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );

      final Map<String, dynamic> map = notification.toFirestore();
      map['assignedTo'] = assignedTo;
      // Use server timestamp for createdAt (overwrite to keep consistency)
      map['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_notificationsCollection).add(map);
      print('Notification created for user: $userId assignedTo: $assignedTo');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications for current user (staff) => filter by assignedTo
  Stream<List<NotificationModel>> getUserNotifications() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('assignedTo', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread notification count (staff) => filter by assignedTo
  Stream<int> getUnreadCount() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('assignedTo', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications for current user (assignedTo) as read
  Future<void> markAllAsRead() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('assignedTo', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Helper methods
  // NOTE: parsing helpers removed (not used). If needed later, re-add.
}
