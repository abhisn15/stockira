class AttendanceRecord {
  final String id;
  final DateTime date;
  final String? checkInTime;
  final String? checkOutTime;
  final String? store;
  final int? duration; // in minutes
  final String status; // 'checked_in', 'checked_out', 'completed'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.store,
    this.duration,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'store': store,
      'duration': duration,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      store: json['store'],
      duration: json['duration'],
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    String? checkInTime,
    String? checkOutTime,
    String? store,
    int? duration,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      store: store ?? this.store,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCheckedOut => checkInTime != null && checkOutTime != null;
  bool get isCompleted => status == 'completed';

  int get workingMinutes {
    if (checkInTime == null || checkOutTime == null) return 0;
    
    // Parse time strings (assuming format like "14:30")
    final checkInParts = checkInTime!.split(':');
    final checkOutParts = checkOutTime!.split(':');
    
    final checkInMinutes = int.parse(checkInParts[0]) * 60 + int.parse(checkInParts[1]);
    final checkOutMinutes = int.parse(checkOutParts[0]) * 60 + int.parse(checkOutParts[1]);
    
    return checkOutMinutes - checkInMinutes;
  }

  String get workingHoursFormatted {
    final minutes = workingMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}
