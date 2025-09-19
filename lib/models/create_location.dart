class Area {
  final int id;
  final String name;
  final String? code;

  Area({
    required this.id,
    required this.name,
    this.code,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}

class SubArea {
  final int id;
  final String name;
  final String? code;
  final Area area;

  SubArea({
    required this.id,
    required this.name,
    this.code,
    required this.area,
  });

  factory SubArea.fromJson(Map<String, dynamic> json) {
    return SubArea(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      area: Area.fromJson(json['area'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'area': area.toJson(),
    };
  }
}

class Account {
  final int id;
  final String name;

  Account({
    required this.id,
    required this.name,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class CreateLocationRequest {
  final String name;
  final int subAreaId;
  final int accountId;
  final double latitude;
  final double longitude;
  final String address;

  CreateLocationRequest({
    required this.name,
    required this.subAreaId,
    required this.accountId,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sub_area_id': subAreaId,
      'account_id': accountId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

class CreateLocationResponse {
  final bool success;
  final String message;
  final dynamic data;

  CreateLocationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CreateLocationResponse.fromJson(Map<String, dynamic> json) {
    return CreateLocationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
