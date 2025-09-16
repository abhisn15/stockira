class AvailabilityResponse {
  final bool success;
  final String message;
  final List<AvailabilityData> data;

  AvailabilityResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return AvailabilityResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => AvailabilityData.fromJson(item))
              .toList()
          : [],
    );
  }
}

class AvailabilityData {
  final int id;
  final String date;
  final List<Store> stores;

  AvailabilityData({
    required this.id,
    required this.date,
    required this.stores,
  });

  factory AvailabilityData.fromJson(Map<String, dynamic> json) {
    return AvailabilityData(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      stores: json['stores'] != null
          ? (json['stores'] as List)
              .map((item) => Store.fromJson(item))
              .toList()
          : [],
    );
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
  final String latitude;
  final String longitude;
  final String? alternateLatitude;
  final String? alternateLongitude;
  final String address;

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
    required this.latitude,
    required this.longitude,
    this.alternateLatitude,
    this.alternateLongitude,
    required this.address,
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
      remarks: json['remarks'],
      isDistributor: json['is_distributor'] ?? false,
      isClose: json['is_close'] ?? false,
      isRequested: json['is_requested'] ?? false,
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      alternateLatitude: json['alternate_latitude'],
      alternateLongitude: json['alternate_longitude'],
      address: json['address'] ?? '',
    );
  }
}

class StoreProductsResponse {
  final bool success;
  final String message;
  final List<Product> data;

  StoreProductsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory StoreProductsResponse.fromJson(Map<String, dynamic> json) {
    return StoreProductsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => Product.fromJson(item))
              .toList()
          : [],
    );
  }
}

class Product {
  final int id;
  final String code;
  final String name;
  final String slug;
  final String? sapName;
  final String? sapCode;
  final String? variant;
  final String? classification;
  final String? package;
  final String? packageContent;
  final String? grammage;
  final int? originId;
  final String? imagePath;
  final String? imageUrl;
  final int isActive;
  final int isHidden;
  final Subcategory? subcategory;
  final Subbrand? subbrand;
  final LatestPrice? latestPrice;
  final List<Focus> focuses;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.slug,
    this.sapName,
    this.sapCode,
    this.variant,
    this.classification,
    this.package,
    this.packageContent,
    this.grammage,
    this.originId,
    this.imagePath,
    this.imageUrl,
    required this.isActive,
    required this.isHidden,
    this.subcategory,
    this.subbrand,
    this.latestPrice,
    required this.focuses,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      sapName: json['sap_name'],
      sapCode: json['sap_code'],
      variant: json['variant'],
      classification: json['classification'],
      package: json['package'],
      packageContent: json['package_content'],
      grammage: json['grammage'],
      originId: json['origin_id'],
      imagePath: json['image_path'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? 0,
      isHidden: json['is_hidden'] ?? 0,
      subcategory: json['subcategory'] != null
          ? Subcategory.fromJson(json['subcategory'])
          : null,
      subbrand: json['subbrand'] != null
          ? Subbrand.fromJson(json['subbrand'])
          : null,
      latestPrice: json['latest_price'] != null
          ? LatestPrice.fromJson(json['latest_price'])
          : null,
      focuses: json['focuses'] != null
          ? (json['focuses'] as List)
              .map((item) => Focus.fromJson(item))
              .toList()
          : [],
    );
  }
}

class Subcategory {
  final int id;
  final String name;
  final ProductCategory productCategory;

  Subcategory({
    required this.id,
    required this.name,
    required this.productCategory,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productCategory: ProductCategory.fromJson(json['product_category']),
    );
  }
}

class ProductCategory {
  final int id;
  final String name;

  ProductCategory({
    required this.id,
    required this.name,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Subbrand {
  final int id;
  final String name;
  final String sapName;
  final int isOriginal;
  final ProductBrand productBrand;

  Subbrand({
    required this.id,
    required this.name,
    required this.sapName,
    required this.isOriginal,
    required this.productBrand,
  });

  factory Subbrand.fromJson(Map<String, dynamic> json) {
    return Subbrand(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sapName: json['sap_name'] ?? '',
      isOriginal: json['is_original'] ?? 0,
      productBrand: ProductBrand.fromJson(json['product_brand']),
    );
  }
}

class ProductBrand {
  final int id;
  final String name;
  final String sapName;

  ProductBrand({
    required this.id,
    required this.name,
    required this.sapName,
  });

  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    return ProductBrand(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sapName: json['sap_name'] ?? '',
    );
  }
}

class LatestPrice {
  final int id;
  final int accountId;
  final int productId;
  final String price;
  final String? startDate;
  final int isActive;
  final String createdAt;
  final String updatedAt;

  LatestPrice({
    required this.id,
    required this.accountId,
    required this.productId,
    required this.price,
    this.startDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LatestPrice.fromJson(Map<String, dynamic> json) {
    return LatestPrice(
      id: json['id'] ?? 0,
      accountId: json['account_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      price: json['price'] ?? '0',
      startDate: json['start_date'],
      isActive: json['is_active'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Focus {
  final int id;
  final int productId;
  final String createdAt;
  final String updatedAt;
  final List<dynamic> stores;

  Focus({
    required this.id,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    required this.stores,
  });

  factory Focus.fromJson(Map<String, dynamic> json) {
    return Focus(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      stores: json['stores'] ?? [],
    );
  }
}
