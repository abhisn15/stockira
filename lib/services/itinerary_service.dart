import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/itinerary.dart';
import 'auth_service.dart';

class ItineraryService {
  // Get all itineraries
  static Future<ItineraryResponse> getItineraries() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ItineraryResponse(
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
        return ItineraryResponse.fromJson(responseData);
      } else {
        // Handle error response
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return ItineraryResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch itineraries',
          data: [],
        );
      }
    } catch (e) {
      print('Error fetching itineraries: $e');
      return ItineraryResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get itinerary by date
  static Future<ItineraryResponse> getItineraryByDate(String date) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ItineraryResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/itineraries?date=$date'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Itinerary by date API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return ItineraryResponse.fromJson(responseData);
        } catch (e) {
          print('Error parsing itinerary response for date $date: $e');
          return ItineraryResponse(
            success: false,
            message: 'Failed to parse itinerary data: ${e.toString()}',
            data: [],
          );
        }
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return ItineraryResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch itinerary for date',
            data: [],
          );
        } catch (e) {
          return ItineraryResponse(
            success: false,
            message: 'Failed to fetch itinerary for date (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching itinerary by date: $e');
      return ItineraryResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get today's itinerary count
  static Future<int> getTodayItineraryCount() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      final response = await getItineraryByDate(today);
      
      if (response.success) {
        return response.data.length;
      } else {
        print('Failed to get today itinerary count: ${response.message}');
        return 0;
      }
    } catch (e) {
      print('Error getting today itinerary count: $e');
      return 0;
    }
  }

  // Get total itinerary count
  static Future<int> getTotalItineraryCount() async {
    try {
      final response = await getItineraries();

      if (response.success) {
        // Ambil jumlah store dari setiap itinerary
        int totalStores = 0;
        for (var itinerary in response.data) {
          totalStores += itinerary.stores.length;
        }
        return totalStores;
      } else {
        print('Failed to get total itinerary count: ${response.message}');
        return 0;
      }
    } catch (e) {
      print('Error getting total itinerary count: $e');
      return 0;
    }
  }
}
