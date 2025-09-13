import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class IOSSafeGoogleMap extends StatefulWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController)? onMapCreated;
  final double? zoom;
  final bool myLocationEnabled;
  final VoidCallback? onRetry;
  final bool enableGestures;

  const IOSSafeGoogleMap({
    super.key,
    this.currentPosition,
    this.markers = const {},
    this.onMapCreated,
    this.zoom = 15.0,
    this.myLocationEnabled = false,
    this.onRetry,
    this.enableGestures = true,
  });

  @override
  State<IOSSafeGoogleMap> createState() => _IOSSafeGoogleMapState();
}

class _IOSSafeGoogleMapState extends State<IOSSafeGoogleMap> {
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Add delay for iOS stability
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ iOS Maps initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Map initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return _buildMapWidget();
  }

  Widget _buildMapWidget() {
    try {
      final position = widget.currentPosition;
      if (position == null) {
        return _buildNoLocationWidget();
      }

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              try {
                print('✅ iOS Safe Maps controller created');
                _controller = controller;
                
                // Add delay before calling callback for iOS stability
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (widget.onMapCreated != null && mounted) {
                    widget.onMapCreated!(controller);
                  }
                });
              } catch (e) {
                print('❌ Error in iOS safe map creation: $e');
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Map controller creation failed: $e';
                  });
                }
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: widget.zoom ?? 15.0,
            ),
            markers: widget.markers,
            
            // iOS-specific safe configuration
            myLocationEnabled: widget.myLocationEnabled && Platform.isAndroid, // Disable for iOS
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            
            // Safe gesture configuration for iOS
            rotateGesturesEnabled: widget.enableGestures && Platform.isAndroid, // Disable for iOS
            scrollGesturesEnabled: widget.enableGestures,
            zoomGesturesEnabled: widget.enableGestures,
            tiltGesturesEnabled: false, // Always disable tilt for stability
            
            // Minimal event handling
            onTap: (LatLng latLng) {
              print('📍 iOS Map tapped: $latLng');
            },
            
            // iOS-specific map type
            mapType: MapType.normal,
            
            // Disable compass for iOS stability
            compassEnabled: false,
            
            // Disable lite mode for better iOS compatibility
            liteModeEnabled: false,
          ),
        ),
      );
    } catch (e) {
      print('❌ Critical iOS Maps error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Maps rendering failed: $e';
          });
        }
      });
      return _buildErrorWidget();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29BDCE)),
            ),
            SizedBox(height: 16),
            Text(
              'Preparing map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Location Not Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to get your current location',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Map Not Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Unable to load map. Please check your connection.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                    _isInitialized = false;
                  });
                  _initializeMap();
                  if (widget.onRetry != null) {
                    widget.onRetry!();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29BDCE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
