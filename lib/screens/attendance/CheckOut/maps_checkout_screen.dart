import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/attendance_service.dart';
import '../../../services/auth_service.dart';
import '../../../config/env.dart';
import '../../../models/attendance_record.dart';
import 'package:flutter_translate/flutter_translate.dart';

class MapsCheckoutScreen extends StatefulWidget {
  final AttendanceRecord currentRecord;

  const MapsCheckoutScreen({
    super.key,
    required this.currentRecord,
  });

  @override
  State<MapsCheckoutScreen> createState() => _MapsCheckoutScreenState();
}

class _MapsCheckoutScreenState extends State<MapsCheckoutScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _mapsError;
  
  Set<Marker> _markers = {};

  // Checkout form
  XFile? _selectedImage;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  
  // Reload data state
  bool _isReloadingData = false;

  @override
  void initState() {
    super.initState();
    print('🏪 Checkout Screen - Store Name: ${widget.currentRecord.storeName}');
    print('🏪 Checkout Screen - Store ID: ${widget.currentRecord.storeId}');
    print('🏪 Checkout Screen - Details count: ${widget.currentRecord.details.length}');
    if (widget.currentRecord.details.isNotEmpty) {
      print('🏪 Checkout Screen - First detail store name: ${widget.currentRecord.details.first.storeName}');
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
            content: Text('Location refreshed successfully'),
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
            content: Text('Failed to refresh location: $e'),
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

  // Reload attendance data
  Future<void> _reloadAttendanceData() async {
    setState(() {
      _isReloadingData = true;
    });

    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ [Check-out] No auth token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [Check-out] Attendance API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        json.decode(response.body); // Parse response to validate
        print('✅ [Check-out] Attendance data reloaded successfully');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance data reloaded successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ [Check-out] Failed to reload attendance data: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reload attendance data'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [Check-out] Error reloading attendance data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reloading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isReloadingData = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Getting current location...');
      
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
          _mapsError = null;
        });
        
        _updateMarkers();
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _mapsError = e.toString();
        });
      }
    }
  }


  void _updateMarkers() {
    // Use the safer update method
    _updateMarkersSimple();
  }


  double _getDistanceToStore() {
    if (_currentPosition == null) {
      return double.infinity;
    }

    // Use the check-in location from the record
    if (widget.currentRecord.details.isNotEmpty) {
      final detail = widget.currentRecord.details.first;
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        detail.latitudeIn,
        detail.longitudeIn,
      );
      print('📏 Distance to store: ${distance.toStringAsFixed(0)}m');
      return distance;
    }

    // Fallback: if no details, return 0 (assume at store)
    print('📏 No store details found, assuming at store (0m)');
    return 0.0;
  }

  void _updateMarkersSimple() {
    if (_currentPosition == null) return;

    final markers = <Marker>{};

    // Current position marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_position'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
      ),
    );

    // Store marker (if available)
    if (widget.currentRecord.details.isNotEmpty) {
      final detail = widget.currentRecord.details.first;
      markers.add(
        Marker(
          markerId: const MarkerId('store_location'),
          position: LatLng(
            detail.latitudeIn,
            detail.longitudeIn,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: detail.storeName,
            snippet: 'Check-out location',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<void> _goToTargetLocation() async {
    if (_mapController == null) {
      print('❌ Map controller not available');
      return;
    }

    if (widget.currentRecord.details.isEmpty) {
      print('❌ No store details available for navigation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final detail = widget.currentRecord.details.first;
      print('🎯 Navigating to store location: ${detail.latitudeIn}, ${detail.longitudeIn}');
      
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            detail.latitudeIn,
            detail.longitudeIn,
          ),
        ),
      );
      
      print('✅ Successfully navigated to store location');
    } catch (e) {
      print('❌ Error going to target: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to navigate to store: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                    // Auto-show submit dialog after taking photo
                    _showSubmitDialog();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                    // Auto-show submit dialog after selecting from gallery
                    _showSubmitDialog();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Ready to Check Out'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Photo captured successfully!'),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add your checkout note...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitCheckout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCheckout() async {
    // Photo and note are now optional - can submit without them
    print('🔄 Submitting checkout...');
    print('📸 Photo selected: ${_selectedImage != null}');
    print('📝 Note: "${_noteController.text.trim()}"');

    try {
      setState(() {
        _isSubmitting = true;
      });

      await AttendanceService().checkOut(
        image: _selectedImage, // Now optional - can be null
        note: _noteController.text.trim().isEmpty ? 'Checkout completed' : _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked out'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Out'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh location',
          ),
          IconButton(
            onPressed: _isReloadingData ? null : _reloadAttendanceData,
            icon: _isReloadingData 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Reload data',
          ),
          if (widget.currentRecord.details.isNotEmpty)
            IconButton(
              onPressed: _goToTargetLocation,
              icon: const Icon(Icons.store),
              tooltip: 'Go to store location',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mapsError != null
              ? _buildErrorState()
              : _buildMapWithCheckoutForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Location Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _mapsError ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWithCheckoutForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Map
            Expanded(
              flex: 2,
              child: _buildMinimalMap(),
            ),
            // Checkout form
            Expanded(
              flex: 1,
              child: _buildCheckoutForm(constraints),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMinimalMap() {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  Widget _buildCheckoutForm(BoxConstraints constraints) {
    final distance = _getDistanceToStore();
    final availableHeight = constraints.maxHeight;
    final isSmallScreen = availableHeight < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check Out',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.currentRecord.storeName ?? 'Unknown Store',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Location info - Compact version for small screens
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: isSmallScreen 
                ? Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(0)}m',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Ready',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Distance: ${distance.toStringAsFixed(0)}m',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
                          Expanded(
                            child: Text(
                              'Location: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}, ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            'Accuracy: ${_currentPosition?.accuracy.toStringAsFixed(1) ?? 'N/A'}m',
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
                  ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Photo section
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: Icon(
                      Icons.camera_alt,
                      size: isSmallScreen ? 16 : 20,
                    ),
                    label: Text(
                      _selectedImage == null ? 'Take Photo' : 'Change Photo',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedImage == null ? Colors.grey[300] : Colors.green,
                      foregroundColor: _selectedImage == null ? Colors.grey[600] : Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 8 : 12,
                        horizontal: isSmallScreen ? 8 : 16,
                      ),
                    ),
                  ),
                ),
                if (_selectedImage != null) ...[
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Container(
                    width: isSmallScreen ? 50 : 60,
                    height: isSmallScreen ? 50 : 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Note section (only show if no photo taken yet)
            if (_selectedImage == null) ...[
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add your checkout note...',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.note,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 12,
                    horizontal: 12,
                  ),
                ),
                maxLines: isSmallScreen ? 1 : 2,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Submit button (only show if no photo taken yet)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: isSmallScreen ? 16 : 20,
                              height: isSmallScreen ? 16 : 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Text(
                              'Checking Out...',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Check Out',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ] else ...[
              // Show message when photo is taken
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: isSmallScreen ? 16 : 20,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        translate('photoCaptured'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
