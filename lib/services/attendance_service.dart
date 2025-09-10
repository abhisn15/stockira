import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attendance_record.dart';
import '../config/env.dart';
import 'auth_service.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance_records';
  
  // Singleton pattern
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  // Get all attendance records
  Future<List<AttendanceRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList(_attendanceKey) ?? [];
    
    return recordsJson
        .map((json) => AttendanceRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get records by date range
  Future<List<AttendanceRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allRecords = await getAllRecords();
    return allRecords.where((record) {
      return record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get records by status
  Future<List<AttendanceRecord>> getRecordsByStatus(String status) async {
    final allRecords = await getAllRecords();
    return allRecords.where((record) => record.status == status).toList();
  }

  // Get today's record
  Future<AttendanceRecord?> getTodayRecord() async {
    final today = DateTime.now();
    final allRecords = await getAllRecords();
    
    try {
      return allRecords.firstWhere((record) {
        return record.date.year == today.year &&
               record.date.month == today.month &&
               record.date.day == today.day;
      });
    } catch (e) {
      return null;
    }
  }

  // Save or update a record
  Future<void> saveRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final allRecords = await getAllRecords();
    
    // Remove existing record with same ID
    allRecords.removeWhere((r) => r.id == record.id);
    
    // Add updated record
    allRecords.add(record);
    
    // Save back to preferences
    final recordsJson = allRecords
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    
    await prefs.setStringList(_attendanceKey, recordsJson);
  }

  // Create new record for today
  Future<AttendanceRecord> createTodayRecord() async {
    final today = DateTime.now();
    final existingRecord = await getTodayRecord();
    
    if (existingRecord != null) {
      return existingRecord;
    }
    
    final newRecord = AttendanceRecord(
      id: '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}',
      date: today,
      createdAt: today,
      updatedAt: today,
    );
    
    await saveRecord(newRecord);
    return newRecord;
  }

  // Check in
  Future<AttendanceRecord> checkIn({
    required int storeId,
    required String storeName,
    required XFile image,
    required String note,
  }) async {
    try {
      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      // Get current location with error handling
      Position position;
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        // Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('Location error: $e');
        // Use default location if GPS fails
        position = Position(
          latitude: -6.200000,
          longitude: 106.816666,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/attendances/check-in'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add fields
      final now = DateTime.now();
      request.fields.addAll({
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'store_id': storeId.toString(),
        'check_in_time': now.toIso8601String().split('T')[1].split('Z')[0],
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'note': note,
        'is_out_itinerary': '0',
      });

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Check-in Request: ${request.fields}');

      print('Check-in API response: ${response.statusCode}');
      print('Check-in API body: ${response.body}');

      if (response.statusCode == 200) {
        // API call successful, save locally for offline access
        final today = DateTime.now();
        
        final record = await createTodayRecord();
        final updatedRecord = record.copyWith(
          checkInTime: today,
          storeName: storeName,
          status: 'checked_in',
          updatedAt: today,
        );
        
        await saveRecord(updatedRecord);
        return updatedRecord;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Check-in failed');
      }
    } catch (e) {
      print('Error during check-in: $e');
      // Fallback to local storage if API fails
      final today = DateTime.now();
      final timeString = '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
      
      final record = await createTodayRecord();
      final updatedRecord = record.copyWith(
        checkInTime: today,
        storeName: storeName,
        status: 'checked_in',
        updatedAt: today,
      );
      
      await saveRecord(updatedRecord);
      return updatedRecord;
    }
  }

  // Check out
  Future<AttendanceRecord> checkOut({
    required XFile image,
    required String note,
  }) async {
    try {
      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      // Get current location with error handling
      Position position;
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        // Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('Location error: $e');
        // Use default location if GPS fails
        position = Position(
          latitude: -6.200000,
          longitude: 106.816666,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/attendances/check-out'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add fields
      final now = DateTime.now();
      request.fields.addAll({
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'check_out_time': now.toIso8601String(),
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'note': note,
        'is_out_itinerary': '1',
      });

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Check-out API response: ${response.statusCode}');
      print('Check-out API body: ${response.body}');

      if (response.statusCode == 200) {
        // API call successful, save locally for offline access
        final today = DateTime.now();
        
        final record = await getTodayRecord();
        if (record == null || record.checkInTime == null) {
          throw Exception('No check-in found for today');
        }
        
        // Calculate duration
        final duration = today.difference(record.checkInTime!).inMinutes;
        
        final updatedRecord = record.copyWith(
          checkOutTime: today,
          duration: duration,
          status: 'completed',
          updatedAt: today,
        );
        
        await saveRecord(updatedRecord);
        return updatedRecord;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Check-out failed');
      }
    } catch (e) {
      print('Error during check-out: $e');
      // Fallback to local storage if API fails
      final today = DateTime.now();
      final timeString = '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
      
      final record = await getTodayRecord();
      if (record == null || record.checkInTime == null) {
        throw Exception('No check-in found for today');
      }
      
      // Calculate duration
      final duration = today.difference(record.checkInTime!).inMinutes;
      
      final updatedRecord = record.copyWith(
        checkOutTime: today,
        duration: duration,
        status: 'completed',
        updatedAt: today,
      );
      
      await saveRecord(updatedRecord);
      return updatedRecord;
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final records = await getRecordsByDateRange(start, end);
    
    final totalDays = records.length;
    final completedDays = records.where((r) => r.isCompleted).length;
    final totalWorkingMinutes = records
        .where((r) => r.isCompleted)
        .fold(0, (sum, r) => sum + r.workingMinutes);
    
    final averageWorkingMinutes = completedDays > 0 
        ? totalWorkingMinutes ~/ completedDays 
        : 0;
    
    return {
      'totalDays': totalDays,
      'completedDays': completedDays,
      'totalWorkingMinutes': totalWorkingMinutes,
      'averageWorkingMinutes': averageWorkingMinutes,
      'completionRate': totalDays > 0 ? (completedDays / totalDays * 100).round() : 0,
    };
  }

  // Clear all records (for testing)
  Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attendanceKey);
  }

  // Get attendance records for calendar view
  Future<List<AttendanceRecord>> getAttendanceRecordsForCalendar({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('No authentication token available for calendar data');
        return [];
      }

      // Build query parameters
      String url = '${Env.apiBaseUrl}/attendances';
      List<String> queryParams = [];
      
      if (startDate != null) {
        queryParams.add('start_date=${startDate.toIso8601String().split('T')[0]}');
      }
      if (endDate != null) {
        queryParams.add('end_date=${endDate.toIso8601String().split('T')[0]}');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Calendar attendance API response: ${response.statusCode}');
      print('Calendar attendance API body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> records = responseData['data'];
          return records.map((record) => AttendanceRecord.fromJson(record)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching calendar attendance data: $e');
      return [];
    }
  }

  // Get attendance records for a specific date
  Future<List<AttendanceRecord>> getAttendanceRecordsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await getAttendanceRecordsForCalendar(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Get attendance records for a week
  Future<List<AttendanceRecord>> getAttendanceRecordsForWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return await getAttendanceRecordsForCalendar(
      startDate: weekStart,
      endDate: weekEnd,
    );
  }

  // Get attendance records for a month
  Future<List<AttendanceRecord>> getAttendanceRecordsForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    return await getAttendanceRecordsForCalendar(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
}
