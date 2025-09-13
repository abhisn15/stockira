import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/env.dart';
import '../models/competitor_activity.dart';
import 'auth_service.dart';

class CompetitorActivityService {
  static final ImagePicker _picker = ImagePicker();

  // Submit competitor activity
  static Future<CompetitorActivityResponse> submitCompetitorActivity({
    required int principalId,
    required int storeId,
    required int typePromotionId,
    required String promoMechanism,
    required DateTime startDate,
    required DateTime endDate,
    required bool isAdditionalDisplay,
    required bool isPosm,
    XFile? image,
    required List<int> products,
    int? typeAdditionalId,
    int? typePosmId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return CompetitorActivityResponse(
          success: false,
          message: 'No authentication token available',
        );
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/reports/competitor-activity'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['principal_id'] = principalId.toString();
      request.fields['store_id'] = storeId.toString();
      request.fields['type_promotion_id'] = typePromotionId.toString();
      request.fields['promo_mechanism'] = promoMechanism;
      request.fields['start_date'] = startDate.toIso8601String().split('T')[0];
      request.fields['end_date'] = endDate.toIso8601String().split('T')[0];
      request.fields['is_additional_display'] = isAdditionalDisplay ? '1' : '0';
      request.fields['is_posm'] = isPosm ? '1' : '0';

      // Add products as individual array elements using multipart files
      for (int productId in products) {
        var productField = http.MultipartFile.fromString(
          'products[]',
          productId.toString(),
        );
        request.files.add(productField);
      }

      if (typeAdditionalId != null) {
        request.fields['type_additional_id'] = typeAdditionalId.toString();
      }
      if (typePosmId != null) {
        request.fields['type_posm_id'] = typePosmId.toString();
      }

      // Add image if provided
      if (image != null) {
        var file = await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: 'competitor_activity_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(file);
      }

      print('Submitting competitor activity...');
      print('Store ID: $storeId');
      print('Principal ID: $principalId');
      print('Type Promotion ID: $typePromotionId');
      print('Products: $products');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Response: $response');

      print('Competitor activity response: ${response.statusCode}');
      print('Competitor activity body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return CompetitorActivityResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return CompetitorActivityResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to submit competitor activity',
          );
        } catch (e) {
          return CompetitorActivityResponse(
            success: false,
            message: 'Failed to submit competitor activity (HTTP ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      print('Error submitting competitor activity: $e');
      return CompetitorActivityResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get type promotions
  static Future<TypePromotionResponse> getTypePromotions() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return TypePromotionResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/type/promotion'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Type promotions API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TypePromotionResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return TypePromotionResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch type promotions',
            data: [],
          );
        } catch (e) {
          return TypePromotionResponse(
            success: false,
            message: 'Failed to fetch type promotions (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching type promotions: $e');
      return TypePromotionResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get type additionals
  static Future<TypeAdditionalResponse> getTypeAdditionals() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return TypeAdditionalResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/type/additional'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Type additionals API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TypeAdditionalResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return TypeAdditionalResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch type additionals',
            data: [],
          );
        } catch (e) {
          return TypeAdditionalResponse(
            success: false,
            message: 'Failed to fetch type additionals (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching type additionals: $e');
      return TypeAdditionalResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get type POSMs
  static Future<TypePosmResponse> getTypePosms() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return TypePosmResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/type/posm'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Type POSMs API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TypePosmResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return TypePosmResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch type POSMs',
            data: [],
          );
        } catch (e) {
          return TypePosmResponse(
            success: false,
            message: 'Failed to fetch type POSMs (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching type POSMs: $e');
      return TypePosmResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get product principals
  static Future<ProductPrincipalResponse> getProductPrincipals({int? originId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ProductPrincipalResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      String url = '${Env.apiBaseUrl}/products/principals';
      if (originId != null) {
        url += '?conditions[origin_id]=$originId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Product principals API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ProductPrincipalResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return ProductPrincipalResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch product principals',
            data: [],
          );
        } catch (e) {
          return ProductPrincipalResponse(
            success: false,
            message: 'Failed to fetch product principals (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching product principals: $e');
      return ProductPrincipalResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }
}
