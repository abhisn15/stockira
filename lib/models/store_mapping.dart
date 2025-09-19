// Store model for store mapping functionality
class Store {
  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? areaId;
  final String? areaName;
  final String? code;
  final String? category;
  final String? distribution;
  final String? ownerName;
  final String? ownerPhone;
  final String? remarks;
  final bool? isDistributor;
  final bool? isClose;
  final bool? isRequested;
  final String? alternateLatitude;
  final String? alternateLongitude;
  final Account? account;
  final List<Employee> employees;

  Store({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.areaId,
    this.areaName,
    this.code,
    this.category,
    this.distribution,
    this.ownerName,
    this.ownerPhone,
    this.remarks,
    this.isDistributor,
    this.isClose,
    this.isRequested,
    this.alternateLatitude,
    this.alternateLongitude,
    this.account,
    this.employees = const [],
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      areaId: json['areaId'] ?? json['area_id'], // Support both formats
      areaName: json['areaName'] ?? json['area_name'], // Support both formats
      code: json['code'],
      category: json['category'],
      distribution: json['distribution'],
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      remarks: json['remarks'],
      isDistributor: json['is_distributor'],
      isClose: json['is_close'],
      isRequested: json['is_requested'],
      alternateLatitude: json['alternate_latitude'],
      alternateLongitude: json['alternate_longitude'],
      account: json['account'] != null ? Account.fromJson(json['account']) : null,
      employees: json['employees'] != null 
          ? (json['employees'] as List).map((e) => Employee.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
      'areaId': areaId,
      'areaName': areaName,
      'code': code,
      'category': category,
      'distribution': distribution,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'remarks': remarks,
      'is_distributor': isDistributor,
      'is_close': isClose,
      'is_requested': isRequested,
      'alternate_latitude': alternateLatitude,
      'alternate_longitude': alternateLongitude,
      'account': account?.toJson(),
      'employees': employees.map((e) => e.toJson()).toList(),
    };
  }

  // Helper methods
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasAlternateLocation => alternateLatitude != null && alternateLongitude != null;
  
  String get displayAddress => address ?? 'No address available';
  String get displayDistribution => distribution ?? 'No distribution info';
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

class Employee {
  final int id;
  final String nik;
  final String name;
  final String nikKtp;
  final String code;
  final String phone;
  final String gender;
  final String joinAt;
  final String birthDate;
  final String? isLeader;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final String? ktpUrl;
  final String? ktpPath;
  final String? bankAccountUrl;
  final String? bankAccountPath;
  final String address;
  final String status;
  final String createdAt;
  final String updatedAt;

  Employee({
    required this.id,
    required this.nik,
    required this.name,
    required this.nikKtp,
    required this.code,
    required this.phone,
    required this.gender,
    required this.joinAt,
    required this.birthDate,
    this.isLeader,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.ktpUrl,
    this.ktpPath,
    this.bankAccountUrl,
    this.bankAccountPath,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      nik: json['nik'] ?? '',
      name: json['name'] ?? '',
      nikKtp: json['nik_ktp'] ?? '',
      code: json['code'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      joinAt: json['join_at'] ?? '',
      birthDate: json['birth_date'] ?? '',
      isLeader: json['is_leader'],
      bankName: json['bank_name'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      bankAccountName: json['bank_account_name'] ?? '',
      ktpUrl: json['ktp_url'],
      ktpPath: json['ktp_path'],
      bankAccountUrl: json['bank_account_url'],
      bankAccountPath: json['bank_account_path'],
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'nik_ktp': nikKtp,
      'code': code,
      'phone': phone,
      'gender': gender,
      'join_at': joinAt,
      'birth_date': birthDate,
      'is_leader': isLeader,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'ktp_url': ktpUrl,
      'ktp_path': ktpPath,
      'bank_account_url': bankAccountUrl,
      'bank_account_path': bankAccountPath,
      'address': address,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

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

class StoresResponse {
  final bool success;
  final String message;
  final List<Store> data;

  StoresResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory StoresResponse.fromJson(Map<String, dynamic> json) {
    return StoresResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? (json['data'] as List).map((e) => Store.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class AreasResponse {
  final bool success;
  final String message;
  final List<Area> data;

  AreasResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AreasResponse.fromJson(Map<String, dynamic> json) {
    return AreasResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? (json['data'] as List).map((e) => Area.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class SubAreasResponse {
  final bool success;
  final String message;
  final List<SubArea> data;

  SubAreasResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SubAreasResponse.fromJson(Map<String, dynamic> json) {
    return SubAreasResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? (json['data'] as List).map((e) => SubArea.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class AddStoresRequest {
  final List<int> storeIds;

  AddStoresRequest({
    required this.storeIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'store_ids': storeIds,
    };
  }
}

class AddStoresResponse {
  final bool success;
  final String message;
  final dynamic data;

  AddStoresResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddStoresResponse.fromJson(Map<String, dynamic> json) {
    return AddStoresResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class LocationUpdateRequest {
  final int storeId;
  final double latitudeOld;
  final double longitudeOld;
  final double latitudeNew;
  final double longitudeNew;
  final String reason;
  final String imagePath; // Path to image file

  LocationUpdateRequest({
    required this.storeId,
    required this.latitudeOld,
    required this.longitudeOld,
    required this.latitudeNew,
    required this.longitudeNew,
    required this.reason,
    required this.imagePath,
  });

  Map<String, dynamic> toFormData() {
    return {
      'store_id': storeId.toString(),
      'latitude_old': latitudeOld.toString(),
      'longitude_old': longitudeOld.toString(),
      'latitude_new': latitudeNew.toString(),
      'longitude_new': longitudeNew.toString(),
      'reason': reason,
    };
  }
}

class LocationUpdateResponse {
  final bool success;
  final String message;
  final dynamic data;

  LocationUpdateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LocationUpdateResponse.fromJson(Map<String, dynamic> json) {
    return LocationUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class AccountsResponse {
  final bool success;
  final String message;
  final List<Account> data;

  AccountsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AccountsResponse.fromJson(Map<String, dynamic> json) {
    return AccountsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Account.fromJson(item))
          .toList() ?? [],
    );
  }
}