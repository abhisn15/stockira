import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/attendance_record.dart';

class AttendanceDetailMapsScreen extends StatefulWidget {
  final AttendanceDetail detail;
  final Map<int, String> storeCodeMap;
  final Map<int, String> storeAddressMap;

  const AttendanceDetailMapsScreen({
    super.key,
    required this.detail,
    required this.storeCodeMap,
    required this.storeAddressMap,
  });

  @override
  State<AttendanceDetailMapsScreen> createState() => _AttendanceDetailMapsScreenState();
}

class _AttendanceDetailMapsScreenState extends State<AttendanceDetailMapsScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _showDetailCard = true;
  int _selectedTabIndex = 0; // 0 for Photo, 1 for Notes

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _updateMarkers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateMarkers() async {
    final markers = <Marker>{};
    
    // Create custom store icon
    final storeIcon = await _createStoreIcon();
    
    // Add store marker
    markers.add(
      Marker(
        markerId: MarkerId('store_${widget.detail.storeId}'),
        position: LatLng(widget.detail.latitudeIn, widget.detail.longitudeIn),
        icon: storeIcon,
        infoWindow: InfoWindow(
          title: widget.detail.storeName,
          snippet: widget.storeAddressMap[widget.detail.storeId] ?? 'Address not available',
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });

    // Move camera to store location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.detail.latitudeIn, widget.detail.longitudeIn),
          16.0,
        ),
      );
    }
  }

  Future<BitmapDescriptor> _createStoreIcon() async {
    // Create a custom icon for the store
    // For now, we'll use a default marker with custom hue
    // In a real app, you might want to create a custom bitmap
    return BitmapDescriptor.defaultMarkerWithHue(
      widget.detail.isApproved ? BitmapDescriptor.hueCyan : BitmapDescriptor.hueOrange,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _calculateDuration() {
    if (widget.detail.checkOutTime == null) return '0 hours 0 minutes';
    
    final checkIn = widget.detail.checkInTime;
    final checkOut = widget.detail.checkOutTime!;
    
    final checkInMinutes = checkIn.hour * 60 + checkIn.minute;
    final checkOutMinutes = checkOut.hour * 60 + checkOut.minute;
    
    int durationMinutes = checkOutMinutes - checkInMinutes;
    if (durationMinutes < 0) {
      durationMinutes += 24 * 60; // Handle day rollover
    }
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    return '$hours hours $minutes minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _updateMarkers();
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.detail.latitudeIn, widget.detail.longitudeIn),
              zoom: 16.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Top app bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF29BDCE), Color(0xFF1E9BA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.detail.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Store Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showDetailCard = !_showDetailCard;
                        });
                        if (_showDetailCard) {
                          _animationController.forward();
                        } else {
                          _animationController.reverse();
                        }
                      },
                      icon: Icon(
                        _showDetailCard ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detail card
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: _showDetailCard ? 0 : -400,
                child: Transform.translate(
                  offset: Offset(0, (1 - _slideAnimation.value) * 400),
                  child: _buildDetailCard(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.5; // 50% of screen height
    
    return Container(
      height: cardHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
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

          // Profile picture (circular, overlapping)
          Positioned(
            top: -5,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.detail.imageUrlIn != null
                      ? Image.network(
                          widget.detail.imageUrlIn!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF29BDCE),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFF29BDCE),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.detail.isApproved 
                                ? [const Color(0xFF29BDCE), const Color(0xFF1E9BA8)]
                                : [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.detail.storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.storeAddressMap[widget.detail.storeId] ?? 'Address not available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Distance and duration
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Jarak Lokasi Checkout',
                          '0,74 Meter', // This would be calculated from actual coordinates
                          Icons.location_on,
                          const Color(0xFF29BDCE),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Duration',
                          _calculateDuration(),
                          Icons.access_time,
                          const Color(0xFF1E9BA8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Check-in/out times
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeItem(
                          'IN',
                          _formatTime(widget.detail.checkInTime),
                          Icons.login,
                          const Color(0xFF29BDCE),
                        ),
                      ),
                      if (widget.detail.checkOutTime != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeItem(
                            'OUT',
                            _formatTime(widget.detail.checkOutTime!),
                            Icons.logout,
                            const Color(0xFF1E9BA8),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tabs for Photo and Notes
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0 ? const Color(0xFF29BDCE) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Photo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedTabIndex == 0 ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 1 ? const Color(0xFF29BDCE) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Catatan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedTabIndex == 1 ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab content
                  if (_selectedTabIndex == 0) _buildPhotoTab(),
                  if (_selectedTabIndex == 1) _buildNotesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    final photos = <Map<String, dynamic>>[];
    
    if (widget.detail.imageUrlIn != null) {
      photos.add({
        'url': widget.detail.imageUrlIn!,
        'label': 'Check-in Photo',
        'color': const Color(0xFF29BDCE),
      });
    }
    
    if (widget.detail.imageUrlOut != null) {
      photos.add({
        'url': widget.detail.imageUrlOut!,
        'label': 'Check-out Photo',
        'color': const Color(0xFF1E9BA8),
      });
    }

    if (photos.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No photos available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 200,
          child: PageView.builder(
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = photos[index];
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: photo['color'].withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Photo label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: photo['color'].withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        photo['label'],
                        style: TextStyle(
                          color: photo['color'],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Photo
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          photo['url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Slide indicators
        if (photos.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedTabIndex == index 
                      ? const Color(0xFF29BDCE) 
                      : Colors.grey[300],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check-in notes
          if (widget.detail.noteIn != null && widget.detail.noteIn!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.login, size: 16, color: const Color(0xFF29BDCE)),
                const SizedBox(width: 6),
                Text(
                  'Checkin Notes:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.detail.noteIn!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (widget.detail.noteOut != null && widget.detail.noteOut!.isNotEmpty)
              const SizedBox(height: 12),
          ],
          
          // Check-out notes
          if (widget.detail.noteOut != null && widget.detail.noteOut!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.logout, size: 16, color: const Color(0xFF1E9BA8)),
                const SizedBox(width: 6),
                Text(
                  'Checkout Notes:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.detail.noteOut!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          // Show message if no notes
          if ((widget.detail.noteIn == null || widget.detail.noteIn!.isEmpty) &&
              (widget.detail.noteOut == null || widget.detail.noteOut!.isEmpty))
            Center(
              child: Text(
                'No notes available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
