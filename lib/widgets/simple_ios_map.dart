import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class SimpleIOSMap extends StatefulWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController)? onMapCreated;
  final double? zoom;

  const SimpleIOSMap({
    super.key,
    this.currentPosition,
    this.markers = const {},
    this.onMapCreated,
    this.zoom = 15.0,
  });

  @override
  State<SimpleIOSMap> createState() => _SimpleIOSMapState();
}

class _SimpleIOSMapState extends State<SimpleIOSMap> {
  GoogleMapController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Add delay for iOS stability
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Simple iOS Map initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
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
                'Loading map...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.currentPosition == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Location not available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
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
            _controller = controller;
            if (widget.onMapCreated != null) {
              // Add delay for iOS stability
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  widget.onMapCreated!(controller);
                }
              });
            }
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            ),
            zoom: widget.zoom ?? 15.0,
          ),
          markers: widget.markers,
          
          // Simple configuration for iOS
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          
          // Basic gestures only
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          
          // Simple map type
          mapType: MapType.normal,
          
          // Disable compass
          compassEnabled: false,
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
