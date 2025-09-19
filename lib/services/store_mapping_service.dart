import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/store_mapping.dart';
import 'auth_service.dart';
import 'http_client_service.dart';

class StoreMappingService {
  
  /// Get stores by employee ID
  static Future<StoresResponse> getStoresByEmployee(int employeeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores').replace(
        queryParameters: {
          'conditions[employees.id]': employeeId.toString(),
        },
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return StoresResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load stores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading stores: $e');
    }
  }

  /// Get stores by sub area ID
  static Future<StoresResponse> getStoresBySubArea(int subAreaId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores').replace(
        queryParameters: {
          'conditions[sub_area_id]': subAreaId.toString(),
        },
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return StoresResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load stores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading stores: $e');
    }
  }

  /// Get all areas
  static Future<AreasResponse> getAreas({String? search}) async {
    try {
      print('StoreMappingService.getAreas() called');
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('Token tidak ditemukan');
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
        final areasResponse = AreasResponse.fromJson(decoded);
        print('Areas parsed: ${areasResponse.data.length} areas');
        return areasResponse;
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAreas: $e');
      throw Exception('Error loading areas: $e');
    }
  }

  /// Get sub areas by area ID
  static Future<AccountsResponse> getAccounts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/accounts');

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AccountsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load accounts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading accounts: $e');
      rethrow;
    }
  }

  static Future<SubAreasResponse> getSubAreas(int areaId) async {
    try {
      print('StoreMappingService.getSubAreas() called with areaId: $areaId');
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('Token tidak ditemukan');
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
        final subAreasResponse = SubAreasResponse.fromJson(decoded);
        print('Sub areas parsed: ${subAreasResponse.data.length} sub areas');
        return subAreasResponse;
      } else {
        throw Exception('Failed to load sub areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getSubAreas: $e');
      throw Exception('Error loading sub areas: $e');
    }
  }

  /// Add stores to employee
  static Future<AddStoresResponse> addStoresToEmployee(List<int> storeIds) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final request = AddStoresRequest(storeIds: storeIds);

      final response = await HttpClientService.post(
        Uri.parse('${Env.apiBaseUrl}/employees/stores'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddStoresResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add stores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding stores: $e');
    }
  }

  /// Update store location
  static Future<LocationUpdateResponse> updateStoreLocation({
    required int storeId,
    required double latitudeOld,
    required double longitudeOld,
    required double latitudeNew,
    required double longitudeNew,
    required String reason,
    required File imageFile,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final url = Uri.parse('${Env.apiBaseUrl}/stores/location-update');
      
      // Prepare form fields
      final fields = {
        'store_id': storeId.toString(),
        'latitude_old': latitudeOld.toString(),
        'longitude_old': longitudeOld.toString(),
        'latitude_new': latitudeNew.toString(),
        'longitude_new': longitudeNew.toString(),
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
        return LocationUpdateResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  /// Get current employee ID (you might need to implement this based on your auth system)
  static Future<int?> getCurrentEmployeeId() async {
    print('StoreMappingService.getCurrentEmployeeId() called');
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        // Assuming user model has employee ID or you can get it from somewhere else
        // You might need to modify this based on your user model structure
        return user.employee?.id; // or user.employeeId if available
      }
      return null;
    } catch (e) {
      print('Error getting current employee ID: $e');
      return null;
    }
  }

  /// Get current employee ID from stored data (alternative method)
  static Future<int?> getCurrentEmployeeIdFromStoredData() async {
    print('StoreMappingService.getCurrentEmployeeIdFromStoredData() called');
    try {
      // Try to get from stored user data
      final user = await AuthService.getUser();
      if (user != null) {
        // Check if user has employee ID field
        // This might need to be adjusted based on your user model
        print('User: $user');
        return user.employee?.id; // Assuming user.employee.id is the employee ID
      }

      // If not available, you might want to make an API call to get current user profile
      // and extract employee ID from there
      return null;
    } catch (e) {
      print('Error getting current employee ID from stored data: $e');
      return null;
    }
  }

  /// Search stores by name or code
  static Future<StoresResponse> searchStores(String query, {int? employeeId, int? subAreaId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final queryParams = <String, String>{
        'search': query,
      };

      if (employeeId != null) {
        queryParams['conditions[employees.id]'] = employeeId.toString();
      }

      if (subAreaId != null) {
        queryParams['conditions[sub_area_id]'] = subAreaId.toString();
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores').replace(
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
        return StoresResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to search stores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching stores: $e');
    }
  }

  /// Get store by ID
  static Future<Store?> getStoreById(int storeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await HttpClientService.get(
        Uri.parse('${Env.apiBaseUrl}/stores/$storeId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Store.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting store by ID: $e');
      return null;
    }
  }

  /// Validate store location data
  static bool validateLocationData({
    required double latitudeOld,
    required double longitudeOld,
    required double latitudeNew,
    required double longitudeNew,
  }) {
    // Check if coordinates are valid
    if (latitudeOld < -90 || latitudeOld > 90 ||
        longitudeOld < -180 || longitudeOld > 180 ||
        latitudeNew < -90 || latitudeNew > 90 ||
        longitudeNew < -180 || longitudeNew > 180) {
      return false;
    }

    // Check if old and new coordinates are different
    if (latitudeOld == latitudeNew && longitudeOld == longitudeNew) {
      return false;
    }

    return true;
  }

  /// Calculate distance between two coordinates (in meters)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}