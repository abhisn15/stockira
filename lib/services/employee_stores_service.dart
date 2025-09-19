import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/store.dart';
import 'auth_service.dart';

class EmployeeStoresService {
  // Get stores for specific employee
  static Future<StoresResponse> getStoresForEmployee(int employeeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return StoresResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final url = '${Env.apiBaseUrl}/stores?conditions[employees.id]=$employeeId';
      print('🌐 [EmployeeStoresService] Calling API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🌐 [EmployeeStoresService] Response status: ${response.statusCode}');
      print('🌐 [EmployeeStoresService] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('🌐 [EmployeeStoresService] Parsed data: ${responseData}');
        return StoresResponse.fromJson(responseData);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return StoresResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch stores for employee',
          data: [],
        );
      }
    } catch (e) {
      print('Error fetching stores for employee: $e');
      return StoresResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get current user's employee ID from stored user data
  static Future<int?> getCurrentEmployeeId() async {
    try {
      final user = await AuthService.getUser();
      if (user?.employee != null) {
        print('🔍 [EmployeeStoresService] Found employee ID: ${user!.employee!.id}');
        return user.employee!.id;
      }
      
      // Fallback: try to decode from JWT token
      final token = await AuthService.getToken();
      if (token != null) {
        final employeeId = _decodeEmployeeIdFromToken(token);
        if (employeeId != null) {
          print('🔍 [EmployeeStoresService] Found employee ID from JWT: $employeeId');
          return employeeId;
        }
      }
      
      print('❌ [EmployeeStoresService] No employee data found in user or JWT');
      return null;
    } catch (e) {
      print('Error getting current employee ID: $e');
      return null;
    }
  }

  // Decode employee ID from JWT token
  static int? _decodeEmployeeIdFromToken(String token) {
    try {
      // JWT token has 3 parts separated by dots: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed for base64 decoding
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);
      
      // Look for employee_id in the payload
      if (payloadMap.containsKey('employee_id')) {
        return payloadMap['employee_id'] as int?;
      }
      
      // Alternative: look for employee.id
      if (payloadMap.containsKey('employee') && payloadMap['employee'] is Map) {
        final employee = payloadMap['employee'] as Map<String, dynamic>;
        if (employee.containsKey('id')) {
          return employee['id'] as int?;
        }
      }
      
      return null;
    } catch (e) {
      print('Error decoding JWT token: $e');
      return null;
    }
  }

  // Get stores for current user
  static Future<StoresResponse> getStoresForCurrentUser() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        return StoresResponse(
          success: false,
          message: 'Could not get current employee ID',
          data: [],
        );
      }

      return await getStoresForEmployee(employeeId);
    } catch (e) {
      print('Error getting stores for current user: $e');
      return StoresResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }
}

class StoresResponse {
  final bool success;
  final String message;
  final List<Store> data;

  StoresResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory StoresResponse.fromJson(Map<String, dynamic> json) {
    return StoresResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Store.fromJson(item))
          .toList() ?? [],
    );
  }
}
