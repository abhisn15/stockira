import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/maps_service.dart';

class SafeGoogleMap extends StatefulWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController)? onMapCreated;
  final double? zoom;
  final bool myLocationEnabled;
  final VoidCallback? onRetry;

  const SafeGoogleMap({
    super.key,
    this.currentPosition,
    this.markers = const {},
    this.onMapCreated,
    this.zoom = 15.0,
    this.myLocationEnabled = false,
    this.onRetry,
  });

  @override
  State<SafeGoogleMap> createState() => _SafeGoogleMapState();
}

class _SafeGoogleMapState extends State<SafeGoogleMap> {
  final MapsService _mapsService = MapsService();
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return _buildMapWidget();
  }

  Widget _buildMapWidget() {
    try {
      final position = widget.currentPosition;
      if (position == null) {
        return _buildLoadingWidget();
      }

      return GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          try {
            print('✅ Safe Maps controller created');
            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          } catch (e) {
            print('❌ Error in safe map creation: $e');
            setState(() {
              _hasError = true;
              _errorMessage = 'Map initialization failed: $e';
            });
          }
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: widget.zoom ?? 15.0,
        ),
        markers: widget.markers,
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        
        // Safe gesture configuration
        rotateGesturesEnabled: false, // Disable for stability
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        tiltGesturesEnabled: false, // Disable tilt
        
        // Minimal event handling
        onTap: (LatLng latLng) {
          print('📍 Map tapped: $latLng');
        },
      );
    } catch (e) {
      print('❌ Critical Maps error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Maps initialization failed: $e';
        });
      });
      return _buildErrorWidget();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing map...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
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
                  });
                  if (widget.onRetry != null) {
                    widget.onRetry!();
                  }
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
}
