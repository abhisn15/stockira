import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/timeline_event.dart';
import 'loading_skeleton_widget.dart';

class LazyLoadingTimelineWidget extends StatefulWidget {
  final AttendanceRecord? attendanceRecord;
  final Future<List<TimelineEvent>> Function()? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final String? loadingMessage;

  const LazyLoadingTimelineWidget({
    super.key,
    this.attendanceRecord,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = false,
    this.loadingMessage,
  });

  @override
  State<LazyLoadingTimelineWidget> createState() => _LazyLoadingTimelineWidgetState();
}

class _LazyLoadingTimelineWidgetState extends State<LazyLoadingTimelineWidget> {
  final List<TimelineEvent> _events = [];
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialEvents();
  }

  @override
  void didUpdateWidget(LazyLoadingTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceRecord != widget.attendanceRecord) {
      _loadInitialEvents();
    }
  }

  void _loadInitialEvents() {
    if (widget.attendanceRecord != null) {
      setState(() {
        _events.clear();
        _hasError = false;
        _errorMessage = null;
      });
      _generateInitialEvents();
    }
  }

  void _generateInitialEvents() {
    final events = <TimelineEvent>[];
    
    // Check-in event
    if (widget.attendanceRecord!.checkInTime != null) {
      events.add(TimelineEvent(
        time: widget.attendanceRecord!.checkInTime!,
        title: 'Check In',
        subtitle: widget.attendanceRecord!.storeName ?? 'Unknown Store',
        icon: Icons.login,
        color: Colors.green,
        isCompleted: true,
        isActive: false,
      ));
    }

    // Check-out event
    if (widget.attendanceRecord!.checkOutTime != null) {
      events.add(TimelineEvent(
        time: widget.attendanceRecord!.checkOutTime!,
        title: 'Check Out',
        subtitle: 'Work completed',
        icon: Icons.logout,
        color: Colors.red,
        isCompleted: true,
        isActive: false,
      ));
    } else if (widget.attendanceRecord!.isCheckedIn) {
      // Show expected check-out as pending
      events.add(TimelineEvent(
        time: DateTime.now(),
        title: 'Check Out',
        subtitle: 'Pending',
        icon: Icons.logout,
        color: Colors.grey,
        isCompleted: false,
        isActive: false,
      ));
    }

    // Sort events by time
    events.sort((a, b) => a.time.compareTo(b.time));
    
    setState(() {
      _events.addAll(events);
    });

    // Load more events if available
    if (widget.onLoadMore != null && widget.hasMore) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final newEvents = await widget.onLoadMore!();
      setState(() {
        _events.addAll(newEvents);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attendanceRecord == null) {
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
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
    if (widget.isLoading && _events.isEmpty) {
      return const ActivityLoadingSkeleton();
    }

    return Column(
      children: [
        // Existing events
        for (int i = 0; i < _events.length; i++)
          _buildTimelineItem(
            event: _events[i],
            isFirst: i == 0,
            isLast: i == _events.length - 1 && !_isLoadingMore && !widget.hasMore,
          ),
        
        // Loading more events
        if (_isLoadingMore) ...[
          const SizedBox(height: 16),
          _buildLoadingMoreIndicator(),
        ],
        
        // Load more button
        if (widget.hasMore && !_isLoadingMore && !_hasError) ...[
          const SizedBox(height: 16),
          _buildLoadMoreButton(),
        ],
        
        // Error state
        if (_hasError) ...[
          const SizedBox(height: 16),
          _buildErrorWidget(),
        ],
        
        // Loading message
        if (widget.loadingMessage != null && widget.isLoading) ...[
          const SizedBox(height: 16),
          _buildLoadingMessage(),
        ],
      ],
    );
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

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading more activities...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loadMoreEvents,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Load More Activities'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: BorderSide(color: Colors.blue[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load activities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadMoreEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.loadingMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

