import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    await _updateFCMToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // Handle notification when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpenedApp(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_updateUserToken);
  }

  // Update FCM token in Firestore
  Future<void> _updateFCMToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token updated: $token');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Update user token when it refreshes
  Future<void> _updateUserToken(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
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

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Store notification in Firestore
    // Note: This is a static method, so we need to create a new instance
    final service = NotificationService();
    await service._storeNotificationFromRemoteMessage(message);
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
  Future<void> _storeNotificationFromRemoteMessage(RemoteMessage message) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: '', // Firestore will generate
        title: message.notification?.title ?? 'New Notification',
        message: message.notification?.body ?? '',
        type: _getNotificationTypeFromData(message.data),
        priority: _getNotificationPriorityFromData(message.data),
        userId: user.uid,
        reportId: message.data['reportId'],
        createdAt: DateTime.now(),
        isRead: false,
        data: message.data,
      );

      await _firestore.collection(_notificationsCollection).add(notification.toFirestore());
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
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );

      await _firestore.collection(_notificationsCollection).add(notification.toFirestore());
      print('Notification created for user: $userId');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications for current user
  Stream<List<NotificationModel>> getUserNotifications() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: user.uid)
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

  // Helper methods
  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final String? typeString = data['type'];
    if (typeString == null) return NotificationType.systemAnnouncement;

    return NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => NotificationType.systemAnnouncement,
    );
  }

  NotificationPriority _getNotificationPriorityFromData(Map<String, dynamic> data) {
    final String? priorityString = data['priority'];
    if (priorityString == null) return NotificationPriority.normal;

    return NotificationPriority.values.firstWhere(
      (e) => e.toString().split('.').last == priorityString,
      orElse: () => NotificationPriority.normal,
    );
  }
}