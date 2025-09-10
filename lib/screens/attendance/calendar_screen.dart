import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_record.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  late final ValueNotifier<List<AttendanceRecord>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final AttendanceService _attendanceService = AttendanceService();
  
  // Sample data - replace with actual API data
  Map<DateTime, List<AttendanceRecord>> _events = {};
  

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    try {
      // Load attendance data for the current month
      final records = await _attendanceService.getAttendanceRecordsForMonth(DateTime.now());
      
      // Group records by date
      _events = {};
      for (final record in records) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        if (_events[date] == null) {
          _events[date] = [];
        }
        _events[date]!.add(record);
      }
      
      setState(() {});
    } catch (e) {
      print('Error loading attendance data: $e');
    }
  }

  List<AttendanceRecord> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  Color _getAttendanceStatusColor(AttendanceRecord record) {
    switch (record.status) {
      case 'completed':
        return Colors.green;
      case 'permit':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'no_activity':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEventMarker(AttendanceRecord event) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getAttendanceStatusColor(event),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildWeeklyCard(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekEvents = <AttendanceRecord>[];
    
    // Collect all events for the week
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      weekEvents.addAll(_getEventsForDay(day));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week ${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _showCalendarPopup(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Weekly calendar grid
            Row(
              children: List.generate(7, (index) {
                final day = weekStart.add(Duration(days: index));
                final dayEvents = _getEventsForDay(day);
                final isToday = isSameDay(day, DateTime.now());
                final isSelected = isSameDay(day, _selectedDay);
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onDaySelected(day, day),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color.fromARGB(255, 41, 189, 206)
                            : isToday 
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday 
                            ? Border.all(color: Colors.blue, width: 1)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (dayEvents.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dayEvents.take(3).map((event) => 
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  child: _buildEventMarker(event),
                                ),
                              ).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (weekEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Store Visits (${weekEvents.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...weekEvents.take(3).map((event) => 
                _buildStoreVisitItem(event),
              ),
              if (weekEvents.length > 3)
                TextButton(
                  onPressed: () => _showStoreProgressBottomSheet(weekEvents),
                  child: Text('View all ${weekEvents.length} visits'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoreVisitItem(AttendanceRecord event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getAttendanceStatusColor(event),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.storeName ?? 'Unknown Store',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${event.checkInTime?.hour.toString().padLeft(2, '0') ?? '--'}:${event.checkInTime?.minute.toString().padLeft(2, '0') ?? '--'} - ${event.checkOutTime?.hour.toString().padLeft(2, '0') ?? '--'}:${event.checkOutTime?.minute.toString().padLeft(2, '0') ?? '--'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map, size: 20),
            onPressed: () => _openGoogleMaps(event.latitude, event.longitude, event.storeName),
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps(double? latitude, double? longitude, String? storeName) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data not available')),
      );
      return;
    }
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  void _showCalendarPopup() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attendance Calendar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TableCalendar<AttendanceRecord>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((event) => 
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              child: _buildEventMarker(event),
                            ),
                          ).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoreProgressBottomSheet(List<AttendanceRecord> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Store Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildStoreProgressCard(event);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProgressCard(AttendanceRecord event) {
    final duration = event.checkOutTime != null && event.checkInTime != null
        ? event.checkOutTime!.difference(event.checkInTime!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getAttendanceStatusColor(event),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.storeName ?? 'Unknown Store',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () => _openGoogleMaps(event.latitude, event.longitude, event.storeName),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Check-in: ${event.checkInTime?.hour.toString().padLeft(2, '0') ?? '--'}:${event.checkInTime?.minute.toString().padLeft(2, '0') ?? '--'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (event.checkOutTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.logout, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Check-out: ${event.checkOutTime?.hour.toString().padLeft(2, '0') ?? '--'}:${event.checkOutTime?.minute.toString().padLeft(2, '0') ?? '--'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (duration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${duration.inHours}h ${duration.inMinutes % 60}m',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.storeAddress ?? 'No address available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (event.note != null && event.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.note!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Present'),
                _buildLegendItem(Colors.orange, 'Permit'),
                _buildLegendItem(Colors.grey, 'No Activity'),
                _buildLegendItem(Colors.red, 'Absent'),
              ],
            ),
          ),
          // Weekly cards
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Show 4 weeks
              itemBuilder: (context, index) {
                final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + (index * 7)));
                return _buildWeeklyCard(weekStart);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
