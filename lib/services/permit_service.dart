import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';

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
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      // Add form fields
      request.fields['permit_type_id'] = permitTypeId.toString();
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason;
      
      // Add image file
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📤 Permit submission response: ${response.statusCode}');
      print('📤 Permit submission body: ${response.body}');
      
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
