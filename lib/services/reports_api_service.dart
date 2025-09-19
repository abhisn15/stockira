import 'dart:convert';
import '../config/env.dart';
import '../services/auth_service.dart';
import '../models/reports_api.dart';
import 'http_client_service.dart';

class ReportsApiService {
  // Get all report types
  static Future<ReportTypesResponse> getReportTypes() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await HttpClientService.get(
        Uri.parse('${Env.apiBaseUrl}/reports/types'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = ReportTypesResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        return data;
      } else {
        throw Exception('Failed to load report types: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading report types: $e');
      rethrow;
    }
  }

  // Get report data by type and date
  static Future<ReportDataResponse> getReportData({
    required String reportType,
    required String date,
    int? storeId,
    int perPage = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'report_type': reportType,
        'date': date,
        'per_page': perPage.toString(),
      };

      if (storeId != null) {
        queryParams['store_id'] = storeId.toString();
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/reports/data').replace(
        queryParameters: queryParams,
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = ReportDataResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        return data;
      } else {
        throw Exception('Failed to load report data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading report data: $e');
      rethrow;
    }
  }

  // Get report summary for a specific date
  static Future<ReportSummaryResponse> getReportSummary({
    String? date,
    int? storeId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (date != null) {
        queryParams['date'] = date;
      }
      if (storeId != null) {
        queryParams['store_id'] = storeId.toString();
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/reports/summary').replace(
        queryParameters: queryParams,
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = ReportSummaryResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        return data;
      } else {
        throw Exception('Failed to load report summary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading report summary: $e');
      rethrow;
    }
  }

  // Check if a specific report type is completed for a store on a specific date
  static Future<bool> isReportCompleted({
    required String reportType,
    required String date,
    required int storeId,
  }) async {
    try {
      final response = await getReportData(
        reportType: reportType,
        date: date,
        storeId: storeId,
        perPage: 1, // We only need to check if there's at least 1 record
      );

      // If there's data and pagination.total > 0, the report is completed
      return response.success && response.data.pagination.total > 0;
    } catch (e) {
      print('Error checking report completion for $reportType: $e');
      return false;
    }
  }

  // Get completion time for a specific report type
  static Future<String?> getReportCompletionTime({
    required String reportType,
    required String date,
    required int storeId,
  }) async {
    try {
      final response = await getReportData(
        reportType: reportType,
        date: date,
        storeId: storeId,
        perPage: 1,
      );

      if (response.success && response.data.data.isNotEmpty) {
        // Return the created_at time of the first (most recent) report
        return response.data.data.first.createdAt;
      }
      return null;
    } catch (e) {
      print('Error getting report completion time for $reportType: $e');
      return null;
    }
  }

  // Get all report completions for a store on a specific date
  static Future<Map<String, Map<String, dynamic>>> getAllReportCompletions({
    required String date,
    required int storeId,
  }) async {
    final reportTypes = [
      'price',
      'price_competitor', 
      'promo_tracking',
      'competitor_activity',
      'activity_other',
      'reguler_display',
      'display',
      'survey',
      'out_of_stock',
      'expired_date',
      'product_belgian_berry',
      'product_focus',
      'sales', // Note: sales might need different handling
    ];

    final Map<String, Map<String, dynamic>> completions = {};

    for (final reportType in reportTypes) {
      try {
        final isCompleted = await isReportCompleted(
          reportType: reportType,
          date: date,
          storeId: storeId,
        );

        String? completionTime;
        if (isCompleted) {
          completionTime = await getReportCompletionTime(
            reportType: reportType,
            date: date,
            storeId: storeId,
          );
        }

        completions[reportType] = {
          'isCompleted': isCompleted,
          'completionTime': completionTime,
          'storeId': storeId,
          'date': date,
        };

        print('📊 Report $reportType for store $storeId on $date: ${isCompleted ? "COMPLETED" : "NOT COMPLETED"}');
        if (isCompleted && completionTime != null) {
          print('📊 Completion time: $completionTime');
        }
      } catch (e) {
        print('❌ Error checking $reportType: $e');
        completions[reportType] = {
          'isCompleted': false,
          'completionTime': null,
          'storeId': storeId,
          'date': date,
        };
      }
    }

    return completions;
  }

  // Optimized method to get all report completions for a store using batch approach
  static Future<Map<String, Map<String, dynamic>>> getAllReportCompletionsOptimized({
    required String date,
    required int storeId,
  }) async {
    print('🚀 Getting all report completions for store $storeId on $date');
    
    final Map<String, Map<String, dynamic>> completions = {};
    
    // Get all report types first
    try {
      final reportTypesResponse = await getReportTypes();
      final reportTypes = reportTypesResponse.data.map((type) => type.key).toList();
      
      print('📋 Available report types: $reportTypes');
      
      // Check each report type for completion
      for (final reportType in reportTypes) {
        try {
          print('🔍 Checking report type: $reportType');
          
          final isCompleted = await isReportCompleted(
            reportType: reportType,
            date: date,
            storeId: storeId,
          );

          String? completionTime;
          if (isCompleted) {
            completionTime = await getReportCompletionTime(
              reportType: reportType,
              date: date,
              storeId: storeId,
            );
          }

          completions[reportType] = {
            'isCompleted': isCompleted,
            'completionTime': completionTime,
            'storeId': storeId,
            'date': date,
          };

          print('📊 Report $reportType for store $storeId on $date: ${isCompleted ? "✅ COMPLETED" : "❌ NOT COMPLETED"}');
          if (isCompleted && completionTime != null) {
            print('📊 Completion time: $completionTime');
          }
        } catch (e) {
          print('❌ Error checking $reportType: $e');
          completions[reportType] = {
            'isCompleted': false,
            'completionTime': null,
            'storeId': storeId,
            'date': date,
            'error': e.toString(),
          };
        }
      }
    } catch (e) {
      print('❌ Error getting report types: $e');
    }

    print('🎯 Final completions summary:');
    completions.forEach((type, data) {
      print('  - $type: ${data['isCompleted'] ? "✅" : "❌"}');
    });

    return completions;
  }
}
