class Store {
  final int id;
  final String name;
  final String code;
  final String? category;
  final String? distribution;
  final String? ownerName;
  final String? ownerPhone;
  final String? province;
  final String? city;
  final String? district;
  final String? village;
  final String? remarks;
  final bool isDistributor;
  final bool isClose;
  final bool isRequested;
  final String latitude;
  final String longitude;
  final String? alternateLatitude;
  final String? alternateLongitude;
  final String? address;
  final double distance;
  final StoreAccount account;
  final List<dynamic> employees;

  Store({
    required this.id,
    required this.name,
    required this.code,
    this.category,
    this.distribution,
    this.ownerName,
    this.ownerPhone,
    this.province,
    this.city,
    this.district,
    this.village,
    this.remarks,
    required this.isDistributor,
    required this.isClose,
    required this.isRequested,
    required this.latitude,
    required this.longitude,
    this.alternateLatitude,
    this.alternateLongitude,
    this.address,
    required this.distance,
    required this.account,
    required this.employees,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      category: json['category'],
      distribution: json['distribution'],
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      province: json['province'],
      city: json['city'],
      district: json['district'],
      village: json['village'],
      remarks: json['remarks'],
      isDistributor: json['is_distributor'] ?? false,
      isClose: json['is_close'] ?? false,
      isRequested: json['is_requested'] ?? false,
      latitude: json['latitude'] ?? '0',
      longitude: json['longitude'] ?? '0',
      alternateLatitude: json['alternate_latitude'],
      alternateLongitude: json['alternate_longitude'],
      address: json['address'],
      distance: (json['distance'] ?? 0).toDouble(),
      account: StoreAccount.fromJson(json['account'] ?? {}),
      employees: json['employees'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'distribution': distribution,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'province': province,
      'city': city,
      'district': district,
      'village': village,
      'remarks': remarks,
      'is_distributor': isDistributor,
      'is_close': isClose,
      'is_requested': isRequested,
      'latitude': latitude,
      'longitude': longitude,
      'alternate_latitude': alternateLatitude,
      'alternate_longitude': alternateLongitude,
      'address': address,
      'distance': distance,
      'account': account.toJson(),
      'employees': employees,
    };
  }

  double get latitudeDouble => double.tryParse(latitude) ?? 0.0;
  double get longitudeDouble => double.tryParse(longitude) ?? 0.0;
  
  String get displayAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    
    final parts = <String>[];
    if (village != null && village!.isNotEmpty) parts.add(village!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    
    return parts.isNotEmpty ? parts.join(', ') : 'Alamat tidak tersedia';
  }

  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  bool get isApproved => !isRequested;
  bool get isPending => isRequested;
}

class StoreAccount {
  final int id;
  final String name;

  StoreAccount({
    required this.id,
    required this.name,
  });

  factory StoreAccount.fromJson(Map<String, dynamic> json) {
    return StoreAccount(
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

class NearestStoresResponse {
  final bool success;
  final String message;
  final List<Store> data;

  NearestStoresResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory NearestStoresResponse.fromJson(Map<String, dynamic> json) {
    return NearestStoresResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Store.fromJson(item))
          .toList() ?? [],
    );
  }
}
