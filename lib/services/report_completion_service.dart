import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportCompletionService {
  static const String _keyPrefix = 'report_completion_';
  
  // Save report completion to local storage
  static Future<void> markReportCompleted({
    required int storeId,
    required String reportType,
    required String date,
    required Map<String, dynamic> reportData,
    DateTime? completedAt, // Optional: use specific timestamp instead of now()
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyPrefix}${storeId}_${reportType}_$date';
      
      final completionData = {
        'storeId': storeId,
        'reportType': reportType,
        'date': date,
        'completedAt': (completedAt ?? DateTime.now()).toIso8601String(),
        'reportData': reportData,
      };
      
      await prefs.setString(key, jsonEncode(completionData));
      print('✅ Report completion saved: $reportType for store $storeId on $date');
    } catch (e) {
      print('❌ Error saving report completion: $e');
    }
  }
  
  // Check if report is completed for specific store and date
  static Future<bool> isReportCompleted({
    required int storeId,
    required String reportType,
    required String date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyPrefix}${storeId}_${reportType}_$date';
      final completionData = prefs.getString(key);
      
      if (completionData != null) {
        final data = jsonDecode(completionData);
        print('✅ Report completion found: $reportType for store $storeId on $date');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error checking report completion: $e');
      return false;
    }
  }
  
  // Get all completed reports for a specific date
  static Future<List<Map<String, dynamic>>> getCompletedReportsForDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      final completedReports = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        final completionData = prefs.getString(key);
        if (completionData != null) {
          final data = jsonDecode(completionData);
          if (data['date'] == date) {
            completedReports.add(data);
          }
        }
      }
      
      return completedReports;
    } catch (e) {
      print('❌ Error getting completed reports: $e');
      return [];
    }
  }
  
  // Get completed reports for specific store and date
  static Future<List<String>> getCompletedReportTypes({
    required int storeId,
    required String date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      final completedTypes = <String>[];
      
      for (final key in keys) {
        final completionData = prefs.getString(key);
        if (completionData != null) {
          final data = jsonDecode(completionData);
          if (data['storeId'] == storeId && data['date'] == date) {
            completedTypes.add(data['reportType']);
          }
        }
      }
      
      return completedTypes;
    } catch (e) {
      print('❌ Error getting completed report types: $e');
      return [];
    }
  }
  
  // Clear all report completions (for testing)
  static Future<void> clearAllCompletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('✅ All report completions cleared');
    } catch (e) {
      print('❌ Error clearing report completions: $e');
    }
  }
  
  // Get completion statistics
  static Future<Map<String, dynamic>> getCompletionStats(String date) async {
    try {
      final completedReports = await getCompletedReportsForDate(date);
      
      final stats = {
        'totalCompleted': completedReports.length,
        'byStore': <int, int>{},
        'byType': <String, int>{},
      };
      
      for (final report in completedReports) {
        final storeId = report['storeId'] as int?;
        final reportType = report['reportType'] as String?;
        
        if (storeId != null && reportType != null) {
          // Count by store
          (stats['byStore'] as Map<int, int>)[storeId] = ((stats['byStore'] as Map<int, int>)[storeId] ?? 0) + 1;
          
          // Count by type
          (stats['byType'] as Map<String, int>)[reportType] = ((stats['byType'] as Map<String, int>)[reportType] ?? 0) + 1;
        }
      }
      
      return stats;
    } catch (e) {
      print('❌ Error getting completion stats: $e');
      return {
        'totalCompleted': 0,
        'byStore': <int, int>{},
        'byType': <String, int>{},
      };
    }
  }
}
