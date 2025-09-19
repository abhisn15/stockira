import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/store.dart';

class StoresMapWidget extends StatefulWidget {
  final List<Store> stores;
  final double? userLatitude;
  final double? userLongitude;
  final Function(Store)? onStoreTap;
  final double initialZoom;
  final bool showUserLocation;

  const StoresMapWidget({
    super.key,
    required this.stores,
    this.userLatitude,
    this.userLongitude,
    this.onStoreTap,
    this.initialZoom = 15.0,
    this.showUserLocation = true,
  });

  @override
  State<StoresMapWidget> createState() => _StoresMapWidgetState();
}

class _StoresMapWidgetState extends State<StoresMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _center;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(StoresMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stores != widget.stores ||
        oldWidget.userLatitude != widget.userLatitude ||
        oldWidget.userLongitude != widget.userLongitude) {
      _updateMarkers();
    }
  }

  void _initializeMap() {
    _updateMarkers();
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add user location marker
    if (widget.showUserLocation && 
        widget.userLatitude != null && 
        widget.userLongitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(widget.userLatitude!, widget.userLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Lokasi Anda',
            snippet: 'Posisi saat ini',
          ),
        ),
      );
      
      // Set center to user location if no center is set
      if (_center == null) {
        _center = LatLng(widget.userLatitude!, widget.userLongitude!);
      }
    }

    // Add store markers
    for (int i = 0; i < widget.stores.length; i++) {
      final store = widget.stores[i];
      final markerId = MarkerId('store_${store.id}');
      
      _markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(store.latitudeDouble, store.longitudeDouble),
          icon: _getStoreMarkerIcon(store),
          infoWindow: InfoWindow(
            title: store.name,
            snippet: '${store.account.name} • ${store.distanceText}',
          ),
          onTap: () {
            if (widget.onStoreTap != null) {
              widget.onStoreTap!(store);
            }
          },
        ),
      );
    }

    // Set center to first store if no user location
    if (_center == null && widget.stores.isNotEmpty) {
      final firstStore = widget.stores.first;
      _center = LatLng(firstStore.latitudeDouble, firstStore.longitudeDouble);
    }

    setState(() {});
  }

  BitmapDescriptor _getStoreMarkerIcon(Store store) {
    if (store.isApproved) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (store.isPending) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    // Handle map tap if needed
  }

  void _onCameraMove(CameraPosition position) {
    // Handle camera move if needed
  }

  void _onCameraIdle() {
    // Handle camera idle if needed
  }


  void _animateToUserLocation() {
    if (_mapController != null && 
        widget.userLatitude != null && 
        widget.userLongitude != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.userLatitude!, widget.userLongitude!),
          widget.initialZoom,
        ),
      );
    }
  }

  void _fitBounds() {
    if (_mapController != null && widget.stores.isNotEmpty) {
      final bounds = _calculateBounds();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _calculateBounds() {
    double minLat = widget.stores.first.latitudeDouble;
    double maxLat = widget.stores.first.latitudeDouble;
    double minLng = widget.stores.first.longitudeDouble;
    double maxLng = widget.stores.first.longitudeDouble;

    for (final store in widget.stores) {
      minLat = minLat < store.latitudeDouble ? minLat : store.latitudeDouble;
      maxLat = maxLat > store.latitudeDouble ? maxLat : store.latitudeDouble;
      minLng = minLng < store.longitudeDouble ? minLng : store.longitudeDouble;
      maxLng = maxLng > store.longitudeDouble ? maxLng : store.longitudeDouble;
    }

    // Include user location if available
    if (widget.userLatitude != null && widget.userLongitude != null) {
      minLat = minLat < widget.userLatitude! ? minLat : widget.userLatitude!;
      maxLat = maxLat > widget.userLatitude! ? maxLat : widget.userLatitude!;
      minLng = minLng < widget.userLongitude! ? minLng : widget.userLongitude!;
      maxLng = maxLng > widget.userLongitude! ? maxLng : widget.userLongitude!;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_center == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat peta...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
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
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center!,
                zoom: widget.initialZoom,
              ),
              markers: _markers,
              onTap: _onMapTap,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              compassEnabled: true,
            ),
            
            // Map controls
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Fit bounds button
                  if (widget.stores.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _fitBounds,
                        icon: const Icon(Icons.fit_screen),
                        tooltip: 'Tampilkan semua store',
                      ),
                    ),
                  
                  // User location button
                  if (widget.showUserLocation && 
                      widget.userLatitude != null && 
                      widget.userLongitude != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _animateToUserLocation,
                        icon: const Icon(Icons.my_location),
                        tooltip: 'Lokasi saya',
                      ),
                    ),
                ],
              ),
            ),
            
            // Legend
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Legenda',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      icon: Icons.store,
                      color: Colors.green,
                      label: 'Approved',
                    ),
                    _buildLegendItem(
                      icon: Icons.store_outlined,
                      color: Colors.orange,
                      label: 'Pending',
                    ),
                    _buildLegendItem(
                      icon: Icons.store_mall_directory_outlined,
                      color: Colors.red,
                      label: 'Other',
                    ),
                    if (widget.showUserLocation)
                      _buildLegendItem(
                        icon: Icons.my_location,
                        color: Colors.blue,
                        label: 'Lokasi Anda',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
