import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'notification_model.dart';
import 'report_status_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class for testing and demonstrating notification functionality
class NotificationTestUtils {
  static final NotificationService _notificationService = NotificationService();

  /// Create a test notification for the current user
  static Future<void> createTestNotification({
    required BuildContext context,
    NotificationType type = NotificationType.systemAnnouncement,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage(context, 'No user logged in');
        return;
      }

      await _notificationService.createNotification(
        title: 'Test Notification',
        message:
            'This is a test notification to verify the notification system is working properly.',
        type: type,
        userId: user.uid,
        reportId: null,
        assignedTo: user.uid,
        priority: priority,
        data: {
          'isTest': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _showMessage(context, 'Test notification created successfully!');
    } catch (e) {
      _showMessage(context, 'Error creating test notification: $e');
    }
  }

  /// Create test notifications for all notification types
  static Future<void> createAllTestNotifications(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage(context, 'No user logged in');
        return;
      }

      final notifications = [
        {
          'type': NotificationType.reportSubmitted,
          'title': 'Report Submitted Successfully',
          'message':
              'Your campus report has been submitted and is being processed.',
          'priority': NotificationPriority.normal,
        },
        {
          'type': NotificationType.reportReviewed,
          'title': 'Report Under Review',
          'message': 'Your report is now being reviewed by our staff team.',
          'priority': NotificationPriority.normal,
        },
        {
          'type': NotificationType.reportCompleted,
          'title': 'Report Completed',
          'message': 'Great news! Your report has been resolved successfully.',
          'priority': NotificationPriority.high,
        },
        {
          'type': NotificationType.reportAssigned,
          'title': 'New Report Assigned',
          'message': 'A new campus report has been assigned to you for review.',
          'priority': NotificationPriority.high,
        },
        {
          'type': NotificationType.systemAnnouncement,
          'title': 'System Maintenance',
          'message':
              'The system will undergo maintenance tonight from 12AM to 3AM.',
          'priority': NotificationPriority.urgent,
        },
      ];

      for (var notification in notifications) {
        await _notificationService.createNotification(
          title: notification['title'] as String,
          message: notification['message'] as String,
          type: notification['type'] as NotificationType,
          userId: user.uid,
          reportId: null,
          assignedTo: user.uid,
          priority: notification['priority'] as NotificationPriority,
          data: {
            'isTest': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      _showMessage(context, 'All test notifications created successfully!');
    } catch (e) {
      _showMessage(context, 'Error creating test notifications: $e');
    }
  }

  /// Test report status update notifications
  static Future<void> testReportStatusUpdate({
    required BuildContext context,
    required String reportId,
    required String newStatus,
  }) async {
    try {
      await ReportStatusHelper.updateReportStatus(
        reportId: reportId,
        newStatus: newStatus,
        staffNote: 'Test status update from notification test utilities',
      );

      _showMessage(context, 'Report status updated and notification sent!');
    } catch (e) {
      _showMessage(context, 'Error updating report status: $e');
    }
  }

  /// Clear all notifications for current user (for testing)
  static Future<void> clearAllNotifications(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage(context, 'No user logged in');
        return;
      }

      await _notificationService.markAllAsRead();
      _showMessage(context, 'All notifications marked as read');
    } catch (e) {
      _showMessage(context, 'Error clearing notifications: $e');
    }
  }

  /// Show a debug panel with notification testing options
  static void showNotificationTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Testing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a test option:'),
            const SizedBox(height: 16),
            _buildTestButton(
              context,
              'Create Test Notification',
              () => createTestNotification(context: context),
            ),
            _buildTestButton(
              context,
              'Create All Test Types',
              () => createAllTestNotifications(context),
            ),
            _buildTestButton(
              context,
              'High Priority Test',
              () => createTestNotification(
                context: context,
                type: NotificationType.reportCompleted,
                priority: NotificationPriority.urgent,
              ),
            ),
            _buildTestButton(
              context,
              'Mark All as Read',
              () => clearAllNotifications(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTestButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed();
          },
          child: Text(label),
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Extension to add notification testing to any widget
extension NotificationTesting on BuildContext {
  void showNotificationTests() {
    NotificationTestUtils.showNotificationTestDialog(this);
  }
}
