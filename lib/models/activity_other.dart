class ActivityOtherRequest {
  final String activityName;
  final List<String> approves;
  final String? documentationImageFirst;
  final String? documentationImageSecond;
  final String? documentationImageThird;

  ActivityOtherRequest({
    required this.activityName,
    required this.approves,
    this.documentationImageFirst,
    this.documentationImageSecond,
    this.documentationImageThird,
  });

  Map<String, dynamic> toJson() {
    return {
      'activity_name': activityName,
      'approves': approves,
      'documentation_image_first': documentationImageFirst,
      'documentation_image_second': documentationImageSecond,
      'documentation_image_third': documentationImageThird,
    };
  }
}

class ActivityOtherResponse {
  final bool success;
  final String message;
  final dynamic data;

  ActivityOtherResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ActivityOtherResponse.fromJson(Map<String, dynamic> json) {
    return ActivityOtherResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class AttendanceDetail {
  final int id;
  final int attendanceId;
  final int storeId;
  final String storeName;
  final int isOutItinerary;
  final dynamic isApproved;
  final String distanceIn;
  final dynamic distanceOut;
  final String noteIn;
  final dynamic noteOut;
  final String checkInTime;
  final dynamic checkOutTime;
  final String imageUrlIn;
  final dynamic imageUrlOut;
  final String latitudeIn;
  final dynamic longitudeIn;
  final String imagePathIn;
  final dynamic imagePathOut;
  final dynamic latitudeOut;
  final dynamic longitudeOut;
  final String createdAt;
  final String updatedAt;

  AttendanceDetail({
    required this.id,
    required this.attendanceId,
    required this.storeId,
    required this.storeName,
    required this.isOutItinerary,
    this.isApproved,
    required this.distanceIn,
    this.distanceOut,
    required this.noteIn,
    this.noteOut,
    required this.checkInTime,
    this.checkOutTime,
    required this.imageUrlIn,
    this.imageUrlOut,
    required this.latitudeIn,
    this.longitudeIn,
    required this.imagePathIn,
    this.imagePathOut,
    this.latitudeOut,
    this.longitudeOut,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      id: json['id'] ?? 0,
      attendanceId: json['attendance_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      storeName: json['store_name'] ?? '',
      isOutItinerary: json['is_out_itinerary'] ?? 0,
      isApproved: json['is_approved'],
      distanceIn: json['distance_in'] ?? '0',
      distanceOut: json['distance_out'],
      noteIn: json['note_in'] ?? '',
      noteOut: json['note_out'],
      checkInTime: json['check_in_time'] ?? '',
      checkOutTime: json['check_out_time'],
      imageUrlIn: json['image_url_in'] ?? '',
      imageUrlOut: json['image_url_out'],
      latitudeIn: json['latitude_in'] ?? '',
      longitudeIn: json['longitude_in'],
      imagePathIn: json['image_path_in'] ?? '',
      imagePathOut: json['image_path_out'],
      latitudeOut: json['latitude_out'],
      longitudeOut: json['longitude_out'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class AttendanceRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String date;
  final dynamic note;
  final int isApproved;
  final List<AttendanceDetail> details;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.note,
    required this.isApproved,
    required this.details,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '',
      date: json['date'] ?? '',
      note: json['note'],
      isApproved: json['is_approved'] ?? 0,
      details: (json['details'] as List<dynamic>?)
          ?.map((detail) => AttendanceDetail.fromJson(detail))
          .toList() ?? [],
    );
  }
}

class AttendanceResponse {
  final bool success;
  final String message;
  final List<AttendanceRecord> data;

  AttendanceResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((record) => AttendanceRecord.fromJson(record))
          .toList() ?? [],
    );
  }
}
