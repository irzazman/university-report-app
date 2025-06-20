import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'student_report_detail_page.dart';

class TicketHistoryPage extends StatelessWidget {
  const TicketHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Support Ticket History'), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('support_tickets')
                .where('userEmail', isEqualTo: userEmail)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 70, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No support tickets found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your support ticket history will appear here',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ticket = tickets[index].data() as Map<String, dynamic>;
              final status = ticket['status'] ?? 'Open';
              final createdAt = ticket['createdAt'] as Timestamp?;
              final reportId = ticket['reportId'] ?? '';
              final reportCategory = ticket['reportCategory'] ?? 'Unknown';
              final issueDescription = ticket['issueDescription'] ?? '';
              final responses = ticket['responses'] as List?;
              final lastResponseAt = ticket['lastResponseAt'] as Timestamp?;

              Color statusColor;
              switch (status.toLowerCase()) {
                case 'resolved':
                  statusColor = Colors.green;
                  break;
                case 'in progress':
                  statusColor = Colors.blue;
                  break;
                case 'open':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              String formattedDate =
                  createdAt != null
                      ? DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(createdAt.toDate())
                      : 'Unknown date';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#$reportId',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Category: $reportCategory',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submitted: $formattedDate',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (lastResponseAt != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Last Response: ${DateFormat('dd/MM/yyyy HH:mm').format(lastResponseAt.toDate())}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      Text(
                        'Issue:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issueDescription,
                        style: const TextStyle(fontSize: 14),
                      ),

                      // Display admin responses
                      if (responses != null && responses.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Admin Responses:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...responses.map((response) {
                          final author = response['author'] ?? 'Unknown';
                          final authorType =
                              response['authorType'] ?? 'unknown';
                          final message = response['message'] ?? '';
                          final responseTimestamp =
                              response['timestamp'] as Timestamp?;

                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  authorType == 'admin'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      authorType == 'admin'
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                      size: 14,
                                      color:
                                          authorType == 'admin'
                                              ? Colors.green
                                              : Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      author,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color:
                                            authorType == 'admin'
                                                ? Colors.green[700]
                                                : Colors.blue[700],
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      responseTimestamp != null
                                          ? DateFormat(
                                            'MMM d, h:mm a',
                                          ).format(responseTimestamp.toDate())
                                          : '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(message, style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
