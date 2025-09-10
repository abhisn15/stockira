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
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
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
    );
  }

  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCheckedOut => checkInTime != null && checkOutTime != null;
  bool get isCompleted => status == 'completed';

  int get workingMinutes {
    if (checkInTime == null || checkOutTime == null) return 0;
    
    return checkOutTime!.difference(checkInTime!).inMinutes;
  }

  String get workingHoursFormatted {
    final minutes = workingMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}
