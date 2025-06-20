import 'dart:async';
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
import 'user_service.dart';

class ReportPage extends StatefulWidget {
  final String category;

  const ReportPage({super.key, required this.category});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  final _floorController = TextEditingController();
  final _roomController = TextEditingController();
  final _houseController = TextEditingController();
  File? _image;
  LatLng _pinLocation = LatLng(2.3136, 102.3212);
  final ImagePicker _picker = ImagePicker();
  GoogleMapController? _mapController;
  double? _uploadProgress;
  bool _isSubmitting = false;

  // Example dropdown options
  final List<String> _categories = [
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
  final List<String> _houses = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];
  final List<String> _rooms = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _dormFloors = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];
  final List<String> _facultyFloors = ['1', '2', '3', '4'];
  final List<String> _colleges = ['Satria', 'Lestari'];
  final Map<String, List<String>> _blocks = {
    'Satria': ['Kasturi', 'Tuah', 'Jebat', 'Lekir', 'Lekiu'],
    'Lestari': ['A1', 'A2', 'B1', 'B2'],
  };
  final List<String> _lestariFloors = ['1', '2', '3', '4'];
  final List<String> _facultyList = [
    'FTMK',
    'FKP',
    'FTKM',
    'CeLL',
    'FTKEK',
    'FKE',
  ];
  String? _selectedFloor;
  String? _selectedHouse;
  String? _selectedRoom;
  String? _predictedType;
  String? _selectedCollege;
  String? _selectedBlock;
  String? _selectedFaculty;
  bool _isCategoryEditable = false;
  Timer? _debounce;
  Timer? _periodicTimer;
  String _lastPredictedDescription = '';

  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();

    // Initialize page animations
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation
    _pageAnimationController.forward();
  }

  Future<void> _setCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        // Try to get last known position first (much faster)
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          setState(() {
            _pinLocation = LatLng(
              lastPosition.latitude,
              lastPosition.longitude,
            );
          });
          _mapController?.animateCamera(CameraUpdate.newLatLng(_pinLocation));
        }
        // Then get the current position (may take longer)
        // Fix: Using LocationSettings instead of deprecated desiredAccuracy
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _pinLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_pinLocation));
      } catch (e) {
        // Replace print with proper logging or error handling
        debugPrint("Error getting location: $e");
      }
    } else {
      debugPrint("Location permission denied");
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
    // Cancel any existing timers
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    if (_periodicTimer?.isActive ?? false) {
      _periodicTimer!.cancel();
    }

    // Wait for user to finish typing (800ms after they stop)
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (description.trim().isNotEmpty &&
          description != _lastPredictedDescription) {
        _predictCategory(description);
        _lastPredictedDescription = description;

        // Set up periodic prediction every 10 seconds if user continues typing
        _periodicTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          final currentDescription = _descriptionController.text;
          if (currentDescription.trim().isNotEmpty &&
              currentDescription != _lastPredictedDescription) {
            _predictCategory(currentDescription);
            _lastPredictedDescription = currentDescription;
          }
        });
      }
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

    try {
      // Show loading indicator while predicting
      if (mounted) {
        setState(() {
          _predictedType = 'Predicting...';
          _isCategoryEditable = false;
        });
      }

      debugPrint('Starting prediction for: "$description"');
      final result = await ApiService.getPredictedCategory(description);
      debugPrint('AI Prediction result: $result');
      debugPrint('Available categories: $_categories');

      // Force a small delay to ensure the loading state is visible
      await Future.delayed(Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          if (result == 'Other' && !_categories.contains('Other')) {
            // If API returned 'Other' but it's not in our categories,
            // let user select manually
            _predictedType = null;
            _isCategoryEditable = true;

            // Show a snackbar to inform user
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Could not predict category. Please select manually.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          } else {
            _predictedType = _categories.contains(result) ? result : null;
            _isCategoryEditable = false;
            debugPrint('Setting _predictedType to: $_predictedType');
          }
        });
      }
    } catch (e) {
      debugPrint('Error predicting category: $e');
      if (mounted) {
        setState(() {
          _predictedType = null;
          _isCategoryEditable = true;
        });

        // Show error message to user
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Prediction service unavailable. Please select category manually.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        });
      }
    }
  }

  void _submitReport() async {
    // Validate required fields
    if (!_validateForm()) {
      return;
    }

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

      // Prepare report data (without reportId for now)
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
        'status': 'Pending',
      };
      final user = FirebaseAuth.instance.currentUser;
      reportData['userEmail'] = user?.email ?? '';

      // Get user's phone number and add to report
      final userPhone = await UserService.getCurrentUserPhone();
      if (userPhone != null) {
        reportData['reporterPhone'] = userPhone['phoneNumber'] ?? '';
        reportData['reporterCountryCode'] = userPhone['countryCode'] ?? '';
        reportData['reporterFullPhone'] = userPhone['fullNumber'] ?? '';
      }

      if (widget.category == 'Dorm') {
        reportData['college'] = _selectedCollege;
        reportData['block'] = _selectedBlock;
        reportData['floor'] = _selectedFloor;
        reportData['room'] = _selectedRoom;
        if (_selectedCollege != 'Lestari') {
          reportData['house'] = _selectedHouse;
        }
      } else if (widget.category == 'Faculty') {
        reportData['faculty'] = _selectedFaculty;
        reportData['floor'] = _selectedFloor;
        reportData['room'] = _roomController.text;
      }

      // Add to Firestore and get the document reference
      final docRef = await FirebaseFirestore.instance
          .collection('reports')
          .add(reportData);

      // Update the same document with its auto-generated ID
      await docRef.update({'reportId': docRef.id});

      setState(() {
        _descriptionController.clear();
        _floorController.clear();
        _roomController.clear();
        _houseController.clear();
        _image = null;
        _uploadProgress = null;
        _isSubmitting = false;
        _predictedType = null;
        _isCategoryEditable = false;
        _selectedCollege = null;
        _selectedBlock = null;
        _selectedFloor = null;
        _selectedRoom = null;
        _selectedHouse = null;
        _selectedFaculty = null;
      });

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Report Submitted",
          pageBuilder: (context, anim1, anim2) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Scaffold(
                backgroundColor: Colors.black.withAlpha(
                  77,
                ), // Fixed withOpacity
                body: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(
                            26,
                          ), // Fixed withOpacity
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0070F0),
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Report Submitted!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thank you for your report.\nTap anywhere to return to Home.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Error submitting report: $e");
      setState(() {
        _isSubmitting = false;
        _uploadProgress = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to submit report."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  bool _validateForm() {
    // Check description is not empty
    if (_descriptionController.text.trim().isEmpty) {
      _showValidationError('Please provide a description of the issue.');
      return false;
    }

    // Check category/type is selected
    if (_predictedType == null || _predictedType!.isEmpty) {
      _showValidationError(
        'Please select or predict a category for the issue.',
      );
      return false;
    }

    // Validate based on category
    if (widget.category == 'Dorm') {
      if (_selectedCollege == null) {
        _showValidationError('Please select a college.');
        return false;
      }
      if (_selectedBlock == null) {
        _showValidationError('Please select a block.');
        return false;
      }
      if (_selectedFloor == null) {
        _showValidationError('Please select a floor.');
        return false;
      }
      if (_selectedRoom == null) {
        _showValidationError('Please select a room.');
        return false;
      }
      if (_selectedCollege != 'Lestari' && _selectedHouse == null) {
        _showValidationError('Please select a house.');
        return false;
      }
    } else if (widget.category == 'Faculty') {
      if (_selectedFaculty == null) {
        _showValidationError('Please select a faculty.');
        return false;
      }
      if (_selectedFloor == null) {
        _showValidationError('Please select a floor.');
        return false;
      }
      if (_roomController.text.trim().isEmpty) {
        _showValidationError('Please enter a room number.');
        return false;
      }
    }

    return true;
  }

  bool get _isFormValid {
    // Check description
    if (_descriptionController.text.trim().isEmpty) return false;

    // Check category
    if (_predictedType == null || _predictedType!.isEmpty) return false;

    // Check category-specific fields
    if (widget.category == 'Dorm') {
      if (_selectedCollege == null ||
          _selectedBlock == null ||
          _selectedFloor == null ||
          _selectedRoom == null)
        return false;
      if (_selectedCollege != 'Lestari' && _selectedHouse == null) return false;
    } else if (widget.category == 'Faculty') {
      if (_selectedFaculty == null ||
          _selectedFloor == null ||
          _roomController.text.trim().isEmpty)
        return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _floorController.dispose();
    _roomController.dispose();
    _houseController.dispose();
    _debounce?.cancel();
    _periodicTimer?.cancel();
    _pageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDorm = widget.category == 'Dorm';
    final isFaculty = widget.category == 'Faculty';
    final isCampus = widget.category == 'Campus';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Report ${widget.category} Issue'),
        backgroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _pageAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Animated Form card
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Opacity(
                            opacity: value,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Animated location details for dorm
                                    if (isDorm) ..._buildAnimatedDormFields(),

                                    // Animated faculty details
                                    if (isFaculty)
                                      ..._buildAnimatedFacultyFields(),

                                    _buildSectionTitle('Issue Description'),
                                    const SizedBox(height: 16),

                                    // Animated description field
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: TextField(
                                        controller: _descriptionController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Describe the issue in detail',
                                          hintText:
                                              'e.g., Broken light in room, Water leakage...',
                                          prefixIcon: Icon(
                                            Icons.description_rounded,
                                            color: Color(0xFF0070F0),
                                          ),
                                        ),
                                        maxLines: 4,
                                        onChanged: _onDescriptionChanged,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Animated category section
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      child: _buildCategorySection(),
                                    ),

                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Animated Map section for campus
                    if (isCampus) ...[
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: Opacity(
                              opacity: value,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionTitle('Location on Campus'),
                                      const SizedBox(height: 16),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        height: 250,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: GoogleMap(
                                            initialCameraPosition:
                                                CameraPosition(
                                                  target: _pinLocation,
                                                  zoom: 17,
                                                ),
                                            onMapCreated: (controller) {
                                              _mapController = controller;
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLng(
                                                  _pinLocation,
                                                ),
                                              );
                                            },
                                            markers: {
                                              Marker(
                                                markerId: const MarkerId(
                                                  "report_location",
                                                ),
                                                position: _pinLocation,
                                                draggable: true,
                                                onDragEnd: (newPosition) {
                                                  setState(() {
                                                    _pinLocation = newPosition;
                                                  });
                                                },
                                                infoWindow: const InfoWindow(
                                                  title: 'Report Location',
                                                  snippet:
                                                      'Tap and drag to adjust',
                                                ),
                                              ),
                                            },
                                            onTap: (LatLng tappedPoint) {
                                              setState(() {
                                                _pinLocation = tappedPoint;
                                              });
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLng(
                                                  tappedPoint,
                                                ),
                                              );
                                            },
                                            myLocationEnabled: true,
                                            myLocationButtonEnabled: true,
                                            zoomControlsEnabled: false,
                                            mapToolbarEnabled: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0070F0,
                                          ).withAlpha(26), // Fixed withOpacity
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline_rounded,
                                              color: Color(0xFF0070F0),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Tap on the map or drag the marker to set the exact location',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: const Color(
                                                    0xFF0070F0,
                                                  ).withAlpha(
                                                    204,
                                                  ), // Fixed withOpacity
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Animated Image section
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Opacity(
                            opacity: value,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Add Photo'),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildImageButton(
                                            'Take Photo',
                                            Icons.camera_alt_rounded,
                                            () =>
                                                _pickImage(ImageSource.camera),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildImageButton(
                                            'From Gallery',
                                            Icons.photo_library_rounded,
                                            () =>
                                                _pickImage(ImageSource.gallery),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_image != null) ...[
                                      const SizedBox(height: 20),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.file(
                                            _image!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Animated upload progress
                    if (_uploadProgress != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  'Uploading... ${(_uploadProgress! * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: LinearProgressIndicator(
                                    value: _uploadProgress,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF0070F0),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Animated submit button - Fixed syntax errors
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  (_isSubmitting || !_isFormValid)
                                      ? null
                                      : _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (_isSubmitting || !_isFormValid)
                                        ? Colors.grey
                                        : const Color(0xFF0070F0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation:
                                    (_isSubmitting || !_isFormValid) ? 0 : 2,
                              ),
                              child:
                                  _isSubmitting
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Submit Report',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    void Function(T?) onChanged,
    IconData icon,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items:
            items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0070F0)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
      ),
    );
  }

  Widget _buildImageButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0070F0),
          side: const BorderSide(color: Color(0xFF0070F0), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    if (!_isCategoryEditable && _predictedType != null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        key: ValueKey('predicted_$_predictedType'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _predictedType == 'Predicting...'
                          ? Colors.orange.withAlpha(77) // Fixed withOpacity
                          : const Color(
                            0xFF0070F0,
                          ).withAlpha(77), // Fixed withOpacity
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _predictedType == 'Predicting...'
                              ? Colors.orange.withAlpha(26) // Fixed withOpacity
                              : const Color(
                                0xFF0070F0,
                              ).withAlpha(26), // Fixed withOpacity
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        _predictedType == 'Predicting...'
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF0070F0),
                              size: 20,
                            ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _predictedType == 'Predicting...'
                              ? 'AI is analyzing...'
                              : _predictedType!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _predictedType == 'Predicting...'
                              ? 'Please wait while we predict the category'
                              : 'Category predicted by AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_predictedType != 'Predicting...')
                    TextButton(
                      onPressed:
                          () => setState(() => _isCategoryEditable = true),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0070F0),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      child: const Text('Change'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        key: const ValueKey('manual_selection'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              'Category',
              _predictedType == 'Predicting...' ? null : _predictedType,
              _categories,
              (value) => setState(() {
                _predictedType = value;
                _isCategoryEditable = true;
              }),
              Icons.category_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Auto-predict'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0070F0),
                      textStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () {
                      setState(() => _isCategoryEditable = false);
                      if (_descriptionController.text.trim().isNotEmpty) {
                        _predictCategory(_descriptionController.text);
                      }
                    },
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Test API'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onPressed: _testApiConnection,
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void _testApiConnection() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Testing API connection...'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      final isConnected = await ApiService.testApiConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected
                  ? 'API connection successful!'
                  : 'API connection failed. Please check your internet connection.',
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing API: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Helper method to build animated dorm fields
  List<Widget> _buildAnimatedDormFields() {
    return [
      _buildSectionTitle('Location Details'),
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: _buildDropdown(
          'College',
          _selectedCollege,
          _colleges,
          (v) => setState(() {
            _selectedCollege = v;
            _selectedBlock = null;
            _selectedFloor = null;
            _selectedHouse = null;
          }),
          Icons.account_balance_rounded,
        ),
      ),
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        child: _buildDropdown(
          'Block',
          _selectedBlock,
          _selectedCollege != null ? _blocks[_selectedCollege] ?? [] : [],
          (v) => setState(() => _selectedBlock = v),
          Icons.business_rounded,
        ),
      ),
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        child: _buildDropdown(
          'Floor',
          _selectedFloor,
          _selectedCollege == 'Lestari' ? _lestariFloors : _dormFloors,
          (v) => setState(() => _selectedFloor = v),
          Icons.layers_rounded,
        ),
      ),
      const SizedBox(height: 16),
      if (_selectedCollege == 'Satria') ...[
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          child: _buildDropdown(
            'House',
            _selectedHouse,
            _houses,
            (v) => setState(() => _selectedHouse = v),
            Icons.home_rounded,
          ),
        ),
        const SizedBox(height: 16),
      ],
      AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        child: _buildDropdown(
          'Room',
          _selectedRoom,
          _rooms,
          (v) => setState(() => _selectedRoom = v),
          Icons.door_front_door_rounded,
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  // Helper method to build animated faculty fields
  List<Widget> _buildAnimatedFacultyFields() {
    return [
      _buildSectionTitle('Faculty Details'),
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: _buildDropdown(
          'Faculty',
          _selectedFaculty,
          _facultyList,
          (v) => setState(() => _selectedFaculty = v),
          Icons.school_rounded,
        ),
      ),
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        child: _buildDropdown(
          'Floor',
          _selectedFloor,
          _facultyFloors,
          (v) => setState(() => _selectedFloor = v),
          Icons.layers_rounded,
        ),
      ),
      const SizedBox(height: 16),
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _roomController,
          decoration: const InputDecoration(
            labelText: 'Room Number',
            hintText: 'e.g., 101, A-201, Lab 1',
            prefixIcon: Icon(
              Icons.door_front_door_rounded,
              color: Color(0xFF0070F0),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            labelStyle: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}
