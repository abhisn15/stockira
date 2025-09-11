import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_record.dart';

class RealtimeTimerWidget extends StatefulWidget {
  final AttendanceRecord? attendanceRecord;
  final TextStyle? textStyle;

  const RealtimeTimerWidget({
    super.key,
    this.attendanceRecord,
    this.textStyle,
  });

  @override
  State<RealtimeTimerWidget> createState() => _RealtimeTimerWidgetState();
}

class _RealtimeTimerWidgetState extends State<RealtimeTimerWidget> {
  Timer? _timer;
  String _currentTime = '0h 0m 0s';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(RealtimeTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceRecord != widget.attendanceRecord) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTime();
    
    if (widget.attendanceRecord?.isCheckedIn == true) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          _updateTime();
        }
      });
    }
  }

  void _updateTime() {
    if (widget.attendanceRecord?.checkInTime == null) {
      setState(() {
        _currentTime = '0h 0m 0s';
      });
      return;
    }

    final record = widget.attendanceRecord!;
    final checkInTime = record.checkInTime!;
    final now = DateTime.now();
    
    // Simple working time calculation (total time since check-in)
    final totalTimeSeconds = now.difference(checkInTime).inSeconds;
    
    setState(() {
      _currentTime = _formatDuration(totalTimeSeconds);
    });
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentTime,
      style: widget.textStyle ?? const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

