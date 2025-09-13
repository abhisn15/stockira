class ItineraryResponse {
  final bool success;
  final String message;
  final List<Itinerary> data;

  ItineraryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    try {
      return ItineraryResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? 'Unknown error',
        data: (json['data'] as List<dynamic>?)
            ?.map((item) => Itinerary.fromJson(item as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      print('Error parsing ItineraryResponse from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class Itinerary {
  final int id;
  final String date;
  final List<Store> stores;
  final String createdAt;
  final String updatedAt;

  Itinerary({
    required this.id,
    required this.date,
    required this.stores,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    try {
      return Itinerary(
        id: json['id'] as int? ?? 0,
        date: json['date'] as String? ?? '',
        stores: (json['stores'] as List<dynamic>?)
            ?.map((item) => Store.fromJson(item as Map<String, dynamic>))
            .toList() ?? [],
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
    } catch (e) {
      print('Error parsing Itinerary from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'stores': stores.map((store) => store.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Store {
  final int id;
  final String name;
  final String code;
  final String? category;
  final String? distribution;
  final String? ownerName;
  final String? ownerPhone;
  final String? remarks;
  final bool isDistributor;
  final bool isClose;
  final bool isRequested;
  final String? latitude;
  final String? longitude;
  final String? alternateLatitude;
  final String? alternateLongitude;
  final String? address;

  Store({
    required this.id,
    required this.name,
    required this.code,
    this.category,
    this.distribution,
    this.ownerName,
    this.ownerPhone,
    this.remarks,
    required this.isDistributor,
    required this.isClose,
    required this.isRequested,
    this.latitude,
    this.longitude,
    this.alternateLatitude,
    this.alternateLongitude,
    this.address,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    try {
      return Store(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        category: json['category'] as String?,
        distribution: json['distribution'] as String?,
        ownerName: json['owner_name'] as String?,
        ownerPhone: json['owner_phone'] as String?,
        remarks: json['remarks'] as String?,
        isDistributor: json['is_distributor'] as bool? ?? false,
        isClose: json['is_close'] as bool? ?? false,
        isRequested: json['is_requested'] as bool? ?? false,
        latitude: json['latitude'] as String?,
        longitude: json['longitude'] as String?,
        alternateLatitude: json['alternate_latitude'] as String?,
        alternateLongitude: json['alternate_longitude'] as String?,
        address: json['address'] as String?,
      );
    } catch (e) {
      print('Error parsing Store from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
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
      'remarks': remarks,
      'is_distributor': isDistributor,
      'is_close': isClose,
      'is_requested': isRequested,
      'latitude': latitude,
      'longitude': longitude,
      'alternate_latitude': alternateLatitude,
      'alternate_longitude': alternateLongitude,
      'address': address,
    };
  }
}
