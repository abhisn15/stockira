class Store {
  final int id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int? areaId;
  final int? subAreaId;
  final String? areaName;
  final String? subAreaName;
  final List<Employee>? employees;

  Store({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.areaId,
    this.subAreaId,
    this.areaName,
    this.subAreaName,
    this.employees,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      areaId: json['area_id'],
      subAreaId: json['sub_area_id'],
      areaName: json['area_name'],
      subAreaName: json['sub_area_name'],
      employees: json['employees'] != null
          ? (json['employees'] as List)
              .map((e) => Employee.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'area_id': areaId,
      'sub_area_id': subAreaId,
      'area_name': areaName,
      'sub_area_name': subAreaName,
      'employees': employees?.map((e) => e.toJson()).toList(),
    };
  }
}

class Employee {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? position;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.position,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
    };
  }
}

class Area {
  final int id;
  final String name;
  final String? description;

  Area({
    required this.id,
    required this.name,
    this.description,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class SubArea {
  final int id;
  final String name;
  final int areaId;
  final String? description;

  SubArea({
    required this.id,
    required this.name,
    required this.areaId,
    this.description,
  });

  factory SubArea.fromJson(Map<String, dynamic> json) {
    return SubArea(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      areaId: json['area_id'] ?? 0,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area_id': areaId,
      'description': description,
    };
  }
}

class StoreLocationUpdate {
  final int storeId;
  final double latitude;
  final double longitude;
  final String? notes;

  StoreLocationUpdate({
    required this.storeId,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    };
  }
}
