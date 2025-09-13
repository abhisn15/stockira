class CompetitorActivityRequest {
  final int principalId;
  final int storeId;
  final int typePromotionId;
  final String promoMechanism;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAdditionalDisplay;
  final bool isPosm;
  final String? image;
  final List<String> products;
  final int? typeAdditionalId;
  final int? typePosmId;

  CompetitorActivityRequest({
    required this.principalId,
    required this.storeId,
    required this.typePromotionId,
    required this.promoMechanism,
    required this.startDate,
    required this.endDate,
    required this.isAdditionalDisplay,
    required this.isPosm,
    this.image,
    required this.products,
    this.typeAdditionalId,
    this.typePosmId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'principal_id': principalId,
      'store_id': storeId,
      'type_promotion_id': typePromotionId,
      'promo_mechanism': promoMechanism,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_additional_display': isAdditionalDisplay ? 1 : 0,
      'is_posm': isPosm ? 1 : 0,
      'products': products,
    };

    if (image != null) data['image'] = image;
    if (typeAdditionalId != null) data['type_additional_id'] = typeAdditionalId;
    if (typePosmId != null) data['type_posm_id'] = typePosmId;

    return data;
  }
}

class TypePromotion {
  final int id;
  final String name;
  final int isPromoPrice;
  final String createdAt;
  final String updatedAt;

  TypePromotion({
    required this.id,
    required this.name,
    required this.isPromoPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TypePromotion.fromJson(Map<String, dynamic> json) {
    return TypePromotion(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isPromoPrice: json['is_promo_price'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_promo_price': isPromoPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class TypeAdditional {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  TypeAdditional({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TypeAdditional.fromJson(Map<String, dynamic> json) {
    return TypeAdditional(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
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

class TypePosm {
  final int id;
  final String name;

  TypePosm({
    required this.id,
    required this.name,
  });

  factory TypePosm.fromJson(Map<String, dynamic> json) {
    return TypePosm(
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

class ProductPrincipal {
  final int id;
  final String name;
  final int originId;

  ProductPrincipal({
    required this.id,
    required this.name,
    required this.originId,
  });

  factory ProductPrincipal.fromJson(Map<String, dynamic> json) {
    return ProductPrincipal(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      originId: json['origin_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'origin_id': originId,
    };
  }
}

class CompetitorActivityResponse {
  final bool success;
  final String message;
  final dynamic data;

  CompetitorActivityResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CompetitorActivityResponse.fromJson(Map<String, dynamic> json) {
    return CompetitorActivityResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }
}

class TypePromotionResponse {
  final bool success;
  final String message;
  final List<TypePromotion> data;

  TypePromotionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TypePromotionResponse.fromJson(Map<String, dynamic> json) {
    return TypePromotionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => TypePromotion.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
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
}

class TypePosmResponse {
  final bool success;
  final String message;
  final List<TypePosm> data;

  TypePosmResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TypePosmResponse.fromJson(Map<String, dynamic> json) {
    return TypePosmResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => TypePosm.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ProductPrincipalResponse {
  final bool success;
  final String message;
  final List<ProductPrincipal> data;

  ProductPrincipalResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ProductPrincipalResponse.fromJson(Map<String, dynamic> json) {
    return ProductPrincipalResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ProductPrincipal.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
