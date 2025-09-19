import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import 'auth_service.dart';
import 'http_client_service.dart';

class CreateLocationService {
  /// Create new location request
  static Future<Map<String, dynamic>> createLocationRequest({
    required String name,
    required int subAreaId,
    required int accountId,
    required double latitude,
    required double longitude,
    required String address,
    File? image,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores/new-request');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['name'] = name;
      request.fields['sub_area_id'] = subAreaId.toString();
      request.fields['account_id'] = accountId.toString();
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address;

      // Add image if provided
      if (image != null) {
        final imageFile = await http.MultipartFile.fromPath(
          'image',
          image.path,
        );
        request.files.add(imageFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create Location API response status: ${response.statusCode}');
      print('Create Location API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return {
          'success': true,
          'data': decoded,
        };
      } else {
        final decoded = json.decode(response.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to create location request',
          'data': decoded,
        };
      }
    } catch (e) {
      print('Error in createLocationRequest: $e');
      return {
        'success': false,
        'message': 'Error creating location request: $e',
      };
    }
  }

  /// Get areas for filtering
  static Future<Map<String, dynamic>> getAreas({String? search}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/areas').replace(
        queryParameters: queryParams,
      );

      print('Areas API URL: ${uri.toString()}');

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Areas API response status: ${response.statusCode}');
      print('Areas API response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return {
          'success': true,
          'data': decoded['data'] ?? [],
        };
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAreas: $e');
      return {
        'success': false,
        'message': 'Error loading areas: $e',
        'data': [],
      };
    }
  }

  /// Get sub-areas by area ID
  static Future<Map<String, dynamic>> getSubAreas(int areaId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/sub-areas').replace(
        queryParameters: {
          'area_id': areaId.toString(),
        },
      );

      print('Sub areas API URL: ${uri.toString()}');

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Sub areas API response status: ${response.statusCode}');
      print('Sub areas API response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return {
          'success': true,
          'data': decoded['data'] ?? [],
        };
      } else {
        throw Exception('Failed to load sub areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getSubAreas: $e');
      return {
        'success': false,
        'message': 'Error loading sub areas: $e',
        'data': [],
      };
    }
  }
}
