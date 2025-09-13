import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:async';

class UltraSafeIOSMap extends StatefulWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController)? onMapCreated;
  final double? zoom;
  final VoidCallback? onRetry;

  const UltraSafeIOSMap({
    super.key,
    this.currentPosition,
    this.markers = const {},
    this.onMapCreated,
    this.zoom = 15.0,
    this.onRetry,
  });

  @override
  State<UltraSafeIOSMap> createState() => _UltraSafeIOSMapState();
}

class _UltraSafeIOSMapState extends State<UltraSafeIOSMap> {
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  GoogleMapController? _controller;
  Timer? _initTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _safeInitialize();
  }

  Future<void> _safeInitialize() async {
    try {
      // Multiple safety checks for iOS
      if (!mounted) return;
      
      // Add longer delay for iOS stability
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });
      
      print('✅ Ultra Safe iOS Map initialized');
    } catch (e) {
      print('❌ Ultra Safe iOS Map initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Map initialization failed: $e';
        });
      }
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

    return _buildUltraSafeMap();
  }

  Widget _buildUltraSafeMap() {
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
              _handleMapCreated(controller);
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: widget.zoom ?? 15.0,
            ),
            markers: widget.markers,
            
            // Ultra-safe iOS configuration
            myLocationEnabled: false, // Always disable for iOS
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            
            // Disable all gestures for maximum stability
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            tiltGesturesEnabled: false,
            
            // Disable all interactive features
            compassEnabled: false,
            liteModeEnabled: false,
            mapType: MapType.normal,
            
            // Minimal event handling
            onTap: (LatLng latLng) {
              // Do nothing to prevent crashes
            },
            
            // Disable all other event handlers
            onCameraMove: null,
            onCameraIdle: null,
          ),
        ),
      );
    } catch (e) {
      print('❌ Critical Ultra Safe iOS Maps error: $e');
      _handleError('Maps rendering failed: $e');
      return _buildErrorWidget();
    }
  }

  void _handleMapCreated(GoogleMapController controller) {
    try {
      print('✅ Ultra Safe iOS Maps controller created');
      _controller = controller;
      
      // Add multiple delays for iOS stability
      _initTimer?.cancel();
      _initTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted && widget.onMapCreated != null) {
          try {
            widget.onMapCreated!(controller);
            print('✅ Ultra Safe iOS Maps callback executed');
          } catch (e) {
            print('❌ Error in Ultra Safe iOS Maps callback: $e');
            _handleError('Map callback failed: $e');
          }
        }
      });
    } catch (e) {
      print('❌ Error in Ultra Safe iOS map creation: $e');
      _handleError('Map controller creation failed: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
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
              'Preparing map for iOS...',
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
              if (_retryCount < _maxRetries)
                ElevatedButton.icon(
                  onPressed: () {
                    _retryCount++;
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                      _isInitialized = false;
                    });
                    _safeInitialize();
                    if (widget.onRetry != null) {
                      widget.onRetry!();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text('Try Again ($_retryCount/$_maxRetries)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29BDCE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                const Text(
                  'Maximum retry attempts reached',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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
    _initTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
