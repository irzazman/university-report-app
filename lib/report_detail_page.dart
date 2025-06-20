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

class ReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailPage({super.key, required this.reportData});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  bool isSubmitting = false;
  File? resolutionImage;
  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final reportData = widget.reportData;
    final status = (reportData['status'] ?? 'Pending').toString();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final bool isAssignedToUser = currentUserEmail == reportData['assignedTo'];
    final bool canMarkAsResolved =
        status.toLowerCase() != 'resolved' && isAssignedToUser;

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
          // Add staff note button - smaller and positioned at top right
          if (status.toLowerCase() == 'in progress' && isAssignedToUser)
            IconButton(
              icon: const Icon(Icons.note_add, size: 20),
              tooltip: 'Add Staff Note',
              onPressed: _showAddNoteDialog,
            ),
          if (canMarkAsResolved)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.green),
              tooltip: 'Mark as Resolved',
              onPressed: _showResolutionDialog,
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
            ...reportData.entries.map((entry) {
              if (entry.key == 'status' ||
                  entry.key == 'timestamp' ||
                  entry.key == 'imageUrl' ||
                  entry.key == 'location' ||
                  entry.key == 'assignedTo' ||
                  entry.key == 'assignedStaffDepartment' ||
                  entry.key == 'assignedStaffName' ||
                  entry.key == 'assignedAt') {
                // Handle assignedAt separately
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  initialValue: entry.value?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText:
                        entry.key[0].toUpperCase() + entry.key.substring(1),
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
              );
            }),

            // Display cleaned assignedAt timestamp if available
            if (reportData['assignedAt'] != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  initialValue: _formatTimestamp(reportData['assignedAt']),
                  decoration: InputDecoration(
                    labelText: 'Assigned At',
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
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
                  onPressed:
                      () => _navigateToLocation(
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

            if (reportData['imageUrl'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image.network(reportData['imageUrl']),
              ),
            // Display staff notes section if available
            if (reportData['staffNotes'] != null &&
                (reportData['staffNotes'] as List).isNotEmpty) ...{
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
            },
            // Display resolution information if available
            if (reportData['resolutionImage'] != null) ...{
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
                    Text(
                      'Resolved by: ${reportData['resolvedBy'] ?? 'Unknown'}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'On: ${_formatTimestamp(reportData['resolutionTimestamp'])}',
                      style: TextStyle(color: Colors.grey[600]),
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
            },
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showResolutionDialog,
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
                        'Or submit without photo',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _showResolutionDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Mark as Resolved',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      // Remove the floating action button since we moved it to app bar
    );
  }

  // Show dialog to add staff notes
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  // Save the work note to Firestore
  Future<void> _saveWorkNote() async {
    if (noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a note')));
      return;
    }

    try {
      Navigator.pop(context); // Close dialog
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

  // Show dialog for resolution submission with photo upload
  void _showResolutionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Mark as Resolved'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm that you have fixed this issue?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please provide evidence of the completed work:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  if (resolutionImage != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(resolutionImage!, height: 200),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              resolutionImage = null;
                            });
                            Navigator.pop(context);
                            _showResolutionDialog();
                          },
                          child: Text('Remove Photo'),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 48,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Documentation required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Please take or select a photo of the completed repair',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.photo_camera),
                        label: Text('Camera'),
                        onPressed: () => _pickImage(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.photo_library),
                        label: Text('Gallery'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Resolution Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Describe what was fixed/replaced',
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Note: This will be sent to admin for review and approval',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  resolutionImage = null;
                  noteController.clear();
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: resolutionImage == null ? null : _submitResolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text('Submit for Review'),
              ),
            ],
          ),
    );
  }

  // Pick image from camera or gallery
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
      // Don't immediately show the dialog - let user see the image first
    }
  }

  // Submit resolution with photo and notes
  Future<void> _submitResolution() async {
    if (resolutionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a photo of the fixed issue')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    Navigator.pop(context); // Close the dialog

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Submitting resolution...'),
                ],
              ),
            ),
      );

      // Upload image to Firebase Storage
      final reportId = widget.reportData['reportId'];
      final fileName =
          'resolution_${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'resolutions/$fileName',
      );

      // Upload file
      final uploadTask = storageRef.putFile(resolutionImage!);
      await uploadTask.whenComplete(() {});

      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();

      // Update report status in Firestore
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
            'pendingReview': true, // Needs admin review
            'resolutionImage': imageUrl,
            'resolutionNote': noteController.text.trim(),
            'resolutionTimestamp': FieldValue.serverTimestamp(),
            'resolvedBy': FirebaseAuth.instance.currentUser?.email,
          });

      // Close loading dialog and show success
      Navigator.pop(context);

      // Clear data
      resolutionImage = null;
      noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resolution submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      // Handle errors
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

  // Navigate to location using default map app
  Future<void> _navigateToLocation(double latitude, double longitude) async {
    final url =
        Platform.isIOS
            ? 'http://maps.apple.com/?daddr=$latitude,$longitude'
            : 'geo:$latitude,$longitude?q=$latitude,$longitude';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps web
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

  // Format timestamp to readable string
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp.millisecondsSinceEpoch,
    );
    return DateFormat('MMM d, yyyy, h:mm a').format(date);
  }
}
