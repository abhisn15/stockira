import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../models/timeline_event.dart';
import 'auth_service.dart';
import 'http_client_service.dart';

class ActivityLazyLoadingService {
  static const int _pageSize = 10;
  static const int _maxRetries = 3;

  /// Load more activity events for a specific attendance record
  static Future<List<TimelineEvent>> loadMoreActivityEvents({
    required int attendanceRecordId,
    required int page,
    int pageSize = _pageSize,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/attendance-records/$attendanceRecordId/activities').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': pageSize.toString(),
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
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return _parseActivityEvents(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load activities');
        }
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading activity events: $e');
      rethrow;
    }
  }

  /// Check if there are more activities to load
  static Future<bool> hasMoreActivities({
    required int attendanceRecordId,
    required int currentPage,
    int pageSize = _pageSize,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/attendance-records/$attendanceRecordId/activities').replace(
        queryParameters: {
          'page': (currentPage + 1).toString(),
          'per_page': pageSize.toString(),
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
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final activities = data['data'] as List;
          return activities.isNotEmpty;
        }
      }
      return false;
    } catch (e) {
      print('Error checking for more activities: $e');
      return false;
    }
  }

  /// Load activity events with retry mechanism
  static Future<List<TimelineEvent>> loadActivityEventsWithRetry({
    required int attendanceRecordId,
    required int page,
    int pageSize = _pageSize,
    int retryCount = 0,
  }) async {
    try {
      return await loadMoreActivityEvents(
        attendanceRecordId: attendanceRecordId,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      if (retryCount < _maxRetries) {
        print('Retrying load activity events (attempt ${retryCount + 1}/$_maxRetries): $e');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return loadActivityEventsWithRetry(
          attendanceRecordId: attendanceRecordId,
          page: page,
          pageSize: pageSize,
          retryCount: retryCount + 1,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Parse activity events from API response
  static List<TimelineEvent> _parseActivityEvents(List<dynamic> data) {
    return data.map((item) {
      final eventType = item['type'] ?? 'unknown';
      final timestamp = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
      
      switch (eventType.toLowerCase()) {
        case 'check_in':
          return TimelineEvent(
            time: timestamp,
            title: 'Check In',
            subtitle: item['store_name'] ?? 'Unknown Store',
            icon: Icons.login,
            color: Colors.green,
            isCompleted: true,
            isActive: false,
          );
        case 'check_out':
          return TimelineEvent(
            time: timestamp,
            title: 'Check Out',
            subtitle: 'Work completed',
            icon: Icons.logout,
            color: Colors.red,
            isCompleted: true,
            isActive: false,
          );
        case 'break_start':
          return TimelineEvent(
            time: timestamp,
            title: 'Break Start',
            subtitle: 'Taking a break',
            icon: Icons.pause,
            color: Colors.orange,
            isCompleted: true,
            isActive: false,
          );
        case 'break_end':
          return TimelineEvent(
            time: timestamp,
            title: 'Break End',
            subtitle: 'Break finished',
            icon: Icons.play_arrow,
            color: Colors.blue,
            isCompleted: true,
            isActive: false,
          );
        case 'report_submitted':
          return TimelineEvent(
            time: timestamp,
            title: 'Report Submitted',
            subtitle: item['report_type'] ?? 'Report',
            icon: Icons.assignment_turned_in,
            color: Colors.purple,
            isCompleted: true,
            isActive: false,
          );
        case 'location_update':
          return TimelineEvent(
            time: timestamp,
            title: 'Location Updated',
            subtitle: 'Location changed',
            icon: Icons.location_on,
            color: Colors.teal,
            isCompleted: true,
            isActive: false,
          );
        default:
          return TimelineEvent(
            time: timestamp,
            title: item['title'] ?? 'Activity',
            subtitle: item['description'] ?? 'Unknown activity',
            icon: Icons.info,
            color: Colors.grey,
            isCompleted: true,
            isActive: false,
          );
      }
    }).toList();
  }

  /// Get loading message based on current state
  static String getLoadingMessage({
    required bool isLoading,
    required bool hasMore,
    required int currentPage,
  }) {
    if (isLoading) {
      if (currentPage == 0) {
        return 'Loading activities...';
      } else {
        return 'Loading more activities...';
      }
    } else if (hasMore) {
      return 'More activities available';
    } else {
      return 'All activities loaded';
    }
  }

  /// Validate attendance record ID
  static bool isValidAttendanceRecordId(int? id) {
    return id != null && id > 0;
  }

  /// Get default page size
  static int getDefaultPageSize() {
    return _pageSize;
  }

  /// Get max retries
  static int getMaxRetries() {
    return _maxRetries;
  }
}
