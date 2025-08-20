import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const StaffReportDetailPage({super.key, required this.reportData});

  @override
  State<StaffReportDetailPage> createState() => _StaffReportDetailPageState();
}

class _StaffReportDetailPageState extends State<StaffReportDetailPage> {
  bool isSubmitting = false;
  File? resolutionImage;
  final TextEditingController noteController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final reportData = widget.reportData;
    final status = (reportData['status'] ?? 'Pending').toString();
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserEmail = currentUser?.email;
    final currentUserUid = currentUser?.uid;
    final assignedToRaw = reportData['assignedTo'];
    // assignedTo in Firestore may be stored as email or uid depending on server/client logic.
    // Consider both when deciding whether this staff is assigned to the report.
    final bool isAssignedToUser = assignedToRaw != null &&
        (assignedToRaw.toString() == currentUserEmail ||
            assignedToRaw.toString() == currentUserUid);

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
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          // Add staff note button - smaller and positioned at top right          if (status.toLowerCase() == 'in progress' && isAssignedToUser)
          IconButton(
            icon: const Icon(Icons.note_add, size: 20),
            tooltip: 'Add Staff Note',
            onPressed: _showAddNoteDialog,
          ),
        ],
      ),
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
            ..._buildOrderedFields(reportData),

            // WhatsApp Contact Button
            if (reportData['reporterFullPhone'] != null &&
                reportData['reporterFullPhone'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF25D366), const Color(0xFF128C7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _launchWhatsAppAlternative(
                    reportData['reporterFullPhone'].toString(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    'Contact Reporter via WhatsApp',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone: ${reportData['reporterFullPhone']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],

            // Google Maps for Campus reports
            if (reportData['category'] == 'Campus' &&
                reportData['location'] != null) ...[
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
                      reportData['location']['latitude'],
                      reportData['location']['longitude'],
                    ),
                    zoom: 17,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('report_location'),
                      position: LatLng(
                        reportData['location']['latitude'],
                        reportData['location']['longitude'],
                      ),
                      infoWindow: InfoWindow(
                        title: 'Report Location',
                        snippet: reportData['description'] ?? '',
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
                  onPressed: () => _navigateToLocation(
                    reportData['location']['latitude'],
                    reportData['location']['longitude'],
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

            if (reportData['imageUrl'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Photo Evidence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(reportData['imageUrl']),
              ),
            ],

            // Display staff notes section if available
            if (reportData['staffNotes'] != null &&
                (reportData['staffNotes'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Staff Work Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: (reportData['staffNotes'] as List).length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = (reportData['staffNotes'] as List)[index];
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                note['staffEmail'] ?? 'Staff',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Spacer(),
                              Text(
                                _formatTimestamp(note['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(note['note'] ?? ''),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Display resolution information if available
            if (reportData['resolutionImage'] != null) ...[
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
                    if (reportData['pendingReview'] == true)
                      Chip(
                        label: Text('Pending Admin Review'),
                        backgroundColor: Colors.amber.withOpacity(0.2),
                        labelStyle: TextStyle(color: Colors.amber[800]),
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.green[700]),
                        SizedBox(width: 4),
                        Text(
                          'Resolved by: ${reportData['resolvedBy'] ?? 'Unknown'}',
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
                          'Completed: ${_formatTimestamp(reportData['resolutionTimestamp'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (reportData['resolutionNote']?.isNotEmpty ?? false) ...[
                      Text(
                        'Resolution Note:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(reportData['resolutionNote'] ?? ''),
                      SizedBox(height: 12),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        reportData['resolutionImage'],
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
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

            // Add a prominent resolution button for staff assigned to this task
            if (status.toLowerCase() == 'in progress' && isAssignedToUser) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Complete This Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When you have fixed the issue, submit evidence by marking it as resolved:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.photo_camera),
                            label: Text('Take Photo'),
                            onPressed: () => _pickImage(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                            onPressed: () => _pickImage(ImageSource.gallery),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (resolutionImage != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          resolutionImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note_alt,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Resolution Notes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please describe what was fixed or replaced',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: noteController,
                              decoration: InputDecoration(
                                labelText: 'Resolution Notes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.blue[700]!,
                                    width: 2,
                                  ),
                                ),
                                hintText: 'Describe what was fixed/replaced',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitResolution,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Submit for Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        'Please take a photo to document the completed work',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
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
        'reporterFullPhone',
        'assignedAt',
        'reviewedAt',
        'reviewedBy',
        'reviewNote',
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
        'reporterFullPhone',
        'assignedAt',
        'reviewedAt',
        'reviewedBy',
        'reviewNote',
      ];
    } else if (category == 'campus') {
      fieldOrder = [
        'category',
        'description',
        'type',
        'timestamp',
        'userEmail',
        'reporterFullPhone',
        'assignedAt',
        'reviewedAt',
        'reviewedBy',
        'reviewNote',
      ];
    } else {
      // Default order for unknown categories
      fieldOrder = [
        'category',
        'description',
        'type',
        'timestamp',
        'userEmail',
        'reporterFullPhone',
        'assignedAt',
        'reviewedAt',
        'reviewedBy',
        'reviewNote',
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
      case 'assignedAt':
        if (reportData['assignedAt'] != null) {
          value = _formatTimestamp(reportData['assignedAt']);
          label = 'Assigned At';
        }
        break;
      case 'reviewedAt':
        if (reportData['reviewedAt'] != null) {
          value = _formatTimestamp(reportData['reviewedAt']);
          label = 'Reviewed At';
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
      case 'reporterFullPhone':
        if (reportData['reporterFullPhone'] != null &&
            reportData['reporterFullPhone'].toString().isNotEmpty) {
          value = reportData['reporterFullPhone'].toString();
          label = 'Reporter Contact';
        }
        break;
      case 'reviewedBy':
        if (reportData['reviewedBy'] != null) {
          value = reportData['reviewedBy'].toString();
          label = 'Reviewed By';
        }
        break;
      case 'reviewNote':
        if (reportData['reviewNote'] != null &&
            reportData['reviewNote'].toString().isNotEmpty) {
          value = reportData['reviewNote'].toString();
          label = 'Review Note';
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
          maxLines: key == 'reviewNote' ? 3 : 1,
        ),
      );
    }

    return null;
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

  Future<void> _navigateToLocation(double latitude, double longitude) async {
    final url = Platform.isIOS
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

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Staff Work Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add details about work performed or parts needed',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Work Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveWorkNote,
            child: Text('Save Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkNote() async {
    if (noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a note')));
      return;
    }

    try {
      Navigator.pop(context);
      final reportId = widget.reportData['reportId'];

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'staffNotes': FieldValue.arrayUnion([
          {
            'note': noteController.text.trim(),
            'timestamp': Timestamp.now(),
            'staffEmail': FirebaseAuth.instance.currentUser?.email,
          },
        ]),
      });

      noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error adding note: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        resolutionImage = File(image.path);
      });
    }
  }

  Future<void> _submitResolution() async {
    if (resolutionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a photo to submit for review')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Submitting resolution...'),
            ],
          ),
        ),
      );

      final reportId = widget.reportData['reportId'];
      final fileName =
          'resolution_${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
            'resolutions/$fileName',
          );

      final uploadTask = storageRef.putFile(resolutionImage!);
      await uploadTask.whenComplete(() {});

      final imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'Pending Review',
        'resolutionImage': imageUrl,
        'resolutionNote': noteController.text.trim(),
        'resolutionTimestamp': FieldValue.serverTimestamp(),
        'resolvedBy': FirebaseAuth.instance.currentUser?.email,
      });

      Navigator.pop(context); // Close loading dialog

      setState(() {
        resolutionImage = null;
        isSubmitting = false;
      });
      noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Work submitted for admin review successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to previous page
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print("Error submitting resolution: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting resolution: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    try {
      // Remove any non-numeric characters except + from phone number
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Ensure the number starts with + for international format
      if (!cleanedNumber.startsWith('+')) {
        cleanedNumber = '+$cleanedNumber';
      }

      // Remove the + for some URL schemes
      String numberWithoutPlus = cleanedNumber.replaceFirst('+', '');

      final String message = Uri.encodeComponent(
        'Hello! I am contacting you regarding your recent report submitted to UTeM Reporter. '
        'Is this a good time to discuss the issue?',
      );

      // Try multiple WhatsApp URL schemes
      List<String> whatsappUrls = [
        'whatsapp://send?phone=$numberWithoutPlus&text=$message',
        'https://wa.me/$numberWithoutPlus?text=$message',
        'https://api.whatsapp.com/send?phone=$numberWithoutPlus&text=$message',
      ];

      bool launched = false;

      // Try each WhatsApp URL
      for (String url in whatsappUrls) {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            launched = true;
            break;
          }
        } catch (e) {
          print('Failed to launch $url: $e');
          continue;
        }
      }

      // If WhatsApp fails, try phone call
      if (!launched) {
        try {
          final String phoneUrl = 'tel:$cleanedNumber';
          if (await canLaunchUrl(Uri.parse(phoneUrl))) {
            await launchUrl(
              Uri.parse(phoneUrl),
              mode: LaunchMode.externalApplication,
            );
            launched = true;
          }
        } catch (e) {
          print('Failed to launch phone: $e');
        }
      }

      // If nothing worked, show instructions
      if (!launched) {
        if (mounted) {
          _showContactInstructions(cleanedNumber);
        }
      }
    } catch (e) {
      print('Error in _launchWhatsApp: $e');
      if (mounted) {
        _showContactInstructions(phoneNumber);
      }
    }
  }

  // Alternative method for launching WhatsApp using Intent (Android-specific)
  Future<void> _launchWhatsAppAlternative(String phoneNumber) async {
    try {
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanedNumber.startsWith('+')) {
        cleanedNumber = '+$cleanedNumber';
      }

      final String message =
          'Hello! I am contacting you regarding your recent report submitted to UTeM Reporter. Is this a good time to discuss the issue?';

      // Try the direct WhatsApp scheme without encoding
      String whatsappUrl =
          'whatsapp://send?phone=${cleanedNumber.replaceFirst('+', '')}&text=${Uri.encodeComponent(message)}';

      await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Alternative WhatsApp launch failed: $e');
      // Fall back to main method
      await _launchWhatsApp(phoneNumber);
    }
  }

  void _showContactInstructions(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Reporter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unable to open WhatsApp automatically. You can contact the reporter using:',
              ),
              const SizedBox(height: 12),
              SelectableText(
                'Phone: $phoneNumber',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Manual steps:'),
              const Text('1. Copy the phone number above'),
              const Text('2. Open WhatsApp manually'),
              const Text('3. Start a new chat with this number'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Copy to clipboard would require additional package
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phone number: $phoneNumber'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: const Text('Show Number'),
            ),
          ],
        );
      },
    );
  }
}
