import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/attendance_record.dart';

class AttendanceMapsScreen extends StatefulWidget {
  final List<AttendanceRecord> attendanceRecords;
  final DateTime selectedDate;
  final Map<int, String> storeCodeMap;
  final Map<int, String> storeAddressMap;

  const AttendanceMapsScreen({
    super.key,
    required this.attendanceRecords,
    required this.selectedDate,
    required this.storeCodeMap,
    required this.storeAddressMap,
  });

  @override
  State<AttendanceMapsScreen> createState() => _AttendanceMapsScreenState();
}

class _AttendanceMapsScreenState extends State<AttendanceMapsScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  AttendanceDetail? _selectedDetail;
  String _selectedFilter = 'all'; // all, visited, unvisited, short

  @override
  void initState() {
    super.initState();
    _updateMarkers();
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
        // Apply filter
        if (_selectedFilter == 'visited' && !detail.isApproved) continue;
        if (_selectedFilter == 'unvisited' && detail.isApproved) continue;
        if (_selectedFilter == 'short' && !_isShortVisit(detail)) continue;

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
                isApproved
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
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

  bool _isShortVisit(AttendanceDetail detail) {
    if (detail.checkOutTime == null) return false;
    final checkInMinutes =
        detail.checkInTime.hour * 60 + detail.checkInTime.minute;
    final checkOutMinutes =
        detail.checkOutTime!.hour * 60 + detail.checkOutTime!.minute;
    int durationMinutes = checkOutMinutes - checkInMinutes;
    if (durationMinutes < 0) durationMinutes += 24 * 60; // Handle day rollover
    return durationMinutes < 5;
  }

  void _onMarkerTapped(AttendanceDetail detail) {
    setState(() {
      _selectedDetail = detail;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _updateMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
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
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            mapType: MapType.normal,
          ),

          // Top app bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Map',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(widget.selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF29BDCE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_markers.length} stores',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF29BDCE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
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
                      'All',
                      _getAllCount(),
                      Colors.grey,
                      _selectedFilter == 'all',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      'Visited',
                      _getVisitedCount(),
                      Colors.green,
                      _selectedFilter == 'visited',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      'Unvisited',
                      _getUnvisitedCount(),
                      Colors.orange,
                      _selectedFilter == 'unvisited',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      '< 5 Min',
                      _getShortVisitCount(),
                      Colors.blue,
                      _selectedFilter == 'short',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected store info popup
          if (_selectedDetail != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildStoreInfoPopup(_selectedDetail!),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    int count,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _onFilterChanged(label.toLowerCase().replaceAll(' ', '')),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.storeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Store Code: ${widget.storeCodeMap[detail.storeId] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isApproved ? 'Visited' : 'In Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isApproved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
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
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close, color: Colors.grey[600], size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Address: ${widget.storeAddressMap[detail.storeId] ?? 'Not available'}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'IN: ${_formatTime(detail.checkInTime)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              if (detail.checkOutTime != null) ...[
                const SizedBox(width: 16),
                Text(
                  'OUT: ${_formatTime(detail.checkOutTime!)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
          if ((detail.noteIn != null && detail.noteIn!.isNotEmpty) ||
              (detail.noteOut != null && detail.noteOut!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 if (detail.noteIn != null && detail.noteIn!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.login, size: 14, color: const Color(0xFF29BDCE)),
                        const SizedBox(width: 6),
                        Text(
                          'Check-in Note:',
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
                      detail.noteIn!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (detail.noteOut != null && detail.noteOut!.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                  
                  // Check-out note
                  if (detail.noteOut != null && detail.noteOut!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.logout, size: 14, color: Colors.orange[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Check-out Note:',
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
                      detail.noteOut!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getAllCount() {
    final recordsForDate = widget.attendanceRecords.where((record) {
      return record.date.year == widget.selectedDate.year &&
          record.date.month == widget.selectedDate.month &&
          record.date.day == widget.selectedDate.day;
    }).toList();

    return recordsForDate.expand((record) => record.details).length;
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
        .where((detail) => _isShortVisit(detail))
        .length;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
