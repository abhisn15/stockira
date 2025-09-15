import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import 'auth_service.dart';
import '../models/expired_date_report.dart';
import 'report_completion_service.dart';

class ExpiredDateService {
  // Submit expired date report
  static Future<ExpiredDateReportResponse> submitExpiredDateReport({
    required int storeId,
    required String date,
    required List<ExpiredDateItem> items,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ExpiredDateReportResponse(
          success: false,
          message: 'No authentication token available',
        );
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/expired-dates'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['store_id'] = storeId.toString();
      request.fields['date'] = date;

      // Add items as individual array elements using multipart files
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        
        // Add product_id
        request.fields['items[$i][product_id]'] = item.productId.toString();
        
        // Add qty
        request.fields['items[$i][qty]'] = item.qty.toString();
        
        // Add expired_date
        request.fields['items[$i][expired_date]'] = item.expiredDate;
      }

      print('Submitting expired date report...');
      print('Store ID: $storeId');
      print('Date: $date');
      print('Items count: ${items.length}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Expired date report response: ${response.statusCode}');
      print('Expired date report body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Save completion status to local storage
        final submissionTime = DateTime.now();
        await ReportCompletionService.markReportCompleted(
          storeId: storeId,
          reportType: 'expired_date',
          date: date,
          completedAt: submissionTime,
          reportData: {
            'itemsCount': items.length,
            'submittedAt': submissionTime.toIso8601String(),
          },
        );
        
        return ExpiredDateReportResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return ExpiredDateReportResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to submit expired date report',
          );
        } catch (e) {
          return ExpiredDateReportResponse(
            success: false,
            message: 'Failed to submit expired date report (HTTP ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      print('Error submitting expired date report: $e');
      return ExpiredDateReportResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get products
  static Future<ProductResponse> getProducts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ProductResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/products?conditions[origin_id]=1'),
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
}
