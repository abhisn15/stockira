import 'package:flutter/material.dart';
import '../../../services/language_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../../models/itinerary.dart';
import '../../../services/attendance_service.dart';
import '../../../services/maps_service.dart';
import '../../../widgets/safe_google_map.dart';

class MapsCheckinScreen extends StatefulWidget {
  final List<Itinerary> itineraryList;

  const MapsCheckinScreen({
    super.key,
    required this.itineraryList,
  });

  @override
  State<MapsCheckinScreen> createState() => _MapsCheckinScreenState();
}

class _MapsCheckinScreenState extends State<MapsCheckinScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Store? _selectedStore;
  XFile? _selectedImage;
  String _note = '';
  bool _isLoading = true;
  bool _isCheckingIn = false; // New state for check-in process
  bool _showStoreSelection = true;
  bool _mapsError = false;
  String _errorMessage = '';
  final TextEditingController _noteController = TextEditingController();
  final AttendanceService _attendanceService = AttendanceService();
  final MapsService _mapsService = MapsService();
  
  Set<Marker> _markers = {};
  late DateTime _currentTime;

  // Todo checklist items
  bool get _isDistanceValid => _selectedStore != null && _currentPosition != null && _getDistanceToStore() <= 100; // within 100 meters
  bool get _isPhotoValid => _selectedImage != null;
  bool get _isNoteValid => _note.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    
    // Debug Maps API key security
    try {
      _mapsService.debugSecurity();
    } catch (e) {
      print('❌ Error in Maps service debug: $e');
    }
    
    _getCurrentLocation();
  }

  // Manual location refresh method
  Future<void> _refreshLocation() async {
    try {
      print('🔄 Manual location refresh...');
      
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      await _getCurrentLocation();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(LanguageService.locationRefreshedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error refreshing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LanguageService.failedToRefreshLocation}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Starting location request...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services disabled');
        throw Exception('Location services are disabled. Please enable location services in device settings.');
      }
      
      print('✅ Location services enabled');

      LocationPermission permission = await Geolocator.checkPermission();
      print('🔍 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('🔄 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🔍 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please allow location access in app settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable in device settings.');
      }

      print('📡 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Reduced timeout for faster response
      );
      
      print('✅ Got location: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Update markers immediately
        _updateMarkers();
      }
    } catch (e) {
      print('❌ Location error: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set default location if GPS fails
          _currentPosition = Position(
            latitude: -6.200000,
            longitude: 106.816666,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        });
        
        _updateMarkers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LanguageService.usingDefaultLocation}: $e'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                // Open app settings - in real app, use app_settings plugin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(LanguageService.pleaseEnableLocationPermissions),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }


  void _updateMarkers() {
    // Use the safer update method
    _updateMarkersSimple();
  }


  double _getDistanceToStore() {
    if (_currentPosition == null || _selectedStore == null) return double.infinity;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      double.parse(_selectedStore!.latitude ?? '0'),
      double.parse(_selectedStore!.longitude ?? '0'),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';

    return '$month ${dateTime.day}, ${dateTime.year} - $hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = days[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];

    return '$weekday, $month ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  void _selectStore(Store store) {
    print('🏪 Store selected: ${store.name}');
    
    // Simple state update
    if (mounted) {
      setState(() {
        _selectedStore = store;
        _showStoreSelection = false;
      });
    }
  }

  void _goToTargetLocation() {
    if (_selectedStore != null && _mapController != null) {
      try {
        print('🎯 Going to target location: ${_selectedStore!.name}');
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              double.parse(_selectedStore!.latitude ?? '0'),
              double.parse(_selectedStore!.longitude ?? '0'),
            ),
            16.0,
          ),
        );
      } catch (e) {
        print('❌ Error going to target: $e');
      }
    }
  }


  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(LanguageService.takePhoto),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${LanguageService.errorTakingPicture}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(LanguageService.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${LanguageService.errorSelectingImage}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performCheckIn() async {
    // Prevent multiple check-in attempts
    if (_isCheckingIn) {
      return;
    }

    if (!_isDistanceValid || !_isPhotoValid || !_isNoteValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(LanguageService.pleaseCompleteAllRequirements),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.confirmCheckIn),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LanguageService.areYouSureCheckIn),
            const SizedBox(height: 16),
            Text('${LanguageService.store}: ${_selectedStore!.name}'),
            Text('${LanguageService.distance}: ${_formatDistance(_getDistanceToStore())}'),
            Text('${LanguageService.time}: ${_formatDateTime(_currentTime)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 41, 189, 206),
              foregroundColor: Colors.white,
            ),
            child: const Text('Check In'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isCheckingIn = true;
      });

      try {
        // Show loading dialog
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 360;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'Checking in...',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Please wait, do not close the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await _attendanceService.checkIn(
          storeId: _selectedStore!.id,
          storeName: _selectedStore!.name,
          image: _selectedImage!,
          note: _note,
          distance: _getDistanceToStore(),
        );

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context, true); // Return to dashboard with success

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully checked in at ${_selectedStore!.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Check-in failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCheckingIn = false;
          });
        }
      }
    }
  }

  List<Store> _getAllStores() {
    final stores = <Store>[];
    for (var itinerary in widget.itineraryList) {
      stores.addAll(itinerary.stores);
    }
    return stores;
  }

  Widget _buildStoreSelectionSheetOLD({ScrollController? scrollController}) { // Deprecated - using simple list now
    final stores = _getAllStores();

    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
              const SizedBox(width: 8),
              const Text(
                'Select Store',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${stores.length} stores',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Store list
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stores.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final store = stores[index];
              final distance = _currentPosition != null
                  ? Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      double.parse(store.latitude ?? '0'),
                      double.parse(store.longitude ?? '0'),
                    )
                  : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 41, 189, 206).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Color.fromARGB(255, 41, 189, 206),
                    ),
                  ),
                  title: Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        store.address ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDistance(distance),
                            style: TextStyle(
                              color: distance <= 100 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectStore(store),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInFormSheetOLD({ScrollController? scrollController}) { // Deprecated - using simple panel now
    final distance = _getDistanceToStore();

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Store info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 41, 189, 206).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store,
                  color: Color.fromARGB(255, 41, 189, 206),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStore!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedStore!.address ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Date and time
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color.fromARGB(255, 41, 189, 206)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(_currentTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTime(_currentTime),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Photo capture
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isPhotoValid ? Colors.green : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to add photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Required for check-in',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Notes field
          TextField(
            controller: _noteController,
            onChanged: (value) => setState(() => _note = value),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText: 'Add your check-in notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.edit_note),
            ),
          ),

          const SizedBox(height: 20),

          // Todo checklist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check-in Requirements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Distance check
                Row(
                  children: [
                    Icon(
                      _isDistanceValid ? Icons.check_circle : Icons.remove_circle,
                      color: _isDistanceValid ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Distance: ${_formatDistance(distance)}',
                        style: TextStyle(
                          color: _isDistanceValid ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Photo check
                Row(
                  children: [
                    Icon(
                      _isPhotoValid ? Icons.check_circle : Icons.remove_circle,
                      color: _isPhotoValid ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Photo captured',
                        style: TextStyle(
                          color: _isPhotoValid ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Note check
                Row(
                  children: [
                    Icon(
                      _isNoteValid ? Icons.check_circle : Icons.remove_circle,
                      color: _isNoteValid ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notes added',
                        style: TextStyle(
                          color: _isNoteValid ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Check-in button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isDistanceValid && _isPhotoValid && _isNoteValid && !_isCheckingIn)
                  ? _performCheckIn
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 41, 189, 206),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCheckingIn
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Checking in...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLargeScreen = screenSize.width > 414;
    
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing maps and location...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Minimal Google Map for maximum stability
                Container(
                  child: _currentPosition != null 
                    ? _buildMinimalMap()
                    : _buildMapPlaceholder(),
                ),

                // Top app bar
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Expanded(
                          child: Text(
                            'Check In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshLocation,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh location',
                        ),
                        if (_selectedStore != null)
                          IconButton(
                            onPressed: _goToTargetLocation,
                            icon: const Icon(Icons.store),
                            tooltip: 'Go to store location',
                          ),
                      ],
                    ),
                  ),
                ),

                // Simple bottom panel to prevent crashes
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _selectedStore == null
                      ? _buildSimpleStoreList()
                      : _buildSimpleCheckInPanel(),
                ),
              ],
            ),
    );
  }

  // Ultra-minimal map to prevent crashes
  Widget _buildMinimalMap() {
    try {
      print('🗺️ Building ultra-minimal map...');
      
      return Container(
        color: Colors.grey[200],
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            print('✅ Ultra-minimal map created');
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14.0,
          ),
          
          // Absolutely minimal configuration
          markers: _markers, // Use current markers
          myLocationEnabled: true, // Enable to show current location
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          
          // Enable basic gestures for better UX
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          
          // No event handlers at all
        ),
      );
    } catch (e) {
      print('❌ Error building minimal map: $e');
      return _buildMapError();
    }
  }
  
  // Emergency fallback if Maps completely fails
  Widget _buildMapError() {
    return Container(
      color: Colors.blue[50],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 64,
                  color: Colors.blue[300],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Map Loading Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We\'re having trouble loading the map. You can still proceed with check-in using the store list below.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _getCurrentLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 41, 189, 206),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simplified marker update
  void _updateMarkersSimple() {
    if (!mounted || _currentPosition == null) return;
    
    try {
      print('🔄 Updating markers safely...');
      
      final markers = <Marker>{};
      
      // Add current position marker only
      markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      );
      
      // Add selected store marker if available
      if (_selectedStore != null) {
        markers.add(
          Marker(
            markerId: MarkerId('store_${_selectedStore!.id}'),
            position: LatLng(
              double.parse(_selectedStore!.latitude ?? '0'),
              double.parse(_selectedStore!.longitude ?? '0'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: _selectedStore!.name,
              snippet: _selectedStore!.address ?? '',
            ),
          ),
        );
      }
      
      if (mounted) {
        setState(() {
          _markers = markers;
        });
        print('✅ Markers updated successfully');
      }
    } catch (e) {
      print('❌ Error updating markers: $e');
    }
  }

  // Map placeholder while loading
  Widget _buildMapPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Preparing map...'),
            SizedBox(height: 8),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
  
  // Simple store list without DraggableScrollableSheet
  Widget _buildSimpleStoreList() {
    final stores = _getAllStores();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
                const SizedBox(width: 8),
                const Text(
                  'Select Store',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${stores.length} stores',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Store list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stores.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final store = stores[index];
                final distance = _currentPosition != null
                    ? Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        double.parse(store.latitude ?? '0'),
                        double.parse(store.longitude ?? '0'),
                      )
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 41, 189, 206).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
                    ),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.address ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistance(distance),
                              style: TextStyle(
                                color: distance <= 100 ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _selectStore(store),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Simple check-in panel
  Widget _buildSimpleCheckInPanel() {
    if (_selectedStore == null) {
      return Container(
        height: 200,
        color: Colors.white,
        child: const Center(
          child: Text('No store selected'),
        ),
      );
    }
    
    final distance = _getDistanceToStore();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Store info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 41, 189, 206).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedStore!.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedStore!.address ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Distance info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: distance <= 100 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: distance <= 100 ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: distance <= 100 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Distance: ${_formatDistance(distance)}',
                        style: TextStyle(
                          color: distance <= 100 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPosition != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GPS Ready - Tap refresh to update',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Simple check-in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: distance <= 100 ? () {
                  Navigator.pop(context, true); // Simple success for now
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 41, 189, 206),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  distance <= 100 ? 'Check In' : 'Too far from store (${_formatDistance(distance)})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}