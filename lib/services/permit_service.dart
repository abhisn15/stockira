import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import 'http_client_service.dart';

class PermitService {
  static String get _apiBaseUrl => Env.apiBaseUrl;

  // Get authorization token
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Submit permit request
  static Future<Map<String, dynamic>> submitPermit({
    required int permitTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    required File imageFile,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$_apiBaseUrl/permits');
      
      // Prepare form fields
      final fields = {
        'permit_type_id': permitTypeId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      };
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      
      // Prepare files
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageFile.path.split('/').last,
      );
      
      // Send multipart request
      final response = await HttpClientService.multipartRequest(
        'POST',
        url,
        headers: headers,
        fields: fields,
        files: [multipartFile],
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Permit submitted successfully',
          'data': responseData['data'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to submit permit',
          'error': errorData,
        };
      }
    } catch (e) {
      print('❌ Error submitting permit: $e');
      return {
        'success': false,
        'message': 'Error submitting permit: $e',
      };
    }
  }

  // Get permits list (with authentication)
  static Future<Map<String, dynamic>> getPermits({
    required String emailOrUsername,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$_apiBaseUrl/permits');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      print('📥 Get permits response: ${response.statusCode}');
      print('📥 Get permits body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] ?? [];
        print('📥 API Response - Success: ${responseData['success']}');
        print('📥 API Response - Message: ${responseData['message']}');
        print('📥 API Response - Data count: ${data.length}');
        if (data.isNotEmpty) {
          print('📥 First permit: ${data[0]}');
        }
        return {
          'success': true,
          'data': data,
          'message': responseData['message'] ?? 'Permits retrieved successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ API Error - Status: ${response.statusCode}');
        print('❌ API Error - Body: ${response.body}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get permits',
          'error': errorData,
        };
      }
    } catch (e) {
      print('❌ Error getting permits: $e');
      return {
        'success': false,
        'message': 'Error getting permits: $e',
      };
    }
  }

  // Get permit types (if needed)
  static Future<Map<String, dynamic>> getPermitTypes() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$_apiBaseUrl/permits');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      print('📥 Get permit types response: ${response.statusCode}');
      print('📥 Get permit types body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? [],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get permit types',
        };
      }
    } catch (e) {
      print('❌ Error getting permit types: $e');
      return {
        'success': false,
        'message': 'Error getting permit types: $e',
      };
    }
  }
}
