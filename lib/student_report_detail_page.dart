import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class StudentReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const StudentReportDetailPage({super.key, required this.reportData});

  @override
  State<StudentReportDetailPage> createState() =>
      _StudentReportDetailPageState();
}

class _StudentReportDetailPageState extends State<StudentReportDetailPage> {
  final TextEditingController _ticketController = TextEditingController();
  bool _isSubmittingTicket = false;

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.reportData['status'] ?? 'Pending').toString();

    IconData icon;
    Color iconColor;
    switch (status.toLowerCase()) {
      case 'pending':
        icon = Icons.hourglass_empty;
        iconColor = Colors.amber;
        break;
      case 'in progress':
        icon = Icons.autorenew;
        iconColor = Colors.blue;
        break;
      case 'resolved':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status at the top
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Display report fields in specific order based on category
            ..._buildOrderedFields(widget.reportData),

            // Google Maps for Campus reports
            if (widget.reportData['category'] == 'Campus' &&
                widget.reportData['location'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.reportData['location']['latitude'],
                      widget.reportData['location']['longitude'],
                    ),
                    zoom: 17,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('report_location'),
                      position: LatLng(
                        widget.reportData['location']['latitude'],
                        widget.reportData['location']['longitude'],
                      ),
                      infoWindow: InfoWindow(
                        title: 'Report Location',
                        snippet: widget.reportData['description'] ?? '',
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      () => _navigateToLocation(
                        context,
                        widget.reportData['location']['latitude'],
                        widget.reportData['location']['longitude'],
                      ),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B9AE1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (widget.reportData['imageUrl'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Photo Evidence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(widget.reportData['imageUrl']),
              ),
            ], // Display resolution information if available
            if (widget.reportData['resolutionImage'] != null) ...[
              const SizedBox(height: 24),
              Text(
                'Resolution Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.green[700]),
                        SizedBox(width: 4),
                        Text(
                          'Resolved by: ${widget.reportData['resolvedBy'] ?? 'Unknown'}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Completed: ${_formatTimestamp(widget.reportData['resolutionTimestamp'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (widget.reportData['resolutionNote']?.isNotEmpty ??
                        false) ...[
                      Text(
                        'Resolution Note:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(widget.reportData['resolutionNote'] ?? ''),
                      SizedBox(height: 12),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.reportData['resolutionImage'],
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Support Ticket System - Show for unresolved reports
            if (status.toLowerCase() != 'resolved') ...[
              const SizedBox(height: 24),
              _buildSupportTicketSection(),
            ],

            // Display existing support tickets
            _buildExistingTicketsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTicketSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'Need Follow-up Support?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If your issue is taking longer than expected or you need updates, create a support ticket below:',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ticketController,
            decoration: InputDecoration(
              labelText: 'Describe your follow-up request',
              hintText:
                  'e.g., Still waiting for repair, need urgent attention, etc.',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingTicket ? null : _submitSupportTicket,
              icon:
                  _isSubmittingTicket
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(Icons.send),
              label: Text(
                _isSubmittingTicket ? 'Submitting...' : 'Submit Support Ticket',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingTicketsSection() {
    final reportId = widget.reportData['reportId'];
    if (reportId == null) return SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('support_tickets')
              .where('reportId', isEqualTo: reportId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox();
        }

        final tickets = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Support Tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...tickets.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildTicketCard(data);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticketData) {
    final status = ticketData['status'] ?? 'Open';
    final reportStatus = ticketData['reportStatus'] ?? 'Unknown';
    final createdAt = ticketData['createdAt'] as Timestamp?;
    final issueDescription = ticketData['issueDescription'] ?? '';
    final responses = ticketData['responses'] as List?;
    final lastResponseAt = ticketData['lastResponseAt'] as Timestamp?;

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

    Color reportStatusColor;
    switch (reportStatus.toLowerCase()) {
      case 'resolved':
        reportStatusColor = Colors.green;
        break;
      case 'in progress':
        reportStatusColor = Colors.blue;
        break;
      case 'pending':
        reportStatusColor = Colors.orange;
        break;
      default:
        reportStatusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Support Ticket',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Report Status: ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: reportStatusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reportStatus,
                  style: TextStyle(
                    color: reportStatusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Issue: $issueDescription', style: TextStyle(fontSize: 14)),
          SizedBox(height: 8),
          Text(
            'Created: ${createdAt != null ? DateFormat('MMM d, yyyy, h:mm a').format(createdAt.toDate()) : 'Unknown'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          if (lastResponseAt != null) ...[
            SizedBox(height: 4),
            Text(
              'Last Response: ${DateFormat('MMM d, yyyy, h:mm a').format(lastResponseAt.toDate())}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],

          // Display admin responses
          if (responses != null && responses.isNotEmpty) ...[
            Divider(height: 24),
            Text(
              'Admin Responses:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            ...responses.map((response) {
              final author = response['author'] ?? 'Unknown';
              final authorType = response['authorType'] ?? 'unknown';
              final message = response['message'] ?? '';
              final responseTimestamp = response['timestamp'] as Timestamp?;

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      authorType == 'admin'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        authorType == 'admin'
                            ? Colors.green.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                  ),
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
                          size: 16,
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
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(message, style: TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildOrderedFields(Map<String, dynamic> reportData) {
    final category = reportData['category']?.toString().toLowerCase();
    List<Widget> fields = [];

    List<String> fieldOrder = [];

    // Define field order based on category
    if (category == 'faculty') {
      fieldOrder = [
        'category',
        'faculty',
        'floor',
        'room',
        'description',
        'type',
        'timestamp',
        'userEmail',
      ];
    } else if (category == 'dormitory' || category == 'dorm') {
      fieldOrder = [
        'category',
        'college',
        'block',
        'floor',
        'house',
        'room',
        'description',
        'type',
        'timestamp',
        'userEmail',
      ];
    } else if (category == 'campus') {
      fieldOrder = [
        'category',
        'description',
        'type',
        'timestamp',
        'userEmail',
      ];
    } else {
      // Default order for unknown categories
      fieldOrder = [
        'category',
        'description',
        'type',
        'timestamp',
        'userEmail',
      ];
    }

    // Build fields in the specified order
    for (String fieldKey in fieldOrder) {
      Widget? field = _buildField(fieldKey, reportData);
      if (field != null) {
        fields.add(field);
      }
    }

    return fields;
  }

  Widget? _buildField(String key, Map<String, dynamic> reportData) {
    String? value;
    String label = '';

    // Handle special fields
    switch (key) {
      case 'timestamp':
        if (reportData['timestamp'] != null) {
          value = _formatTimestamp(reportData['timestamp']);
          label = 'Submitted At';
        }
        break;
      case 'userEmail':
        if (reportData['userEmail'] != null) {
          value = reportData['userEmail'].toString();
          label = 'Submitted By';
        }
        break;
      case 'type':
        if (reportData['type'] != null) {
          value = reportData['type'].toString();
          label = 'Issue Type';
        }
        break;
      default:
        if (reportData[key] != null && reportData[key].toString().isNotEmpty) {
          value = reportData[key].toString();
          label = _formatFieldLabel(key);
        }
        break;
    }

    if (value != null && label.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
        ),
      );
    }

    return null;
  }

  Future<void> _submitSupportTicket() async {
    if (_ticketController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please describe your follow-up request')),
      );
      return;
    }

    setState(() {
      _isSubmittingTicket = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final reportId = widget.reportData['reportId'];
      final reportCategory = widget.reportData['category'];
      final reportStatus = widget.reportData['status'] ?? 'Pending';

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'reportId': reportId,
        'reportCategory': reportCategory,
        'reportStatus': reportStatus, // Add the current report status
        'userEmail': user?.email ?? '',
        'issueDescription': _ticketController.text.trim(),
        'status': 'Open',
        'createdAt': Timestamp.now(),
      });

      _ticketController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Support ticket submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting support ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit support ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingTicket = false;
      });
    }
  }

  String _formatFieldLabel(String key) {
    switch (key) {
      case 'userEmail':
        return 'Submitted By';
      case 'type':
        return 'Issue Type';
      case 'reporterPhone':
        return 'Reporter Phone';
      case 'reporterCountryCode':
        return 'Country Code';
      case 'reporterFullPhone':
        return 'Reporter Contact';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp.millisecondsSinceEpoch,
    );
    return DateFormat('MMM d, yyyy, h:mm a').format(date);
  }

  Future<void> _navigateToLocation(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final url =
        Platform.isIOS
            ? 'http://maps.apple.com/?daddr=$latitude,$longitude'
            : 'geo:$latitude,$longitude?q=$latitude,$longitude';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        final googleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
        if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
          await launchUrl(
            Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch map application';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map application: $e')),
      );
    }
  }
}
