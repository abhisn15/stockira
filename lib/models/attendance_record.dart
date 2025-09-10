class BreakSession {
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in minutes

  BreakSession({
    required this.startTime,
    this.endTime,
    this.duration,
  });

  bool get isActive => endTime == null;

  int get actualDuration => duration ?? (endTime?.difference(startTime).inMinutes ?? 0);

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': duration,
    };
  }

  factory BreakSession.fromJson(Map<String, dynamic> json) {
    return BreakSession(
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      duration: json['duration'],
    );
  }

  BreakSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
  }) {
    return BreakSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
    );
  }
}

class AttendanceRecord {
  final dynamic id; // Can be String or int
  final int? employeeId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int? storeId;
  final String? storeName;
  final String? storeAddress;
  final double? latitude;
  final double? longitude;
  final int? duration; // in minutes
  final String status; // 'checked_in', 'checked_out', 'completed', 'permit', 'absent', 'no_activity'
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Break/rest functionality
  final bool isOnBreak;
  final DateTime? breakStartTime;
  final int totalBreakMinutes; // total break time in minutes
  final List<BreakSession> breakSessions;

  AttendanceRecord({
    required this.id,
    this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.storeId,
    this.storeName,
    this.storeAddress,
    this.latitude,
    this.longitude,
    this.duration,
    this.status = 'pending',
    this.note,
    this.createdAt,
    this.updatedAt,
    this.isOnBreak = false,
    this.breakStartTime,
    this.totalBreakMinutes = 0,
    this.breakSessions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'store_id': storeId,
      'store_name': storeName,
      'store_address': storeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'duration': duration,
      'status': status,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_on_break': isOnBreak,
      'break_start_time': breakStartTime?.toIso8601String(),
      'total_break_minutes': totalBreakMinutes,
      'break_sessions': breakSessions.map((session) => session.toJson()).toList(),
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      employeeId: json['employee_id'],
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null ? DateTime.parse(json['check_in_time']) : null,
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      storeId: json['store_id'],
      storeName: json['store_name'],
      storeAddress: json['store_address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      duration: json['duration'],
      status: json['status'] ?? 'pending',
      note: json['note'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isOnBreak: json['is_on_break'] ?? false,
      breakStartTime: json['break_start_time'] != null ? DateTime.parse(json['break_start_time']) : null,
      totalBreakMinutes: json['total_break_minutes'] ?? 0,
      breakSessions: (json['break_sessions'] as List<dynamic>?)
          ?.map((session) => BreakSession.fromJson(session as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  AttendanceRecord copyWith({
    dynamic id,
    int? employeeId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? storeId,
    String? storeName,
    String? storeAddress,
    double? latitude,
    double? longitude,
    int? duration,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnBreak,
    DateTime? breakStartTime,
    int? totalBreakMinutes,
    List<BreakSession>? breakSessions,
    bool clearCheckOutTime = false, // ✅ Explicit parameter for clearing checkout time
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: clearCheckOutTime ? null : (checkOutTime ?? this.checkOutTime), // ✅ Explicit null handling
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      breakSessions: breakSessions ?? this.breakSessions,
    );
  }

  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCheckedOut => checkInTime != null && checkOutTime != null;
  bool get isCompleted => status == 'completed';

  int get workingMinutes {
    if (checkInTime == null) return 0;
    
    final endTime = checkOutTime ?? DateTime.now();
    final totalMinutes = endTime.difference(checkInTime!).inMinutes;
    
    // Subtract break time
    return totalMinutes - totalBreakMinutes;
  }

  int get totalMinutesIncludingBreak {
    if (checkInTime == null) return 0;
    
    final endTime = checkOutTime ?? DateTime.now();
    return endTime.difference(checkInTime!).inMinutes;
  }

  String get workingHoursFormatted {
    final minutes = workingMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

}
