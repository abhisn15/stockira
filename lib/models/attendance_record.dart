import 'package:flutter/material.dart';

class AttendanceDetail {
  final int id;
  final int attendanceId;
  final int storeId;
  final String storeName;
  final bool isOutItinerary;
  final bool isApproved;
  final String? noteIn;
  final String? noteOut;
  final TimeOfDay checkInTime;
  final TimeOfDay? checkOutTime;
  final String? imageUrlIn;
  final String? imageUrlOut;
  final String? imagePathIn;
  final String? imagePathOut;
  final double? distanceIn;
  final double? distanceOut;
  final double latitudeIn;
  final double longitudeIn;
  final double? latitudeOut;
  final double? longitudeOut;
  final bool? salesReportCompleted;
  final DateTime? salesReportCompletedAt;

  AttendanceDetail({
    required this.id,
    required this.attendanceId,
    required this.storeId,
    required this.storeName,
    required this.isOutItinerary,
    required this.isApproved,
    this.noteIn,
    this.noteOut,
    required this.checkInTime,
    this.checkOutTime,
    this.imageUrlIn,
    this.imageUrlOut,
    this.imagePathIn,
    this.imagePathOut,
    this.distanceIn,
    this.distanceOut,
    required this.latitudeIn,
    required this.longitudeIn,
    this.latitudeOut,
    this.longitudeOut,
    this.salesReportCompleted,
    this.salesReportCompletedAt,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      id: json['id'],
      attendanceId: json['attendance_id'],
      storeId: json['store_id'],
      storeName: json['store_name'],
      isOutItinerary: json['is_out_itinerary'] == 1,
      isApproved: json['is_approved'] == 1,
      noteIn: json['note_in'],
      noteOut: json['note_out'],
      checkInTime: _parseTimeOfDay(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null
          ? _parseTimeOfDay(json['check_out_time'])
          : null,
      imageUrlIn: json['image_url_in'],
      imageUrlOut: json['image_url_out'],
      imagePathIn: json['image_path_in'],
      imagePathOut: json['image_path_out'],
      distanceIn: json['distance_in'] != null ? double.tryParse(json['distance_in'].toString()) : null,
      distanceOut: json['distance_out'] != null ? double.tryParse(json['distance_out'].toString()) : null,
      latitudeIn: double.parse(json['latitude_in'].toString()),
      longitudeIn: double.parse(json['longitude_in'].toString()),
      latitudeOut: json['latitude_out'] != null
          ? double.parse(json['latitude_out'].toString())
          : null,
      longitudeOut: json['longitude_out'] != null
          ? double.parse(json['longitude_out'].toString())
          : null,
      salesReportCompleted: json['sales_report_completed'] == 1,
      salesReportCompletedAt: json['sales_report_completed_at'] != null
          ? DateTime.parse(json['sales_report_completed_at'])
          : null,
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  AttendanceDetail copyWith({
    int? id,
    int? attendanceId,
    int? storeId,
    String? storeName,
    bool? isOutItinerary,
    bool? isApproved,
    String? noteIn,
    String? noteOut,
    TimeOfDay? checkInTime,
    TimeOfDay? checkOutTime,
    String? imageUrlIn,
    String? imageUrlOut,
    String? imagePathIn,
    String? imagePathOut,
    double? distanceIn,
    double? distanceOut,
    double? latitudeIn,
    double? longitudeIn,
    double? latitudeOut,
    double? longitudeOut,
    bool? salesReportCompleted,
    DateTime? salesReportCompletedAt,
  }) {
    return AttendanceDetail(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      isOutItinerary: isOutItinerary ?? this.isOutItinerary,
      isApproved: isApproved ?? this.isApproved,
      noteIn: noteIn ?? this.noteIn,
      noteOut: noteOut ?? this.noteOut,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      imageUrlIn: imageUrlIn ?? this.imageUrlIn,
      imageUrlOut: imageUrlOut ?? this.imageUrlOut,
      imagePathIn: imagePathIn ?? this.imagePathIn,
      imagePathOut: imagePathOut ?? this.imagePathOut,
      distanceIn: distanceIn ?? this.distanceIn,
      distanceOut: distanceOut ?? this.distanceOut,
      latitudeIn: latitudeIn ?? this.latitudeIn,
      longitudeIn: longitudeIn ?? this.longitudeIn,
      latitudeOut: latitudeOut ?? this.latitudeOut,
      longitudeOut: longitudeOut ?? this.longitudeOut,
      salesReportCompleted: salesReportCompleted ?? this.salesReportCompleted,
      salesReportCompletedAt: salesReportCompletedAt ?? this.salesReportCompletedAt,
    );
  }
}

class AttendanceRecord {
  final dynamic id; // Can be String or int
  final int? employeeId;
  final String? employeeName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int? storeId;
  final String? storeName;
  final String? storeAddress;
  final double? latitude;
  final double? longitude;
  final double? distance; // in meters
  final int? duration; // in minutes
  final String
  status; // 'checked_in', 'checked_out', 'completed', 'permit', 'absent', 'no_activity'
  final String? note;
  final bool isApproved;
  final bool hasApprovedPermit;
  final List<AttendanceDetail> details;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    this.employeeId,
    this.employeeName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.storeId,
    this.storeName,
    this.storeAddress,
    this.latitude,
    this.longitude,
    this.distance,
    this.duration,
    this.status = 'pending',
    this.note,
    this.isApproved = false,
    this.hasApprovedPermit = false,
    this.details = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date': date.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'store_id': storeId,
      'store_name': storeName,
      'store_address': storeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'duration': duration,
      'status': status,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Parse details first to get the is_approved status
    final details = (json['details'] as List<dynamic>?)
        ?.map((detail) => AttendanceDetail.fromJson(detail))
        .toList() ?? [];
    
    // Always use data level is_approved (even if 0, still consider as approved)
    bool isApproved = true; // Default to approved for attendance records
    
    return AttendanceRecord(
      id: json['id'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      storeId: json['store_id'],
      storeName: json['store_name'],
      storeAddress: json['store_address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      status: json['status'] ?? 'pending',
      note: json['note'],
      isApproved: isApproved,
      hasApprovedPermit: json['has_approved_permit'] ?? false,
      details: details,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  AttendanceRecord copyWith({
    dynamic id,
    int? employeeId,
    String? employeeName,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? storeId,
    String? storeName,
    String? storeAddress,
    double? latitude,
    double? longitude,
    double? distance,
    int? duration,
    String? status,
    String? note,
    bool? isApproved,
    bool? hasApprovedPermit,
    List<AttendanceDetail>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearCheckOutTime =
        false, // ✅ Explicit parameter for clearing checkout time
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: clearCheckOutTime
          ? null
          : (checkOutTime ?? this.checkOutTime), // ✅ Explicit null handling
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      note: note ?? this.note,
      isApproved: isApproved ?? this.isApproved,
      hasApprovedPermit: hasApprovedPermit ?? this.hasApprovedPermit,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCheckedOut => checkInTime != null && checkOutTime != null;
  bool get isCompleted => status == 'completed';

  int get workingMinutes {
    if (checkInTime == null) return 0;

    final endTime = checkOutTime ?? DateTime.now();
    final totalMinutes = endTime.difference(checkInTime!).inMinutes;

    return totalMinutes;
  }


  String get workingHoursFormatted {
    final minutes = workingMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}
