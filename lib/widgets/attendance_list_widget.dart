import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../screens/attendance/Detail/index.dart';

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
        border: Border.all(
          color: Colors.grey[400]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF29BDCE), Color(0xFF1E9BA8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDate(record.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${record.details.length} Visits',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Store visits list
            if (record.details.isNotEmpty) ...[
              Text(
                'Store Visits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              ...record.details.map((detail) => _buildDetailItem(context, detail)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, AttendanceDetail detail) {
    final isApproved = detail.isApproved;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved ? Colors.green.withOpacity(0.3) : const Color(0xFF29BDCE).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isApproved 
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : [const Color(0xFF29BDCE), const Color(0xFF1E9BA8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isApproved ? Icons.check_circle : Icons.access_time,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isApproved ? 'Visited' : 'In Progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Duration: ${_formatTime(_calculateDetailDuration(detail))}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Store info section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF29BDCE).withOpacity(0.1),
                            const Color(0xFF1E9BA8).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF29BDCE).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 28,
                        color: Color(0xFF29BDCE),
                      ),
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
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF29BDCE).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Code: ${storeCodeMap[detail.storeId] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF29BDCE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  storeAddressMap[detail.storeId] ?? 'Address not available',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text("IN: " + (detail.checkInTime?.toString().substring(10,15) ?? 'N/A'), style: TextStyle(fontSize: 13, color: const Color.fromARGB(255, 26, 176, 0)),),
                              SizedBox(width: 8),
                              Text("OUT: " + (detail.checkOutTime?.toString().substring(10,15) ?? 'N/A'), style: TextStyle(fontSize: 13, color: const Color.fromARGB(255, 222, 53, 53)),),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Time and duration info
                Row(
                  children: [
                    // Expanded(
                    //   child: _buildTimeInfoForDetail(
                    //     'IN',
                    //     detail.checkInTime!,
                    //     Icons.login,
                    //     const Color(0xFF29BDCE),
                    //   ),
                    // ),
                    // const SizedBox(width: 8),
                    // Expanded(
                    //   child: _buildTimeInfoForDetail(
                    //     'OUT',
                    //     detail.checkOutTime!,
                    //     Icons.access_time,
                    //     Colors.blue,
                    //   ),
                    // ),
                    // Expanded(
                    //   child: _buildTimeInfoForDetail(
                    //     'Duration',
                    //     _calculateDetailDuration(detail),
                    //     Icons.access_time,
                    //     Colors.blue,
                    //   ),
                    // ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showStoreDetailDialog(context, detail),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF29BDCE).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF29BDCE).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    color: const Color(0xFF29BDCE),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Detail',
                                    style: TextStyle(
                                      color: const Color(0xFF29BDCE),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showMapsView(context, detail),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    color: Colors.orange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Maps',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }


  TimeOfDay _calculateDetailDuration(AttendanceDetail detail) {
    if (detail.checkOutTime == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    
    final checkIn = detail.checkInTime;
    final checkOut = detail.checkOutTime!;
    
    // Convert TimeOfDay to minutes for calculation
    final checkInMinutes = checkIn.hour * 60 + checkIn.minute;
    final checkOutMinutes = checkOut.hour * 60 + checkOut.minute;
    
    int durationMinutes = checkOutMinutes - checkInMinutes;
    if (durationMinutes < 0) {
      durationMinutes += 24 * 60; // Handle day rollover
    }
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    return TimeOfDay(hour: hours, minute: minutes);
  }

  void _showStoreDetailDialog(BuildContext context, AttendanceDetail detail) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF29BDCE), Color(0xFF1E9BA8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 24,
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Code: ${storeCodeMap[detail.storeId] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic info
                      _buildInfoRow('Check In', _formatTime(detail.checkInTime), Icons.login, const Color(0xFF29BDCE)),
                      if (detail.checkOutTime != null)
                        _buildInfoRow('Check Out', _formatTime(detail.checkOutTime!), Icons.logout, Colors.orange),
                      _buildInfoRow('Status', detail.isApproved ? 'Approved' : 'Pending', 
                          detail.isApproved ? Icons.check_circle : Icons.access_time, 
                          detail.isApproved ? Colors.green : Colors.orange),
                      
                      const SizedBox(height: 20),
                      
                      // Photos section with slides
                      if (detail.imageUrlIn != null || detail.imageUrlOut != null) ...[
                        Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPhotosSlider(detail),
                        const SizedBox(height: 20),
                      ],
                      
                      // Notes section with slides
                      if ((detail.noteIn != null && detail.noteIn!.isNotEmpty) || 
                          (detail.noteOut != null && detail.noteOut!.isNotEmpty)) ...[
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNotesSlider(detail),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showMapsView(BuildContext context, AttendanceDetail detail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceDetailMapsScreen(
          detail: detail,
          storeCodeMap: storeCodeMap,
          storeAddressMap: storeAddressMap,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSlider(AttendanceDetail detail) {
    final photos = <Map<String, dynamic>>[];
    
    if (detail.imageUrlIn != null) {
      photos.add({
        'url': detail.imageUrlIn!,
        'label': 'Check-in Photo',
        'color': const Color(0xFF29BDCE),
        'icon': Icons.login,
      });
    }
    
    if (detail.imageUrlOut != null) {
      photos.add({
        'url': detail.imageUrlOut!,
        'label': 'Check-out Photo',
        'color': Colors.orange,
        'icon': Icons.logout,
      });
    }

    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      child: PageView.builder(
        itemCount: photos.length,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(photo['icon'], color: photo['color'], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        photo['label'],
                        style: TextStyle(
                          color: photo['color'],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
    );
  }

  Widget _buildNotesSlider(AttendanceDetail detail) {
    final notes = <Map<String, dynamic>>[];
    
    if (detail.noteIn != null && detail.noteIn!.isNotEmpty) {
      notes.add({
        'text': detail.noteIn!,
        'label': 'Check-in Note',
        'color': const Color(0xFF29BDCE),
        'icon': Icons.login,
      });
    }
    
    if (detail.noteOut != null && detail.noteOut!.isNotEmpty) {
      notes.add({
        'text': detail.noteOut!,
        'label': 'Check-out Note',
        'color': Colors.orange,
        'icon': Icons.logout,
      });
    }

    if (notes.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      child: PageView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: note['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: note['color'].withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note label
                Row(
                  children: [
                    Icon(note['icon'], color: note['color'], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      note['label'],
                      style: TextStyle(
                        color: note['color'],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Note text
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      note['text'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}