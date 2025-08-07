import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'auth_page.dart';
import 'staff_report_detail_page.dart';
import 'staff_review_detail_page.dart';
import 'auth_token_service.dart';
import 'session_manager.dart';
import 'notifications_page.dart';
import 'notification_badge.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  static void _showSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 340,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F2FF),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, color: const Color(0xFF3B9AE1)),
                          const SizedBox(width: 12),
                          Text(
                            'Staff Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B9AE1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Options
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),

                          // Language option
                          _ModernSettingsOption(
                            icon: Icons.language_rounded,
                            label: "language".tr(),
                            trailing: Switch(
                              value: context.locale.languageCode == 'ms',
                              onChanged: (isMs) {
                                context.setLocale(
                                  isMs
                                      ? const Locale('ms')
                                      : const Locale('en'),
                                );
                              },
                              activeColor: theme.colorScheme.primary,
                            ),
                          ),

                          const Divider(indent: 56, endIndent: 20),

                          // Log Out option
                          _ModernSettingsOption(
                            icon: Icons.logout_rounded,
                            label: "logout".tr(),
                            color: theme.colorScheme.error,
                            onTap: () async {
                              try {
                                await AuthTokenService.clearToken();
                                SessionManager().endSession();
                                await FirebaseAuth.instance.signOut();

                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const AuthPage(),
                                  ),
                                );
                              } catch (e) {
                                print("Error during logout: $e");
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const AuthPage(),
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF6366F1),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 60,
                        bottom: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Welcome, Staff! 👨‍💼',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage campus reports',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: NotificationIconButton(
                              icon: Icons.notifications_outlined,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                              ),
                              tooltip: 'Settings',
                              onPressed: () => _showSettingsDialog(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xFF6366F1),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF6366F1),
                      indicatorWeight: 3,
                      isScrollable: false,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "My Tasks",
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Review",
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "History",
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  children: [
                    // My Tasks Tab
                    _buildModernMyTasksTab(context),
                    // Admin Review Tab
                    _buildAdminReviewTab(context),
                    // History Tab
                    _buildModernHistoryTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMyTasksTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('reports')
                      .where('status', isEqualTo: 'In Progress')
                      .snapshots(),
              builder: (context, snapshot) {
                int inProgressReports = 0;
                int todayReports = 0;

                if (snapshot.hasData) {
                  final today = DateTime.now();
                  final todayStart = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );

                  inProgressReports = snapshot.data!.docs.length;

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp).toDate();

                    if (timestamp.isAfter(todayStart)) {
                      todayReports++;
                    }
                  }
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildStaffStatItem(
                        'In Progress',
                        inProgressReports.toString(),
                        Icons.assignment_outlined,
                        const Color(0xFF6366F1),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildStaffStatItem(
                        'Today',
                        todayReports.toString(),
                        Icons.today,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Task Categories
          Expanded(child: _buildCategorizedTasksSection(context)),
        ],
      ),
    );
  }

  Widget _buildModernHistoryTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildCompletedReportsSection(context)),
        ],
      ),
    );
  }

  Widget _buildAdminReviewTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports for Admin Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(child: _buildAdminReviewReportsSection(context)),
        ],
      ),
    );
  }

  // Helper method to build staff stat items
  Widget _buildStaffStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Build categorized tasks section
  Widget _buildCategorizedTasksSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('reports')
              .where('status', isEqualTo: 'In Progress')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_alt, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No in-progress tasks assigned to you",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildStaffReportCard(context, doc, data, false),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // Build completed reports section
  Widget _buildCompletedReportsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('reports')
              .where('status', whereIn: ['Completed', 'Resolved'])
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Completed Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reports you complete will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildStaffReportCard(context, doc, data, true),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // Build admin review reports section
  Widget _buildAdminReviewReportsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('reports')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Reports for Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All reports have been reviewed and processed',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } // Filter reports that need review
        final reviewReports =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] == 'Pending Review') ||
                  (data['status'] == 'Under Review');
            }).toList();

        if (reviewReports.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Reports for Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All reports have been reviewed and processed',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                reviewReports.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAdminReviewCard(context, doc, data),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // Helper method to build staff report cards
  Widget _buildStaffReportCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isCompleted,
  ) {
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final timeAgo = _getTimeAgo(timestamp);
    final status = data['status'] ?? 'Unknown';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffReportDetailPage(reportData: data),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with category and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        data['category'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(data['category']),
                          size: 14,
                          color: _getCategoryColor(data['category']),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data['category'] ?? 'General',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(data['category']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isCompleted
                                ? Colors.green.shade200
                                : Colors.blue.shade200,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            isCompleted
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Report description
              Text(
                data['description'] ?? 'No Description',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Bottom row with time information
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reported: $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  if (data['assignedAt'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_ind,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned: ${_getTimeAgo((data['assignedAt'] as Timestamp).toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (data['reassignedAt'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reassigned: ${_getTimeAgo((data['reassignedAt'] as Timestamp).toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build admin review card
  Widget _buildAdminReviewCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final timeAgo = _getTimeAgo(timestamp);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffReviewDetailPage(reportData: data),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with category
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        data['category'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(data['category']),
                          size: 14,
                          color: _getCategoryColor(data['category']),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data['category'] ?? 'General',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(data['category']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Report description
              Text(
                data['description'] ?? 'No Description',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Bottom row with status, time, and action button
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          data['status'] == 'Pending Review'
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            data['status'] == 'Pending Review'
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      data['status'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            data['status'] == 'Pending Review'
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Time information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reported: $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (data['assignedAt'] != null) ...[
                          Text(
                            'Assigned: ${_getTimeAgo((data['assignedAt'] as Timestamp).toDate())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        if (data['reassignedAt'] != null) ...[
                          Text(
                            'Reassigned: ${_getTimeAgo((data['reassignedAt'] as Timestamp).toDate())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Quick action button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    StaffReviewDetailPage(reportData: data),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF6366F1),
                      ),
                      tooltip: 'Review Report',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get category color
  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'dormitory':
      case 'dorm':
        return const Color(0xFFEF4444);
      case 'faculty':
        return const Color(0xFF10B981);
      case 'campus':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF6366F1);
    }
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'dormitory':
      case 'dorm':
        return Icons.home;
      case 'faculty':
        return Icons.school;
      case 'campus':
        return Icons.location_city;
      default:
        return Icons.report;
    }
  }

  // Helper method to get time ago string
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Modern Settings Option class
class _ModernSettingsOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;

  const _ModernSettingsOption({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;
    final textColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            trailing ??
                (onTap != null
                    ? Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    )
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}
