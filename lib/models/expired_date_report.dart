class ExpiredDateReportResponse {
  final bool success;
  final String message;
  final ExpiredDateReportData? data;

  ExpiredDateReportResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ExpiredDateReportResponse.fromJson(Map<String, dynamic> json) {
    return ExpiredDateReportResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? ExpiredDateReportData.fromJson(json['data'] as Map<String, dynamic>) : null,
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

class ExpiredDateReportData {
  final int id;

  ExpiredDateReportData({
    required this.id,
  });

  factory ExpiredDateReportData.fromJson(Map<String, dynamic> json) {
    return ExpiredDateReportData(
      id: json['id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
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
  final int originId;
  final String? imagePath;
  final String? imageUrl;
  final int isActive;
  final int isHidden;
  final ProductSubcategory? subcategory;
  final ProductSubbrand subbrand;
  final ProductLatestPrice latestPrice;
  final List<ProductFocus> focuses;

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
    required this.originId,
    this.imagePath,
    this.imageUrl,
    required this.isActive,
    required this.isHidden,
    this.subcategory,
    required this.subbrand,
    required this.latestPrice,
    required this.focuses,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      sapName: json['sap_name'] as String?,
      sapCode: json['sap_code'] as String?,
      variant: json['variant'] as String?,
      classification: json['classification'] as String?,
      package: json['package'] as String?,
      packageContent: json['package_content'] as String?,
      grammage: json['grammage'] as String?,
      originId: json['origin_id'] as int? ?? 0,
      imagePath: json['image_path'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as int? ?? 0,
      isHidden: json['is_hidden'] as int? ?? 0,
      subcategory: json['subcategory'] != null ? ProductSubcategory.fromJson(json['subcategory'] as Map<String, dynamic>) : null,
      subbrand: ProductSubbrand.fromJson(json['subbrand'] as Map<String, dynamic>),
      latestPrice: ProductLatestPrice.fromJson(json['latest_price'] as Map<String, dynamic>),
      focuses: (json['focuses'] as List<dynamic>?)
          ?.map((item) => ProductFocus.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'slug': slug,
      'sap_name': sapName,
      'sap_code': sapCode,
      'variant': variant,
      'classification': classification,
      'package': package,
      'package_content': packageContent,
      'grammage': grammage,
      'origin_id': originId,
      'image_path': imagePath,
      'image_url': imageUrl,
      'is_active': isActive,
      'is_hidden': isHidden,
      'subcategory': subcategory?.toJson(),
      'subbrand': subbrand.toJson(),
      'latest_price': latestPrice.toJson(),
      'focuses': focuses.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductSubcategory {
  final int id;
  final String name;
  final ProductCategory productCategory;

  ProductSubcategory({
    required this.id,
    required this.name,
    required this.productCategory,
  });

  factory ProductSubcategory.fromJson(Map<String, dynamic> json) {
    return ProductSubcategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      productCategory: ProductCategory.fromJson(json['product_category'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_category': productCategory.toJson(),
    };
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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ProductSubbrand {
  final int id;
  final String name;
  final String sapName;
  final int isOriginal;
  final ProductBrand productBrand;

  ProductSubbrand({
    required this.id,
    required this.name,
    required this.sapName,
    required this.isOriginal,
    required this.productBrand,
  });

  factory ProductSubbrand.fromJson(Map<String, dynamic> json) {
    return ProductSubbrand(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sapName: json['sap_name'] as String? ?? '',
      isOriginal: json['is_original'] as int? ?? 0,
      productBrand: ProductBrand.fromJson(json['product_brand'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sap_name': sapName,
      'is_original': isOriginal,
      'product_brand': productBrand.toJson(),
    };
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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sapName: json['sap_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sap_name': sapName,
    };
  }
}

class ProductLatestPrice {
  final int id;
  final int accountId;
  final int productId;
  final String price;
  final String? startDate;
  final int isActive;
  final String createdAt;
  final String updatedAt;

  ProductLatestPrice({
    required this.id,
    required this.accountId,
    required this.productId,
    required this.price,
    this.startDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductLatestPrice.fromJson(Map<String, dynamic> json) {
    return ProductLatestPrice(
      id: json['id'] as int? ?? 0,
      accountId: json['account_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      price: json['price'] as String? ?? '',
      startDate: json['start_date'] as String?,
      isActive: json['is_active'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'product_id': productId,
      'price': price,
      'start_date': startDate,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ProductFocus {
  final int id;
  final int productId;
  final String createdAt;
  final String updatedAt;
  final List<dynamic> stores;

  ProductFocus({
    required this.id,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    required this.stores,
  });

  factory ProductFocus.fromJson(Map<String, dynamic> json) {
    return ProductFocus(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      stores: json['stores'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'stores': stores,
    };
  }
}

class ProductResponse {
  final bool success;
  final String message;
  final List<Product> data;

  ProductResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
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

class ExpiredDateItem {
  final int productId;
  final int qty;
  final String expiredDate;

  ExpiredDateItem({
    required this.productId,
    required this.qty,
    required this.expiredDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'qty': qty,
      'expired_date': expiredDate,
    };
  }
}
