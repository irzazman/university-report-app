import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'auth_page.dart';
import 'report_page.dart';
import 'student_report_detail_page.dart';
import 'ticket_history_page.dart';
import 'session_manager.dart';
import 'notifications_page.dart';
import 'notification_badge.dart';
import 'notification_settings_page.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

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
                          Icon(Icons.settings, color: const Color(0xFF0070F0)),
                          const SizedBox(width: 12),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0070F0),
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

                          // View Tickets option
                          _ModernSettingsOption(
                            icon: Icons.history_rounded,
                            label: "view_tickets".tr(),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const TicketHistoryPage(),
                                ),
                              );
                            },
                          ),

                          // Notification Settings option
                          _ModernSettingsOption(
                            icon: Icons.notifications_outlined,
                            label: "notification_settings.title".tr(),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationSettingsPage(),
                                ),
                              );
                            },
                          ),

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

                          // Logout option
                          _ModernSettingsOption(
                            icon: Icons.logout_rounded,
                            label: "logout".tr(),
                            color: Colors.red,
                            onTap: () async {
                              Navigator.of(context).pop();
                              SessionManager().endSession();
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const AuthPage(),
                                ),
                                (route) => false,
                              );
                            },
                          ),

                          const SizedBox(height: 20),
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
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            // Modern App Bar with tabs
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF0070F0),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0070F0), Color(0xFF64B5F6)],
                    ),
                  ),
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
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
                                        'Hello, Student! 👋',
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
                                  'Report campus issues easily',
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
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.report_problem, size: 18),
                            const SizedBox(width: 8),
                            Text("Report Issue"),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 18),
                            const SizedBox(width: 8),
                            Text("My Reports"),
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
                  // Report Issue Tab
                  _buildReportIssueTab(context),
                  // My Reports Tab
                  _buildMyReportsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Report Issue Tab with image-based category buttons
  Widget _buildReportIssueTab(BuildContext context) {
    return SingleChildScrollView(
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
                      .where(
                        'userEmail',
                        isEqualTo:
                            FirebaseAuth.instance.currentUser?.email ?? '',
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                int totalReports = 0;
                int pendingReports = 0;
                int completedReports = 0;
                if (snapshot.hasData) {
                  totalReports = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    if (status == 'Completed' || status == 'Resolved') {
                      completedReports++;
                    } else if (status == 'Pending') {
                      pendingReports++;
                    }
                  }
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Reports',
                      '$totalReports',
                      Icons.description_outlined,
                      const Color(0xFF6366F1),
                    ),
                    _buildStatItem(
                      'Pending',
                      '$pendingReports',
                      Icons.schedule_outlined,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Completed',
                      '$completedReports',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Report Categories Section
          Text(
            'Report an Issue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(
            height: 16,
          ), // Image-based Category Buttons (3 rows, greyscale)
          Column(
            children: [
              _buildImageCategoryCard(
                context,
                'Dormitory',
                'assets/dorm.jpg',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPage(category: 'Dorm'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildImageCategoryCard(
                context,
                'Faculty',
                'assets/faculty.jpg',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPage(category: 'Faculty'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildImageCategoryCard(
                context,
                'Campus',
                'assets/campus.jpg',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPage(category: 'Campus'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // My Reports Tab with report history
  Widget _buildMyReportsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildAllReportsSection(context),
        ],
      ),
    );
  }

  // Helper method to build stat items
  Widget _buildStatItem(
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

  // Helper method to build image-based category cards (full width, greyscale)
  Widget _buildImageCategoryCard(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0, // Red channel
                  0.2126, 0.7152, 0.0722, 0, 0, // Green channel
                  0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
                  0, 0, 0, 1, 0, // Alpha channel
                ]),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build all reports section for My Reports tab
  Widget _buildAllReportsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('reports')
              .where(
                'userEmail',
                isEqualTo: FirebaseAuth.instance.currentUser?.email ?? '',
              )
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reports yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit your first report to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp).toDate();
                final status = data['status'] ?? 'Pending';
                final category = data['category'] ?? 'Unknown';
                final description = data['description'] ?? 'No description';
                Color statusColor;
                switch (status) {
                  case 'Completed':
                  case 'Resolved':
                    statusColor = Colors.green;
                    break;
                  case 'In Progress':
                    statusColor = Colors.blue;
                    break;
                  default:
                    statusColor = Colors.orange;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    StudentReportDetailPage(reportData: data),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 48,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

// Modern settings option widget
class _ModernSettingsOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? trailing;

  const _ModernSettingsOption({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.trailing,
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
