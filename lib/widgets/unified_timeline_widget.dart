import 'package:flutter/material.dart';
import '../models/attendance_record.dart';

class UnifiedTimelineWidget extends StatelessWidget {
  final AttendanceRecord? attendanceRecord;

  const UnifiedTimelineWidget({
    super.key,
    this.attendanceRecord,
  });

  @override
  Widget build(BuildContext context) {
    if (attendanceRecord == null) {
      return _buildEmptyTimeline();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineContent(),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No activity today',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineContent() {
    final events = _generateTimelineEvents();
    
    return Column(
      children: [
        for (int i = 0; i < events.length; i++)
          _buildTimelineItem(
            event: events[i],
            isFirst: i == 0,
            isLast: i == events.length - 1,
          ),
      ],
    );
  }

  List<TimelineEvent> _generateTimelineEvents() {
    final events = <TimelineEvent>[];
    
    // Check-in event
    if (attendanceRecord!.checkInTime != null) {
      events.add(TimelineEvent(
        time: attendanceRecord!.checkInTime!,
        title: 'Check In',
        subtitle: attendanceRecord!.storeName ?? 'Unknown Store',
        icon: Icons.login,
        color: Colors.green,
        isCompleted: true,
      ));
    }

    // No break functionality - removed all break-related events

    // Check-out event
    if (attendanceRecord!.checkOutTime != null) {
      events.add(TimelineEvent(
        time: attendanceRecord!.checkOutTime!,
        title: 'Check Out',
        subtitle: 'Work completed',
        icon: Icons.logout,
        color: Colors.red,
        isCompleted: true,
      ));
    } else if (attendanceRecord!.isCheckedIn) {
      // Show expected check-out as pending
      events.add(TimelineEvent(
        time: DateTime.now(),
        title: 'Check Out',
        subtitle: 'Pending',
        icon: Icons.logout,
        color: Colors.grey,
        isCompleted: false,
      ));
    }

    // Sort events by time
    events.sort((a, b) => a.time.compareTo(b.time));
    
    return events;
  }

  Widget _buildTimelineItem({
    required TimelineEvent event,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event.isActive 
                    ? event.color.withOpacity(0.2)
                    : event.isCompleted 
                        ? event.color 
                        : Colors.grey[300],
                shape: BoxShape.circle,
                border: event.isActive 
                    ? Border.all(color: event.color, width: 2)
                    : null,
              ),
              child: Icon(
                event.icon,
                color: event.isActive
                    ? event.color
                    : event.isCompleted 
                        ? Colors.white 
                        : Colors.grey[600],
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Event content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: event.isActive ? event.color : Colors.black87,
                      ),
                    ),
                    Text(
                      _formatTime(event.time),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (event.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      event.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class TimelineEvent {
  final DateTime time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isActive;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isCompleted,
    this.isActive = false,
  });
}
