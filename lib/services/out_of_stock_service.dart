import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/env.dart';
import 'auth_service.dart';
import '../models/out_of_stock_report.dart';
import 'report_completion_service.dart';

class OutOfStockService {
  static final ImagePicker _picker = ImagePicker();

  // Submit out of stock report
  static Future<OutOfStockReportResponse> submitOutOfStockReport({
    required int storeId,
    required String date,
    required bool isOutOfStock,
    required List<OutOfStockProduct> products,
    required List<XFile> images,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return OutOfStockReportResponse(
          success: false,
          message: 'No authentication token available',
        );
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/reports/out-of-stock'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['store_id'] = storeId.toString();
      request.fields['date'] = date;
      request.fields['is_out_of_stock'] = isOutOfStock ? '1' : '0';

      // Add products as individual array elements using indexed fields
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        
        request.fields['products[$i][product_id]'] = product.productId.toString();
        request.fields['products[$i][actual_qty]'] = product.actualQty.toString();
        request.fields['products[$i][estimated_po]'] = product.estimatedPo.toString();
        request.fields['products[$i][average_weekly_sale_out]'] = product.averageWeeklySaleOut.toString();
        request.fields['products[$i][average_weekly_sale_in]'] = product.averageWeeklySaleIn.toString();
        request.fields['products[$i][oos_distributor]'] = product.oosDistributor.toString();
      }

      // Add images as individual array elements using multipart files
      for (XFile image in images) {
        var imageField = await http.MultipartFile.fromPath(
          'images[]',
          image.path,
          filename: 'oos_report_${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg',
        );
        request.files.add(imageField);
      }

      print('Submitting out of stock report...');
      print('Store ID: $storeId');
      print('Date: $date');
      print('Is Out of Stock: $isOutOfStock');
      print('Products count: ${products.length}');
      print('Images count: ${images.length}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Out of stock report response: ${response.statusCode}');
      print('Out of stock report body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Save completion status to local storage
        final submissionTime = DateTime.now();
        await ReportCompletionService.markReportCompleted(
          storeId: storeId,
          reportType: 'out_of_stock',
          date: date,
          completedAt: submissionTime,
          reportData: {
            'isOutOfStock': isOutOfStock,
            'productsCount': products.length,
            'imagesCount': images.length,
            'submittedAt': submissionTime.toIso8601String(),
          },
        );
        
        return OutOfStockReportResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return OutOfStockReportResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to submit out of stock report',
          );
        } catch (e) {
          return OutOfStockReportResponse(
            success: false,
            message: 'Failed to submit out of stock report (HTTP ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      print('Error submitting out of stock report: $e');
      return OutOfStockReportResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get products with filters
  static Future<ProductResponse> getProducts({
    String? search,
    int? perPage,
    int? originId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ProductResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      // Build query parameters
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage.toString();
      }
      if (originId != null) {
        queryParams['conditions[origin_id]'] = originId.toString();
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/products').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Products API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ProductResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return ProductResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch products',
            data: [],
          );
        } catch (e) {
          return ProductResponse(
            success: false,
            message: 'Failed to fetch products (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
      return ProductResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Image picker methods
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
}
