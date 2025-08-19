import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'notification_service.dart';
import 'notification_model.dart';

class ReportStatusHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Update report status and send notifications
  static Future<void> updateReportStatus({
    required String reportId,
    required String newStatus,
    String? staffNote,
    String? resolutionNote,
    String? resolutionImageUrl,
  }) async {
    try {
      // Get current user (staff member)
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Get the report data first to know who to notify
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) throw Exception('Report not found');

      final reportData = reportDoc.data() as Map<String, dynamic>;
      final studentEmail = reportData['userEmail'] as String?;

      // Prepare update data
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': user.email,
      };

      // Add specific fields based on status
      switch (newStatus.toLowerCase()) {
        case 'under review':
          updateData['reviewedAt'] = FieldValue.serverTimestamp();
          updateData['reviewedBy'] = user.email;
          if (staffNote != null) {
            updateData['reviewNote'] = staffNote;
          }
          break;
        case 'in progress':
          updateData['assignedAt'] = FieldValue.serverTimestamp();
          updateData['assignedTo'] = user.email;
          break;
        case 'resolved':
        case 'completed':
          updateData['resolutionTimestamp'] = FieldValue.serverTimestamp();
          updateData['resolvedBy'] = user.email;
          if (resolutionNote != null) {
            updateData['resolutionNote'] = resolutionNote;
          }
          if (resolutionImageUrl != null) {
            updateData['resolutionImage'] = resolutionImageUrl;
          }
          break;
      }

      // Update the report
      await _firestore.collection('reports').doc(reportId).update(updateData);

      // Send notification to the student who submitted the report
      if (studentEmail != null) {
        await _sendStatusUpdateNotification(
          reportId: reportId,
          newStatus: newStatus,
          studentEmail: studentEmail,
          category: reportData['category'] ?? 'Unknown',
        );
      }

      print('Report status updated to: $newStatus');
    } catch (e) {
      print('Error updating report status: $e');
      throw e;
    }
  }

  // Send notification to student about status update
  static Future<void> _sendStatusUpdateNotification({
    required String reportId,
    required String newStatus,
    required String studentEmail,
    required String category,
  }) async {
    try {
      // Get student user ID from email
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: studentEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print('Student user not found for email: $studentEmail');
        return;
      }

      final studentUserId = userSnapshot.docs.first.id;

      // Determine notification type and message based on status
      NotificationType notificationType;
      String title;
      String message;

      switch (newStatus.toLowerCase()) {
        case 'under review':
          notificationType = NotificationType.reportReviewed;
          title = 'notifications.report_reviewed'.tr();
          message = 'Your $category report is now under review by our staff.';
          break;
        case 'in progress':
          notificationType = NotificationType.reportReviewed;
          title = 'Report In Progress';
          message = 'Work has started on your $category report.';
          break;
        case 'resolved':
        case 'completed':
          notificationType = NotificationType.reportCompleted;
          title = 'notifications.report_completed'.tr();
          message =
              'Your $category report has been resolved. Thank you for your patience!';
          break;
        default:
          notificationType = NotificationType.systemAnnouncement;
          title = 'Report Status Updated';
          message =
              'Your $category report status has been updated to: $newStatus';
      }

      // Create the notification
      await _notificationService.createNotification(
        title: title,
        message: message,
        type: notificationType,
        userId: studentUserId,
        assignedTo: studentUserId,
        reportId: reportId,
        priority: NotificationPriority.normal,
        data: {
          'reportId': reportId,
          'newStatus': newStatus,
          'category': category,
        },
      );

      print('Status update notification sent to student: $studentEmail');
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  // Convenience method to mark report as reviewed
  static Future<void> markAsReviewed(String reportId, {String? note}) async {
    await updateReportStatus(
      reportId: reportId,
      newStatus: 'Under Review',
      staffNote: note,
    );
  }

  // Convenience method to mark report as in progress
  static Future<void> markAsInProgress(String reportId) async {
    await updateReportStatus(
      reportId: reportId,
      newStatus: 'In Progress',
    );
  }

  // Convenience method to mark report as completed
  static Future<void> markAsCompleted(
    String reportId, {
    String? resolutionNote,
    String? resolutionImageUrl,
  }) async {
    await updateReportStatus(
      reportId: reportId,
      newStatus: 'Resolved',
      resolutionNote: resolutionNote,
      resolutionImageUrl: resolutionImageUrl,
    );
  }
}
