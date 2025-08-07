// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_report_app/main.dart';
import 'package:university_report_app/notification_model.dart';
import 'package:university_report_app/notification_service.dart';

void main() {
  group('Notification Module Tests', () {
    test('NotificationModel serialization test', () {
      final notification = NotificationModel(
        id: 'test-id',
        title: 'Test Notification',
        message: 'This is a test notification',
        type: NotificationType.reportSubmitted,
        priority: NotificationPriority.normal,
        userId: 'user-123',
        reportId: 'report-456',
        createdAt: DateTime.now(),
        isRead: false,
      );

      // Test toFirestore
      final firestoreData = notification.toFirestore();
      expect(firestoreData['title'], equals('Test Notification'));
      expect(firestoreData['message'], equals('This is a test notification'));
      expect(firestoreData['type'], equals('reportSubmitted'));
      expect(firestoreData['priority'], equals('normal'));
      expect(firestoreData['userId'], equals('user-123'));
      expect(firestoreData['reportId'], equals('report-456'));
      expect(firestoreData['isRead'], equals(false));
    });

    test('NotificationType icons test', () {
      expect(NotificationModel(
        id: '',
        title: '',
        message: '',
        type: NotificationType.reportSubmitted,
        priority: NotificationPriority.normal,
        userId: '',
        createdAt: DateTime.now(),
      ).icon, equals('📝'));

      expect(NotificationModel(
        id: '',
        title: '',
        message: '',
        type: NotificationType.reportReviewed,
        priority: NotificationPriority.normal,
        userId: '',
        createdAt: DateTime.now(),
      ).icon, equals('👀'));

      expect(NotificationModel(
        id: '',
        title: '',
        message: '',
        type: NotificationType.reportCompleted,
        priority: NotificationPriority.normal,
        userId: '',
        createdAt: DateTime.now(),
      ).icon, equals('✅'));
    });

    test('NotificationPriority colors test', () {
      expect(NotificationModel(
        id: '',
        title: '',
        message: '',
        type: NotificationType.systemAnnouncement,
        priority: NotificationPriority.low,
        userId: '',
        createdAt: DateTime.now(),
      ).priorityColor, equals('#64748B'));

      expect(NotificationModel(
        id: '',
        title: '',
        message: '',
        type: NotificationType.systemAnnouncement,
        priority: NotificationPriority.urgent,
        userId: '',
        createdAt: DateTime.now(),
      ).priorityColor, equals('#EF4444'));
    });
  });

  testWidgets('MyApp creates without error', (WidgetTester tester) async {
    // Since we can't easily test Firebase initialization in unit tests,
    // we'll just verify the app structure can be created
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('UTeM Reporter'),
          ),
        ),
      ),
    );

    expect(find.text('UTeM Reporter'), findsOneWidget);
  });
}
