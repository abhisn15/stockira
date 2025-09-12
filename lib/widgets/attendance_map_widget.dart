import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/attendance_record.dart';

class AttendanceMapWidget extends StatefulWidget {
  final List<AttendanceRecord> attendanceRecords;
  final DateTime selectedDate;
  final Map<int, String> storeCodeMap;
  final Map<int, String> storeAddressMap;
  final Function(AttendanceDetail)? onStoreSelected;

  const AttendanceMapWidget({
    super.key,
    required this.attendanceRecords,
    required this.selectedDate,
    required this.storeCodeMap,
    required this.storeAddressMap,
    this.onStoreSelected,
  });

  @override
  State<AttendanceMapWidget> createState() => _AttendanceMapWidgetState();
}

class _AttendanceMapWidgetState extends State<AttendanceMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  AttendanceDetail? _selectedDetail;

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(AttendanceMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.attendanceRecords != widget.attendanceRecords) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    final recordsForDate = widget.attendanceRecords.where((record) {
      return record.date.year == widget.selectedDate.year &&
             record.date.month == widget.selectedDate.month &&
             record.date.day == widget.selectedDate.day;
    }).toList();

    final markers = <Marker>{};
    LatLngBounds? bounds;

    for (final record in recordsForDate) {
      for (final detail in record.details) {
        // Skip if coordinates are not available (they are required fields)
        
        try {
          final lat = detail.latitudeIn;
          final lng = detail.longitudeIn;
          final position = LatLng(lat, lng);

          // Update bounds
          if (bounds == null) {
            bounds = LatLngBounds(southwest: position, northeast: position);
          } else {
            bounds = LatLngBounds(
              southwest: LatLng(
                math.min(bounds.southwest.latitude, position.latitude),
                math.min(bounds.southwest.longitude, position.longitude),
              ),
              northeast: LatLng(
                math.max(bounds.northeast.latitude, position.latitude),
                math.max(bounds.northeast.longitude, position.longitude),
              ),
            );
          }

          final isApproved = detail.isApproved;
          final markerId = MarkerId('store_${detail.storeId}');

          markers.add(
            Marker(
              markerId: markerId,
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isApproved ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: detail.storeName,
                snippet: isApproved ? 'Visited' : 'In Progress',
                onTap: () => _onMarkerTapped(detail),
              ),
              onTap: () => _onMarkerTapped(detail),
            ),
          );
        } catch (e) {
          print('Error parsing coordinates for store ${detail.storeId}: $e');
        }
      }
    }

    setState(() {
      _markers = markers;
    });

    // Move camera to show all markers
    if (bounds != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  void _onMarkerTapped(AttendanceDetail detail) {
    setState(() {
      _selectedDetail = detail;
    });
    
    if (widget.onStoreSelected != null) {
      widget.onStoreSelected!(detail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateMarkers();
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(-6.200000, 106.816666), // Jakarta default
                zoom: 12.0,
              ),
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
            ),
            
            // Top overlay with date
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFF29BDCE),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29BDCE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_markers.length} stores',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF29BDCE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom overlay with filter buttons
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton(
                        'Visited',
                        _getVisitedCount(),
                        Colors.green,
                        true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        'Unvisited',
                        _getUnvisitedCount(),
                        Colors.orange,
                        false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        '< 5 Min',
                        _getShortVisitCount(),
                        Colors.blue,
                        false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Selected store info popup
            if (_selectedDetail != null)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: _buildStoreInfoPopup(_selectedDetail!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, int count, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Handle filter tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoPopup(AttendanceDetail detail) {
    final isApproved = detail.isApproved;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green : Colors.orange,
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
                      detail.storeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isApproved ? 'Visited' : 'In Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isApproved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDetail = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'IN: ${_formatTime(detail.checkInTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              if (detail.checkOutTime != null) ...[
                const SizedBox(width: 12),
                Text(
                  'OUT: ${_formatTime(detail.checkOutTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int _getVisitedCount() {
    final recordsForDate = widget.attendanceRecords.where((record) {
      return record.date.year == widget.selectedDate.year &&
             record.date.month == widget.selectedDate.month &&
             record.date.day == widget.selectedDate.day;
    }).toList();

    return recordsForDate
        .expand((record) => record.details)
        .where((detail) => detail.isApproved)
        .length;
  }

  int _getUnvisitedCount() {
    final recordsForDate = widget.attendanceRecords.where((record) {
      return record.date.year == widget.selectedDate.year &&
             record.date.month == widget.selectedDate.month &&
             record.date.day == widget.selectedDate.day;
    }).toList();

    return recordsForDate
        .expand((record) => record.details)
        .where((detail) => !detail.isApproved)
        .length;
  }

  int _getShortVisitCount() {
    final recordsForDate = widget.attendanceRecords.where((record) {
      return record.date.year == widget.selectedDate.year &&
             record.date.month == widget.selectedDate.month &&
             record.date.day == widget.selectedDate.day;
    }).toList();

    return recordsForDate
        .expand((record) => record.details)
        .where((detail) {
          if (detail.checkOutTime == null) return false;
          final checkInMinutes = detail.checkInTime.hour * 60 + detail.checkInTime.minute;
          final checkOutMinutes = detail.checkOutTime!.hour * 60 + detail.checkOutTime!.minute;
          int durationMinutes = checkOutMinutes - checkInMinutes;
          if (durationMinutes < 0) durationMinutes += 24 * 60; // Handle day rollover
          return durationMinutes < 5;
        })
        .length;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
