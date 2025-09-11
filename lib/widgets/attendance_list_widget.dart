import 'package:flutter/material.dart';
import '../models/attendance_record.dart';

class AttendanceListWidget extends StatelessWidget {
  final List<AttendanceRecord> attendanceRecords;
  final DateTime selectedDate;
  final Map<int, String> storeCodeMap;
  final Map<int, String> storeAddressMap;

  const AttendanceListWidget({
    super.key,
    required this.attendanceRecords,
    required this.selectedDate,
    required this.storeCodeMap,
    required this.storeAddressMap,
  });

  @override
  Widget build(BuildContext context) {
    final recordsForDate = attendanceRecords.where((record) {
      return record.date.year == selectedDate.year &&
             record.date.month == selectedDate.month &&
             record.date.day == selectedDate.day;
    }).toList();

    if (recordsForDate.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Details - ${_formatDate(selectedDate)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...recordsForDate.map((record) => _buildAttendanceCard(context, record)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No attendance records',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'for ${_formatDate(selectedDate)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceRecord record) {
    final storeVisits = record.details.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with employee info and progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    record.employeeName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.employeeName ?? 'Unknown Employee',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$storeVisits store${storeVisits != 1 ? 's' : ''} visited',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Store visits list
          if (record.details.isNotEmpty) ...[
            ...record.details.map((detail) => _buildStoreVisitItem(context, detail)),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No store visits recorded',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreVisitItem(BuildContext context, AttendanceDetail detail) {
    final hasCheckOut = detail.checkOutTime != null;
    final duration = hasCheckOut ? _calculateDuration(detail.checkInTime, detail.checkOutTime!) : null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header with image
          Row(
            children: [
              // Store image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 70,
                  height: 100,
                  color: Colors.grey[200],
                  child: detail.imageUrlIn != null
                      ? Image.network(
                          detail.imageUrlIn!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.store,
                              size: 30,
                              color: Colors.grey[400],
                            );
                          },
                        )
                      : Icon(
                          Icons.store,
                          size: 30,
                          color: Colors.grey[400],
                        ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${storeCodeMap[detail.storeId] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (detail.distanceIn != null)
                      Text(
                        'Distance: ${detail.distanceIn!.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (storeAddressMap[detail.storeId] != null)
                      Text(
                        'Address: ${storeAddressMap[detail.storeId]?.substring(1, 40)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (detail.checkInTime != null && detail.checkOutTime != null)
                      Text(
                        'Time: ${detail.checkInTime!.hour.toString().padLeft(2, '0')}:${detail.checkInTime!.minute.toString().padLeft(2, '0')} - ${detail.checkOutTime!.hour.toString().padLeft(2, '0')}:${detail.checkOutTime!.minute.toString().padLeft(2, '0')} ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: hasCheckOut ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasCheckOut ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: hasCheckOut ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Time and duration info
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  'Check In',
                  detail.checkInTime,
                  Icons.login,
                  Colors.green,
                ),
              ),
              if (hasCheckOut) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeInfo(
                    'Check Out',
                    detail.checkOutTime!,
                    Icons.logout,
                    Colors.red,
                  ),
                ),
              ],
              if (duration != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDurationInfo(duration),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // View details button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showStoreDetailDialog(context, detail),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                side: BorderSide(color: Colors.blue[200]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, TimeOfDay time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo(String duration) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer, size: 16, color: Colors.purple),
          const SizedBox(height: 4),
          const Text(
            'Duration',
            style: TextStyle(
              fontSize: 10,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            duration,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    if (durationMinutes < 0) return '0m';
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showStoreDetailDialog(BuildContext context, AttendanceDetail detail) {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2, // Photo and Note tabs
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with store info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Colors.blue[600]),
                      const SizedBox(width: 8),
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
                            Text(
                              'Code: ${storeCodeMap[detail.storeId] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: TabBar(
                    labelColor: Colors.blue[600],
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.blue[600],
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.photo_camera, size: 20),
                        text: 'Photos',
                      ),
                      Tab(
                        icon: Icon(Icons.note, size: 20),
                        text: 'Notes',
                      ),
                    ],
                  ),
                ),

                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    children: [
                      // Photos Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store info
                            _buildDetailRow('Check In Time', '${detail.checkInTime.hour.toString().padLeft(2, '0')}:${detail.checkInTime.minute.toString().padLeft(2, '0')}'),
                            if (detail.checkOutTime != null)
                              _buildDetailRow('Check Out Time', '${detail.checkOutTime!.hour.toString().padLeft(2, '0')}:${detail.checkOutTime!.minute.toString().padLeft(2, '0')}'),
                            if (detail.distanceIn != null)
                              _buildDetailRow('Distance In', '${detail.distanceIn!.toStringAsFixed(1)} meters'),
                            if (detail.distanceOut != null)
                              _buildDetailRow('Distance Out', '${detail.distanceOut!.toStringAsFixed(1)} meters'),
                            _buildDetailRow('Latitude In', '${detail.latitudeIn.toStringAsFixed(6)}'),
                            _buildDetailRow('Longitude In', '${detail.longitudeIn.toStringAsFixed(6)}'),
                            if (detail.latitudeOut != null)
                              _buildDetailRow('Latitude Out', '${detail.latitudeOut!.toStringAsFixed(6)}'),
                            if (detail.longitudeOut != null)
                              _buildDetailRow('Longitude Out', '${detail.longitudeOut!.toStringAsFixed(6)}'),
                            if (storeAddressMap[detail.storeId] != null)
                              _buildDetailRow('Store Address', '${storeAddressMap[detail.storeId]}'),

                            _buildDetailRow('Duration', detail.checkOutTime != null
                                ? _calculateDuration(detail.checkInTime, detail.checkOutTime!)
                                : 'In progress'),

                            const SizedBox(height: 16),

                            // Photos section
                            if (detail.imageUrlIn != null || detail.imageUrlOut != null) ...[
                              const Text(
                                'Photos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (detail.imageUrlIn != null) ...[
                                _buildImageCard('Check In Photo', detail.imageUrlIn!),
                                const SizedBox(height: 12),
                              ],
                              if (detail.imageUrlOut != null) ...[
                                _buildImageCard('Check Out Photo', detail.imageUrlOut!),
                              ],
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(Icons.photo_camera, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No photos available',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Notes Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Notes section
                            if (detail.noteIn != null || detail.noteOut != null) ...[
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (detail.noteIn != null) ...[
                                _buildNoteCard('Check In Note', detail.noteIn!, Colors.green),
                                const SizedBox(height: 12),
                              ],
                              if (detail.noteOut != null) ...[
                                _buildNoteCard('Check Out Note', detail.noteOut!, Colors.red),
                              ],
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No notes available',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String title, String note, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
