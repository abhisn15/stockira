import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/availability.dart';
import 'auth_service.dart';

class AvailabilityService {
  // Get all itineraries
  static Future<AvailabilityResponse> getItineraries() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return AvailabilityResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/itineraries'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Itinerary API response: ${response.statusCode}');
      print('Itinerary API body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return AvailabilityResponse.fromJson(responseData);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return AvailabilityResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch itineraries',
          data: [],
        );
      }
    } catch (e) {
      print('Error fetching itineraries: $e');
      return AvailabilityResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get store products
  static Future<StoreProductsResponse> getStoreProducts(int storeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return StoreProductsResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/stores/products?store_id=$storeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Store Products API response: ${response.statusCode}');
      print('Store Products API body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return StoreProductsResponse.fromJson(responseData);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return StoreProductsResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch store products',
          data: [],
        );
      }
    } catch (e) {
      print('Error fetching store products: $e');
      return StoreProductsResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get all products
  static Future<StoreProductsResponse> getAllProducts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return StoreProductsResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('All Products API response: ${response.statusCode}');
      print('All Products API body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return StoreProductsResponse.fromJson(responseData);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return StoreProductsResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch products',
          data: [],
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      return StoreProductsResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Add products to store
  static Future<Map<String, dynamic>> addProductsToStore({
    required int storeId,
    required List<int> productIds,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/stores/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'store_id': storeId,
          'products': productIds,
        }),
      );

      print('Add Products API response: ${response.statusCode}');
      print('Add Products API body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Products added successfully',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add products',
        };
      }
    } catch (e) {
      print('Error adding products: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update store products
  static Future<Map<String, dynamic>> updateStoreProducts({
    required int storeId,
    required List<int> productIds,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      final response = await http.put(
        Uri.parse('${Env.apiBaseUrl}/stores/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'store_id': storeId,
          'products': productIds,
        }),
      );

      print('Update Products API response: ${response.statusCode}');
      print('Update Products API body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Products updated successfully',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update products',
        };
      }
    } catch (e) {
      print('Error updating products: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
