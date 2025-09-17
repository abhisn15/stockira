class ReportType {
  final String key;
  final String name;
  final String description;

  ReportType({
    required this.key,
    required this.name,
    required this.description,
  });

  factory ReportType.fromJson(Map<String, dynamic> json) {
    return ReportType(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class ReportTypesResponse {
  final bool success;
  final String message;
  final List<ReportType> data;

  ReportTypesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReportTypesResponse.fromJson(Map<String, dynamic> json) {
    return ReportTypesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ReportType.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ReportData {
  final int id;
  final String? date;
  final int? employeeId;
  final int? storeId;
  final String? createdAt;
  final String? updatedAt;

  ReportData({
    required this.id,
    this.date,
    this.employeeId,
    this.storeId,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json['id'] ?? 0,
      date: json['date'],
      employeeId: json['employee_id'],
      storeId: json['store_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ReportDataResponse {
  final bool success;
  final String message;
  final ReportDataWrapper data;

  ReportDataResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReportDataResponse.fromJson(Map<String, dynamic> json) {
    return ReportDataResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ReportDataWrapper.fromJson(json['data'] ?? {}),
    );
  }
}

class ReportDataWrapper {
  final List<ReportData> data;
  final Pagination pagination;

  ReportDataWrapper({
    required this.data,
    required this.pagination,
  });

  factory ReportDataWrapper.fromJson(Map<String, dynamic> json) {
    return ReportDataWrapper(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ReportData.fromJson(item))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      from: json['from'],
      to: json['to'],
    );
  }
}

class ReportSummary {
  final String date;
  final int employeeId;
  final Map<String, int> reports;
  final int totalReports;

  ReportSummary({
    required this.date,
    required this.employeeId,
    required this.reports,
    required this.totalReports,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      date: json['date'] ?? '',
      employeeId: json['employee_id'] ?? 0,
      reports: Map<String, int>.from(json['reports'] ?? {}),
      totalReports: json['total_reports'] ?? 0,
    );
  }
}

class ReportSummaryResponse {
  final bool success;
  final String message;
  final ReportSummary data;

  ReportSummaryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReportSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ReportSummaryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ReportSummary.fromJson(json['data'] ?? {}),
    );
  }
}
