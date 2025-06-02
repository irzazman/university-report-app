import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';

class ReportPage extends StatefulWidget {
  final String category;

  const ReportPage({Key? key, required this.category}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _descriptionController = TextEditingController();
  final _floorController = TextEditingController();
  final _roomController = TextEditingController();
  File? _image;
  LatLng _pinLocation = LatLng(2.3136, 102.3212);
  final ImagePicker _picker = ImagePicker();
  GoogleMapController? _mapController;
  double? _uploadProgress;
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'Electrical',
    'Furniture',
    'IT/Equipment',
    'Cleanliness',
    'Structural',
    'Air Conditioning',
    'Plumbing',
    'Internet/WiFi',
    'Safety',
    'Lighting',
    'Garden/Landscape',
    'Road/Walkways',
    'Signage',
  ];

  String? _predictedType;
  bool _isCategoryEditable = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
  }

  Future<void> _setCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _pinLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_pinLocation));
      } catch (e) {
        print("Error getting location: $e");
      }
    } else {
      print("Location permission denied");
    }
  }

  void signInAnonymouslyIfNeeded() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _onDescriptionChanged(String description) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _predictCategory(description);
    });
  }

  void _predictCategory(String description) async {
    if (description.trim().isEmpty) {
      setState(() {
        _predictedType = null;
        _isCategoryEditable = false;
      });
      return;
    }

    final result = await ApiService.getPredictedCategory(description);
    print('API result: $result');
    print('Report types: $_reportTypes');
    setState(() {
      _predictedType = _reportTypes.contains(result) ? result : 'Other';
      _isCategoryEditable = false;
    });
  }

  void _submitReport() async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      // Upload image if available
      String? imageUrl;
      if (_image != null) {
        final fileName = const Uuid().v4();
        final storageRef = FirebaseStorage.instance.ref().child(
          'reports/$fileName.jpg',
        );

        UploadTask uploadTask = storageRef.putFile(_image!);
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        TaskSnapshot taskSnapshot = await uploadTask;
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      // Prepare report data
      Map<String, dynamic> reportData = {
        'category': widget.category,
        'description': _descriptionController.text,
        'type': _predictedType,
        'location': {
          'latitude': _pinLocation.latitude,
          'longitude': _pinLocation.longitude,
        },
        'imageUrl': imageUrl,
        'timestamp': Timestamp.now(),
      };

      if (widget.category == 'Dorms') {
        reportData['floor'] = _floorController.text;
        reportData['room'] = _roomController.text;
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('reports').add(reportData);

      setState(() {
        _descriptionController.clear();
        _floorController.clear();
        _roomController.clear();
        _image = null;
        _uploadProgress = null;
        _isSubmitting = false;
        _predictedType = null;
        _isCategoryEditable = false;
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('🎉 Report Submitted!'),
              content: Text('Thank you for your report.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      print("Error submitting report: $e");
      setState(() {
        _isSubmitting = false;
        _uploadProgress = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit report.")));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _floorController.dispose();
    _roomController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report ${widget.category} Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: _onDescriptionChanged,
            ),
            SizedBox(height: 16),

            // Category display / change UI
            if (!_isCategoryEditable && _predictedType != null) ...[
              TextFormField(
                readOnly: true,
                initialValue: _predictedType,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isCategoryEditable = true;
                    });
                  },
                  child: Text('Change'),
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _predictedType,
                items:
                    _reportTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _predictedType = value;
                    _isCategoryEditable = true;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            SizedBox(height: 16),

            if (widget.category == 'Dorms') ...[
              TextField(
                controller: _floorController,
                decoration: InputDecoration(
                  labelText: 'Floor',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
            ],

            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _pinLocation,
                  zoom: 17,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(_pinLocation),
                  );
                },
                markers: {
                  Marker(
                    markerId: MarkerId("report_location"),
                    position: _pinLocation,
                    draggable: true,
                    onDragEnd: (newPosition) {
                      setState(() {
                        _pinLocation = newPosition;
                      });
                    },
                  ),
                },
              ),
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text("Gallery"),
                ),
              ],
            ),
            if (_image != null) ...[
              SizedBox(height: 10),
              Image.file(_image!, height: 200),
            ],
            SizedBox(height: 24),

            if (_uploadProgress != null) ...[
              LinearProgressIndicator(value: _uploadProgress),
              SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              child:
                  _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Submit Report"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
