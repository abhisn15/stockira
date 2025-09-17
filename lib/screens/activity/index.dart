import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../../services/auth_service.dart';
import '../../services/itinerary_service.dart';
import '../../services/attendance_service.dart';
import '../../services/reports_api_service.dart';
import '../../services/report_completion_service.dart';
import '../../models/itinerary.dart';
import '../../models/attendance_record.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Itinerary data
  List<Itinerary> itineraries = [];
  List<AttendanceRecord> attendanceRecords = [];
  bool isLoading = false;
  String? errorMessage;

  // User role detection
  String? userRole; // 'SPG' or 'MD'
  int totalTasks = 0; // 10 for SPG, 11 for MD

  // Task types based on role
  List<String> get taskTypes {
    if (userRole == 'SPG') {
      return [
        translate('sales'),
        translate('oosOutOfStock'),
        translate('expiredDate'),
        translate('survey'),
        translate('regularDisplay'),
        translate('pricePrincipal'),
        translate('priceCompetitor'),
        translate('promoTracking'),
        translate('competitorActivity'),
        'Kegiatan Lain-lain',
        translate('attendance'),
      ];
    } else {
      // MD
      return [
        translate('productFocus'),
        translate('oosOutOfStock'),
        translate('expiredDate'),
        translate('display'),
        translate('pricePrincipal'),
        translate('priceCompetitor'),
        translate('promoTracking'),
        translate('competitorActivity'),
        translate('survey'),
        translate('productBelgianBerry'),
        'Kegiatan Lain-lain',
        translate('attendance'),
      ];
    }
  }

  // Selected date for filtering
  DateTime selectedDate = DateTime.now();

  // Todo items with timeline
  List<Map<String, dynamic>> todoItems = [];
  bool showTodoTimeline = false;

  // Progress tracking
  int completedTasks = 0;
  bool isItineraryCompleted = false;
  bool isLoadingReports = false;
  
  // Lazy loading state
  Map<String, bool> _loadingStates = {}; // Key: "storeId_taskName", Value: loading state
  Map<String, bool> _completionStates = {}; // Key: "storeId_taskName", Value: completion state
  Map<String, String?> _completionTimes = {}; // Key: "storeId_taskName", Value: completion time
  
  // Attendance data from API
  Map<String, Map<String, dynamic>> _attendanceData = {}; // Key: "storeId", Value: attendance details
  bool _isLoadingAttendance = false;
  
  // Pagination state
  int _currentPage = 1;
  int _itemsPerPage = 5;

  // Expanded stores state
  Map<String, bool> _expandedStores = {};

  // Timer for real-time duration updates
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadItinerariesForDate(selectedDate);
    _loadAttendanceRecords();
    _loadAttendanceData(); // Load attendance data from API
    _loadTodoItems();
    // Refresh todo completion status on init
    _refreshTodoCompletionStatus();

    // Start timer for real-time duration updates
    _startDurationTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  // Start timer for real-time duration updates
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger rebuild and update duration display
        });
      }
    });
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_position') ?? 'SPG';
      setState(() {
        userRole = role.contains('MD') ? 'MD' : 'SPG';
        totalTasks = userRole == 'SPG' ? 10 : 11;
      });
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        userRole = 'SPG';
        totalTasks = 10;
      });
    }
  }

  Future<void> _loadItinerariesForDate(DateTime date) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      print('Loading itineraries for date: $dateStr');
      final response = await ItineraryService.getItineraryByDate(dateStr);

        if (response.success) {
        setState(() {
          itineraries = response.data;
          print('Loaded ${itineraries.length} itineraries');
          _checkItineraryCompletion();
          isLoading = false;
          // Reset pagination when new data is loaded
          _currentPage = 1;
        });
        
        // Load attendance data from API
        await _loadAttendanceData();
        
        // Generate todos after loading itineraries
        await _generateDefaultTodos();
        // Refresh todo completion status to check for completed reports
        await _refreshTodoCompletionStatusOptimized();
        } else {
        setState(() {
          errorMessage = response.message;
          itineraries = [];
        isLoading = false;
      });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load itineraries: ${e.toString()}';
        itineraries = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    try {
      final response = await AttendanceService().getAllRecords();
      setState(() {
        attendanceRecords = response;
        _checkItineraryCompletion();
      });

      // Debug: Print attendance records
      print('📋 Loaded ${attendanceRecords.length} attendance records');
      for (var record in attendanceRecords) {
        print(
          '📋 Record date: ${record.date}, details: ${record.details.length}',
        );
        for (var detail in record.details) {
          print(
            '📋   Store ${detail.storeId}: checkIn=${detail.checkInTime}, checkOut=${detail.checkOutTime}',
          );
        }
      }

      // Auto-refresh todo completion status
      await _refreshTodoCompletionStatus();
    } catch (e) {
      print('Error loading attendance records: $e');
    }
  }

  Future<void> _refreshTodoCompletionStatus() async {
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    bool hasChanges = false;
    for (int i = 0; i < todoItems.length; i++) {
      final todo = todoItems[i];
      final storeId = todo['storeId'] as int? ?? 0;
      final taskName = todo['task'] as String? ?? '';
      final currentCompleted = todo['completed'] == true;

      // Check if should be auto-completed
      final shouldBeCompleted = await _checkAutoCompletion(
        storeId,
        taskName,
        dateStr,
      );

      if (currentCompleted != shouldBeCompleted) {
        todoItems[i]['completed'] = shouldBeCompleted;
        todoItems[i]['autoCompleted'] = shouldBeCompleted;
        if (shouldBeCompleted) {
          todoItems[i]['completedTime'] = await _getActualCompletionTime(storeId, taskName, dateStr);
          // Log additional activity when task is completed
          await _saveAdditionalActivityLog(
            taskName,
            todo['storeName'] as String? ?? 'Unknown Store',
            storeId,
            'completed',
          );
        }
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _saveTodoItems();
      _updateProgress();
    }
  }

  Future<void> _refreshTodoCompletionStatusOptimized() async {
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    print('🔄 [Lazy Loading] Initializing todo completion status for date: $dateStr');
    
    // Clear previous states
    setState(() {
      _loadingStates.clear();
      _completionStates.clear();
      _completionTimes.clear();
    });
    
    print('ℹ️ [Lazy Loading] Todo items ready for lazy loading. Tap any item to check completion status.');
  }

  void _checkItineraryCompletion() {
    if (itineraries.isEmpty || attendanceRecords.isEmpty) {
      setState(() {
        isItineraryCompleted = false;
      });
      return;
    }

    // Check if all stores in itinerary have attendance records
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final todayAttendance = attendanceRecords.where((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      return recordDate == dateStr;
    }).toList();

    // Get all store IDs from itinerary
    final itineraryStoreIds = <int>{};
    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        itineraryStoreIds.add(store.id);
      }
    }

    // Get all store IDs from attendance
    final attendanceStoreIds = <int>{};
    for (var record in todayAttendance) {
      for (var detail in record.details) {
        attendanceStoreIds.add(detail.storeId);
      }
    }

    // Check if all itinerary stores have attendance
    final allStoresVisited = itineraryStoreIds.every(
      (storeId) => attendanceStoreIds.contains(storeId),
    );

    setState(() {
      isItineraryCompleted = allStoresVisited;
    });
  }

  Future<void> _loadTodoItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final todoJson = prefs.getString('todo_items_$dateStr');

      if (todoJson != null) {
        final List<dynamic> todoList = json.decode(todoJson);
        setState(() {
          todoItems = todoList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _updateProgress();
        });
      } else {
        // Generate default todos if none exist
        await _generateDefaultTodos();
      }
    } catch (e) {
      print('Error loading todo items: $e');
      await _generateDefaultTodos();
    }
  }

  Future<void> _generateDefaultTodos() async {
    if (userRole == null || totalTasks == 0) return;

    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    // Generate todos for each store in itinerary
    List<Map<String, dynamic>> newTodos = [];

    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        print('Generating todos for store: ${store.name} (ID: ${store.id})');
        for (var task in taskTypes) {
          // Check if this task is already completed based on attendance and reports
          final isAutoCompleted = await _checkAutoCompletion(
            store.id,
            task,
            dateStr,
          );

          newTodos.add({
            'id':
                DateTime.now().millisecondsSinceEpoch +
                task.hashCode +
                store.id,
            'task': task,
            'storeName': store.name,
            'storeId': store.id,
            'time': DateTime.now().toIso8601String(),
            'completed': isAutoCompleted,
            'createdAt': DateTime.now().toIso8601String(),
            'date': dateStr,
            'autoCompleted': isAutoCompleted,
            'completedTime': isAutoCompleted
                ? await _getActualCompletionTime(store.id, task, dateStr)
                : null,
          });
        }
      }
    }

    print('Generated ${newTodos.length} todos');
    setState(() {
      todoItems = newTodos;
    });
    _saveTodoItems();
    _updateProgress();
  }

  Future<bool> _checkAutoCompletion(
int storeId,
    String taskName,
    String dateStr,
  ) async {
    // Special handling for Attendance task
    if (taskName == translate('attendance')) {
      return await _checkAttendanceCompletion(storeId, dateStr);
    }

    // Check if specific report has been completed using API
    String? reportType = _getReportTypeFromTask(taskName);
    if (reportType != null && reportType.isNotEmpty) {
      try {
        final isReportCompleted = await ReportsApiService.isReportCompleted(
          reportType: reportType,
          date: dateStr,
          storeId: storeId,
        );

        if (isReportCompleted) {
          // Get completion time from API
          final completionTime = await ReportsApiService.getReportCompletionTime(
            reportType: reportType,
            date: dateStr,
            storeId: storeId,
          );

          print(
            '✅ Auto-completion: $taskName completed for store $storeId on $dateStr',
          );
          if (completionTime != null) {
            print('✅ Completion time: $completionTime');
          }
          return true;
        }
      } catch (e) {
        print('❌ Error checking API completion for $taskName: $e');
        // Fallback to local storage check
        final isLocalCompleted = await ReportCompletionService.isReportCompleted(
          storeId: storeId,
          reportType: reportType,
          date: dateStr,
        );
        if (isLocalCompleted) {
          print('✅ Fallback to local completion: $taskName completed for store $storeId on $dateStr');
          return true;
        }
      }
    }

    // For other tasks, check if user has checked in/out at this store
    final hasAttendance = attendanceRecords.any((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      if (recordDate != dateStr) return false;

      return record.details.any((detail) => detail.storeId == storeId);
    });

    return hasAttendance;
  }

  Future<bool> _checkAttendanceCompletion(int storeId, String dateStr) async {
    // Check attendance status from API data
    final attendance = _attendanceData[storeId.toString()];
    if (attendance != null) {
      final checkInTime = attendance['check_in_time'] as String?;
      final checkOutTime = attendance['check_out_time'] as String?;
      
      // Consider attendance completed if both check-in and check-out are done
      if (checkInTime != null && checkOutTime != null) {
        print('✅ [Attendance API] Store $storeId: Check-in: $checkInTime, Check-out: $checkOutTime - COMPLETED');
        return true;
      } else if (checkInTime != null && checkOutTime == null) {
        print('🔄 [Attendance API] Store $storeId: Check-in: $checkInTime, Check-out: null - IN PROGRESS');
        return false;
      } else {
        print('❌ [Attendance API] Store $storeId: No check-in data - NOT STARTED');
        return false;
      }
    }
    
    // Fallback to local storage if API data not available
    print('⚠️ [Attendance API] No API data for store $storeId, checking local storage...');
    final hasCheckIn = attendanceRecords.any((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      return recordDate == dateStr &&
          record.details.any((detail) => detail.storeId == storeId);
    });

    print('📋 [Local Storage] Store $storeId attendance: ${hasCheckIn ? "FOUND" : "NOT FOUND"}');
    return hasCheckIn;
  }

  String? _getReportTypeFromTask(String taskName) {
    // Map task names to report types (matching API report types)
    final taskToReportMap = {
      'OOS': 'out_of_stock',
      'OOS (Out of Stock)': 'out_of_stock',
      'Out of Stock': 'out_of_stock',
      'Price Principal': 'price',
      'Price Competitor': 'price_competitor',
      'Promo Tracking': 'promo_tracking',
      'Competitor Activity': 'competitor_activity',
      'Activity Other': 'activity_other',
      'Kegiatan Lain-lain': 'activity_other',
      translate('survey'): 'survey',
      'Product Focus': 'product_focus',
      'Regular Display': 'reguler_display',
      'Reguler Display': 'reguler_display',
      translate('display'): 'display',
      'Product Belgian Berry': 'product_belgian_berry',
      'Expired Date': 'expired_date',
      'Display Check': 'display',
      translate('sales'): 'sales',
      'Customer Feedback': 'customer_feedback',
    };

    return taskToReportMap[taskName];
  }

  Future<String?> _getActualCompletionTime(int storeId, String taskName, String dateStr) async {
    try {
      String? reportType = _getReportTypeFromTask(taskName);
      if (reportType != null && reportType.isNotEmpty) {
        final completionTime = await ReportsApiService.getReportCompletionTime(
          reportType: reportType,
          date: dateStr,
          storeId: storeId,
        );
        return completionTime;
      }
      return DateTime.now().toIso8601String();
    } catch (e) {
      print('❌ Error getting actual completion time: $e');
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _saveTodoItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      await prefs.setString('todo_items_$dateStr', json.encode(todoItems));
    } catch (e) {
      print('Error saving todo items: $e');
    }
  }

  // Save additional activity log
  Future<void> _saveAdditionalActivityLog(
    String taskName,
    String storeName,
    int storeId,
    String status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      // Get existing activity logs
      final existingLogs =
          prefs.getString('additional_activity_logs_$dateStr') ?? '[]';
      final List<dynamic> activityLogs = json.decode(existingLogs);

      // Add new activity log
      final newLog = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'taskName': taskName,
        'storeName': storeName,
        'storeId': storeId,
        'status': status, // 'completed' or 'started'
        'timestamp': DateTime.now().toIso8601String(),
        'date': dateStr,
      };

      activityLogs.add(newLog);

      // Save back to preferences
      await prefs.setString(
        'additional_activity_logs_$dateStr',
        json.encode(activityLogs),
      );

      print(
        '📝 Additional activity logged: $taskName - $status at ${newLog['timestamp']}',
      );
    } catch (e) {
      print('Error saving additional activity log: $e');
    }
  }

  void _updateProgress() {
    setState(() {
      completedTasks = todoItems
          .where((item) => item['completed'] == true)
          .length;
    });
  }


  Future<void> _clearAllActivities() async {
    setState(() {
      todoItems.clear();
      itineraries.clear();
      completedTasks = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    await prefs.remove('todo_items_$dateStr');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All activities and todos cleared')),
    );
  }

  List<Map<String, dynamic>> getStoreVisits() {
    // Get stores from itinerary API for selected date
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    // Get attendance records for today to get check-in/check-out times
    final todayAttendance = attendanceRecords.where((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      return recordDate == dateStr;
    }).toList();

    // Create a map of visited stores from attendance records
    Map<int, Map<String, dynamic>> visitedStores = {};
    for (var record in todayAttendance) {
      for (var detail in record.details) {
        visitedStores[detail.storeId] = {
          'checkInTime': detail.checkInTime,
          'checkOutTime': detail.checkOutTime,
          'storeName': detail.storeName,
        };
      }
    }

    // Group by store from itinerary API - show ALL stores from itinerary
    Map<String, Map<String, dynamic>> storeVisits = {};

    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        final storeName = store.name;
        final storeId = store.id;

        // Show ALL stores from itinerary, regardless of attendance
        if (!storeVisits.containsKey(storeName)) {
          storeVisits[storeName] = {
            'storeName': storeName,
            'storeId': storeId,
            'totalTasks': 0,
            'completedTasks': 0,
            'checkInTime': visitedStores.containsKey(storeId)
                ? visitedStores[storeId]!['checkInTime']
                : null,
            'checkOutTime': visitedStores.containsKey(storeId)
                ? visitedStores[storeId]!['checkOutTime']
                : null,
            'todos': <Map<String, dynamic>>[],
          };
        }

        // Get todos for this store
        final storeTodos = todoItems
            .where((todo) => (todo['storeName'] as String? ?? '') == storeName)
            .toList();

        storeVisits[storeName]!['totalTasks'] = storeTodos.length;
        storeVisits[storeName]!['completedTasks'] = storeTodos
            .where((todo) => todo['completed'] == true)
            .length;
        storeVisits[storeName]!['todos'] = storeTodos;
      }
    }

    return storeVisits.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateFilterDialog,
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () =>
                setState(() => showTodoTimeline = !showTodoTimeline),
            tooltip: 'Todo Timeline',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllActivities,
            tooltip: 'Clear All',
          ),
          IconButton(
            icon: _isLoadingAttendance 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: _isLoadingAttendance ? null : () async {
              await _loadItinerariesForDate(selectedDate);
              await _refreshAttendanceData();
              await _refreshTodoCompletionStatus();
            },
            tooltip: _isLoadingAttendance ? 'Refreshing...' : 'Reload',
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with date and store count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                        color: Color(0xFF29BDCE),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                        '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29BDCE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${translate('totalStores')}: ${itineraries.fold(0, (sum, itinerary) => sum + itinerary.stores.length)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Todo Timeline (if enabled)
            if (showTodoTimeline && todoItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          translate('todoTimeline'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          onPressed: _showTodoTimelineDialog,
                          tooltip: translate('viewFullTimeline'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...todoItems
                        .take(3)
                        .map(
                          (item) => _buildLazyTodoItem(item),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Store visits list with pagination
            Expanded(
              child: isLoading || _isLoadingAttendance
                  ? _buildSkeletonLoading()
                  : errorMessage != null
                  ? _buildErrorState(errorMessage!)
                  : getStoreVisits().isEmpty
                  ? _buildEmptyState()
                  : _buildPaginatedStoreList(),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder methods - these will be implemented in the next part
  void _showDateFilterDialog() {
    // TODO: Implement date filter dialog
  }

  void _showTodoTimelineDialog() {
    // TODO: Implement todo timeline dialog
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            translate('noTasksFound'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              translate('noTasksScheduled'),
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 24),
            Text(
            translate('errorLoadingData'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _loadItinerariesForDate(selectedDate);
              await _refreshTodoCompletionStatus();
            },
            child: Text(translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => _buildSkeletonCard()),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Time skeleton
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Store info skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress skeleton
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Todo items skeleton
          ...List.generate(2, (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                child: Container(
                    height: 12,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaginatedStoreList() {
    final allStores = getStoreVisits();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allStores.length);
    final currentPageStores = allStores.sublist(startIndex, endIndex);
    
    return Column(
      children: [
        // Store list
        Expanded(
          child: ListView.builder(
            itemCount: currentPageStores.length,
            itemBuilder: (context, i) {
              final storeVisit = currentPageStores[i];
              return _buildStoreVisitItem(context, storeVisit, startIndex + i);
            },
          ),
        ),
        
        // Pagination controls
        if (allStores.length > _itemsPerPage)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: _currentPage > 1 ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage > 1 ? const Color(0xFF29BDCE) : Colors.grey[300],
                    foregroundColor: _currentPage > 1 ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                
                // Page info
                Text(
                  'Page $_currentPage of ${(allStores.length / _itemsPerPage).ceil()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Next button
                ElevatedButton.icon(
                  onPressed: _currentPage < (allStores.length / _itemsPerPage).ceil() ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage < (allStores.length / _itemsPerPage).ceil() ? const Color(0xFF29BDCE) : Colors.grey[300],
                    foregroundColor: _currentPage < (allStores.length / _itemsPerPage).ceil() ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    final totalPages = (getStoreVisits().length / _itemsPerPage).ceil();
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  // Placeholder methods for remaining functionality
  Widget _buildStoreVisitItem(BuildContext context, Map<String, dynamic> storeVisit, int index) {
    final storeName = storeVisit['storeName'] as String? ?? 'Unknown Store';
    final storeId = storeVisit['storeId'] as int? ?? 0;
    final completedTasks = storeVisit['completedTasks'] as int? ?? 0;
    final totalTasks = storeVisit['totalTasks'] as int? ?? 0;
    final todos = storeVisit['todos'] as List<Map<String, dynamic>>? ?? [];
    
    return StatefulBuilder(
      builder: (context, setState) {
        // Use a key to maintain state for each store
        final storeKey = '${storeName}_$index';
        bool isExpanded = _expandedStores[storeKey] ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main store visit info
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedStores[storeKey] = !isExpanded;
                  });
                  // Also update the main widget state
                  this.setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Time
                      // Container(
                      //   width: 60,
                      //   child: Text(
                      //     _getAttendanceStatusText(storeId),
                      //     style: TextStyle(
                      //       fontSize: 14,
                      //       fontWeight: FontWeight.bold,
                      //       color: _getAttendanceStatus(storeId) ? const Color(0xFF29BDCE) : Colors.grey[400],
                      //     ),
                      //   ),
                      // ),
                      
                      // const SizedBox(width: 12),
                      
                      // Store icon and name
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF29BDCE).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Color(0xFF29BDCE),
                          size: 60,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Store details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getAttendanceStatusText(storeId),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getAttendanceStatus(storeId) ? const Color(0xFF29BDCE) : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  translate('progress') + ': ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '$completedTasks/$totalTasks',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF29BDCE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: totalTasks > 0 ? completedTasks / totalTasks : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completedTasks == totalTasks ? Colors.green : const Color(0xFF29BDCE),
                              ),
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                      
                      // Dropdown arrow
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded task details
              if (isExpanded) ...[
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[200],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translate('taskDetails'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29BDCE),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimelineTodos(todos),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLazyTodoItem(Map<String, dynamic> item) {
    final isCompleted = item['completed'] == true;
    final taskName = item['task'] as String? ?? 'Unknown Task';
    final storeName = item['storeName'] as String? ?? 'Unknown Store';
    final storeId = item['storeId'] as int? ?? 0;
    final key = '${storeId}_$taskName';
    final isLoading = _loadingStates[key] ?? false;
    final completionTime = _completionTimes[key];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : isLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : const Icon(Icons.radio_button_unchecked, color: Colors.white, size: 12),
          ),
          
          const SizedBox(width: 12),
          
          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green[700] : Colors.black87,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  storeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (isCompleted && completionTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Selesai pada: ${_formatCompletionTime(completionTime)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          if (!isCompleted && !isLoading)
            GestureDetector(
              onTap: () => _loadTodoCompletionStatus(storeId, taskName),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineTodos(List<Map<String, dynamic>> todos) {
    return Column(
      children: todos.asMap().entries.map((entry) {
        final index = entry.key;
        final todo = entry.value;
        final isCompleted = todo['completed'] == true;
        final taskName = todo['task'] as String? ?? 'Unknown Task';
        final isLast = index == todos.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                // Timeline dot
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey[400],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                // Timeline line
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Task content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            taskName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green[700] : Colors.black87,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              translate('done'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      isCompleted 
                          ? translate('taskAutoCompleted') 
                          : translate('taskWillAutoComplete'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted ? Colors.green[600] : Colors.grey[600],
                      ),
                    ),
                    
                    if (isCompleted && todo['completedTime'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        translate('completedAt') + ': ${_formatCompletionTime(todo['completedTime'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    if (!isCompleted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                translate('taskWillAutoComplete'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    final months = [
      translate('jan'),
      translate('feb'),
      translate('mar'),
      translate('apr'),
      translate('may'),
      translate('jun'),
      translate('jul'),
      translate('aug'),
      translate('sep'),
      translate('oct'),
      translate('nov'),
      translate('dec'),
    ];
    return months[month - 1];
  }

  // Attendance status methods
  bool _getAttendanceStatus(int storeId) {
    final attendance = _attendanceData[storeId.toString()];
    if (attendance == null) return false;
    
    final checkInTime = attendance['check_in_time'] as String?;
    final checkOutTime = attendance['check_out_time'] as String?;
    
    return checkInTime != null && checkOutTime != null;
  }

  String _getAttendanceStatusText(int storeId) {
    final attendance = _attendanceData[storeId.toString()];
    if (attendance == null) return 'Belum check-in';
    
    final checkInTime = attendance['check_in_time'] as String?;
    final checkOutTime = attendance['check_out_time'] as String?;
    
    if (checkInTime == null) {
      return 'Belum check-in';
    } else if (checkOutTime == null) {
      return 'Masih di toko (Check-in: ${checkInTime.substring(0, 5)})';
    } else {
      final duration = _calculateDurationFromAPI(checkInTime, checkOutTime);
      return 'Selesai ($duration)';
    }
  }

  String _formatCompletionTime(String? completionTime) {
    if (completionTime == null) return '';
    
    try {
      final dateTime = DateTime.parse(completionTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return completionTime;
    }
  }

  Future<void> _loadTodoCompletionStatus(int storeId, String taskName) async {
    final key = '${storeId}_$taskName';
    
    setState(() {
      _loadingStates[key] = true;
    });

    try {
      final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final reportType = _getReportTypeFromTask(taskName);
      
      if (reportType != null) {
        final isCompleted = await ReportsApiService.isReportCompleted(
          storeId: storeId, 
          reportType: reportType, 
          date: dateStr
        );
        final completionTime = isCompleted 
            ? await ReportsApiService.getReportCompletionTime(
                storeId: storeId, 
                reportType: reportType, 
                date: dateStr
              )
            : null;
        
        setState(() {
          _completionStates[key] = isCompleted;
          _completionTimes[key] = completionTime;
          _loadingStates[key] = false;
        });
      }
    } catch (e) {
      print('Error loading todo completion status: $e');
      setState(() {
        _loadingStates[key] = false;
      });
    }
  }


  String _calculateDurationFromAPI(String? checkInTime, String? checkOutTime) {
    if (checkInTime == null) return '0h 0m';
    
    try {
      final checkIn = DateTime.parse('2024-01-01 $checkInTime');
      final checkOut = checkOutTime != null 
          ? DateTime.parse('2024-01-01 $checkOutTime')
          : DateTime.now();
      
      final duration = checkOut.difference(checkIn);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      if (checkOutTime == null) {
        return '${hours}h ${minutes}m (live)';
      } else {
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return '0h 0m';
    }
  }

  // Attendance data loading from API
  Future<void> _loadAttendanceData() async {
    if (_isLoadingAttendance) return;
    
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ [Attendance API] No auth token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [Attendance API] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📡 [Attendance API] Response data: $responseData');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> attendanceList = responseData['data'];
          
          // Clear previous data
          _attendanceData.clear();
          
          // Process attendance data
          for (var attendance in attendanceList) {
            final List<dynamic> details = attendance['details'] ?? [];
            
            for (var detail in details) {
              final storeId = detail['store_id']?.toString() ?? '';
              if (storeId.isNotEmpty) {
                _attendanceData[storeId] = {
                  'check_in_time': detail['check_in_time'],
                  'check_out_time': detail['check_out_time'],
                  'store_name': detail['store_name'],
                  'distance_in': detail['distance_in'],
                  'distance_out': detail['distance_out'],
                  'note_in': detail['note_in'],
                  'note_out': detail['note_out'],
                  'image_url_in': detail['image_url_in'],
                  'image_url_out': detail['image_url_out'],
                  'created_at': detail['created_at'],
                  'updated_at': detail['updated_at'],
                };
                
                print('✅ [Attendance API] Loaded data for store $storeId: checkIn=${detail['check_in_time']}, checkOut=${detail['check_out_time']}');
              }
            }
          }
          
          print('📊 [Attendance API] Loaded ${_attendanceData.length} store attendance records');
          
          // Update UI
          setState(() {});
        } else {
          print('❌ [Attendance API] Invalid response format');
        }
      } else {
        print('❌ [Attendance API] Failed to load attendance data: ${response.statusCode}');
        print('❌ [Attendance API] Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ [Attendance API] Error loading attendance data: $e');
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  Future<void> _refreshAttendanceData() async {
    print('🔄 [Attendance API] Refreshing attendance data...');
    await _loadAttendanceData();
  }

}
