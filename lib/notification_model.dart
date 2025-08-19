import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  reportSubmitted,
  reportReviewed,
  reportCompleted,
  reportAssigned,
  systemAnnouncement,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String userId;
  final String? reportId;
  final String assignedTo;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.userId,
    this.reportId,
    required this.assignedTo,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  // Convert from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.systemAnnouncement,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      userId: data['userId'] ?? '',
      reportId: data['reportId'],
      assignedTo: data['assignedTo'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'userId': userId,
      'reportId': reportId,
      'assignedTo': assignedTo,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'data': data,
    };
  }

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? userId,
    String? reportId,
    String? assignedTo,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      reportId: reportId ?? this.reportId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Get icon for notification type
  String get icon {
    switch (type) {
      case NotificationType.reportSubmitted:
        return '📝';
      case NotificationType.reportReviewed:
        return '👀';
      case NotificationType.reportCompleted:
        return '✅';
      case NotificationType.reportAssigned:
        return '📋';
      case NotificationType.systemAnnouncement:
        return '📢';
    }
  }

  // Get color for priority
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return '#64748B';
      case NotificationPriority.normal:
        return '#0070F0';
      case NotificationPriority.high:
        return '#F59E0B';
      case NotificationPriority.urgent:
        return '#EF4444';
    }
  }
}
