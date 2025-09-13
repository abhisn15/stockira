class DisplayReportResponse {
  final bool success;
  final String message;
  final DisplayReportData? data;

  DisplayReportResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DisplayReportResponse.fromJson(Map<String, dynamic> json) {
    return DisplayReportResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? DisplayReportData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class DisplayReportData {
  final int id;

  DisplayReportData({
    required this.id,
  });

  factory DisplayReportData.fromJson(Map<String, dynamic> json) {
    return DisplayReportData(
      id: json['id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}

class TypeAdditional {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  TypeAdditional({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory TypeAdditional.fromJson(Map<String, dynamic> json) {
    return TypeAdditional(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class TypeAdditionalResponse {
  final bool success;
  final String message;
  final List<TypeAdditional> data;

  TypeAdditionalResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TypeAdditionalResponse.fromJson(Map<String, dynamic> json) {
    return TypeAdditionalResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => TypeAdditional.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class AttendanceDetail {
  final int id;
  final int attendanceId;
  final int storeId;
  final String storeName;
  final int isOutItinerary;
  final int? isApproved;
  final String distanceIn;
  final String? distanceOut;
  final String? noteIn;
  final String? noteOut;
  final String checkInTime;
  final String? checkOutTime;
  final String? imageUrlIn;
  final String? imageUrlOut;
  final String latitudeIn;
  final String longitudeIn;
  final String? imagePathIn;
  final String? imagePathOut;
  final String? latitudeOut;
  final String? longitudeOut;
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
    this.noteIn,
    this.noteOut,
    required this.checkInTime,
    this.checkOutTime,
    this.imageUrlIn,
    this.imageUrlOut,
    required this.latitudeIn,
    required this.longitudeIn,
    this.imagePathIn,
    this.imagePathOut,
    this.latitudeOut,
    this.longitudeOut,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      id: json['id'] as int? ?? 0,
      attendanceId: json['attendance_id'] as int? ?? 0,
      storeId: json['store_id'] as int? ?? 0,
      storeName: json['store_name'] as String? ?? '',
      isOutItinerary: json['is_out_itinerary'] as int? ?? 0,
      isApproved: json['is_approved'] as int?,
      distanceIn: json['distance_in'] as String? ?? '',
      distanceOut: json['distance_out'] as String?,
      noteIn: json['note_in'] as String?,
      noteOut: json['note_out'] as String?,
      checkInTime: json['check_in_time'] as String? ?? '',
      checkOutTime: json['check_out_time'] as String?,
      imageUrlIn: json['image_url_in'] as String?,
      imageUrlOut: json['image_url_out'] as String?,
      latitudeIn: json['latitude_in'] as String? ?? '',
      longitudeIn: json['longitude_in'] as String? ?? '',
      imagePathIn: json['image_path_in'] as String?,
      imagePathOut: json['image_path_out'] as String?,
      latitudeOut: json['latitude_out'] as String?,
      longitudeOut: json['longitude_out'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendance_id': attendanceId,
      'store_id': storeId,
      'store_name': storeName,
      'is_out_itinerary': isOutItinerary,
      'is_approved': isApproved,
      'distance_in': distanceIn,
      'distance_out': distanceOut,
      'note_in': noteIn,
      'note_out': noteOut,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'image_url_in': imageUrlIn,
      'image_url_out': imageUrlOut,
      'latitude_in': latitudeIn,
      'longitude_in': longitudeIn,
      'image_path_in': imagePathIn,
      'image_path_out': imagePathOut,
      'latitude_out': latitudeOut,
      'longitude_out': longitudeOut,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class AttendanceRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String date;
  final String? note;
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
      id: json['id'] as int? ?? 0,
      employeeId: json['employee_id'] as int? ?? 0,
      employeeName: json['employee_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      note: json['note'] as String?,
      isApproved: json['is_approved'] as int? ?? 0,
      details: (json['details'] as List<dynamic>?)
          ?.map((item) => AttendanceDetail.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date': date,
      'note': note,
      'is_approved': isApproved,
      'details': details.map((item) => item.toJson()).toList(),
    };
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
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
