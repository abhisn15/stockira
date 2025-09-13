import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/services/itinerary_service.dart';
import 'package:stockira/models/attendance_record.dart';
import 'package:stockira/widgets/attendance_list_widget.dart';
import 'package:stockira/widgets/cute_loading_widget.dart';
import 'Maps/index.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  late DateTime firstDayOfMonth;
  late DateTime lastDayOfMonth;

  // Services
  final AttendanceService _attendanceService = AttendanceService();

  // Data absensi per hari, key: yyyy-MM-dd, value: Map (checkin, checkout, dll)
  Map<String, Map<String, dynamic>> attendanceData = {};
  List<AttendanceRecord> attendanceRecords = [];

  // Store meta from itinerary (code, address) keyed by store_id
  Map<int, String> storeCodeMap = {};
  Map<int, String> storeAddressMap = {};

  // KPI
  int totalMasuk = 0;
  int totalHari = 0;
  int plan = 0;
  int actual = 0;
  double ach = double.nan;
  int uniqueStore = 0;
  int noOut = 0;
  int lessThan5Min = 0;

  // Statistics
  Map<String, dynamic> statistics = {};
  bool isLoading = false;
  bool isCalendarLoading = false;
  
  // Calendar data cache - key: "YYYY-MM", value: List<AttendanceRecord>
  Map<String, List<AttendanceRecord>> calendarDataCache = {};

  @override
  void initState() {
    super.initState();
    _setPeriod(selectedDate);
    _loadAttendanceData();
    // Calendar data will be loaded by _setPeriod method
  }

  Future<void> _loadAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('attendanceData');
    if (raw != null) {
      setState(() {
        attendanceData = Map<String, Map<String, dynamic>>.from(
          (json.decode(raw) as Map).map(
            (k, v) =>
                MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
          ),
        );
      });
    }
    _refreshKpi();
  }


  // Efficient method to load calendar data for a specific month
  Future<void> _loadCalendarDataForMonth(DateTime month) async {
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    
    // Check if data is already cached
    if (calendarDataCache.containsKey(monthKey)) {
      setState(() {
        attendanceRecords = calendarDataCache[monthKey]!;
        isCalendarLoading = false;
      });
      return;
    }

    // Set loading state
    setState(() {
      isCalendarLoading = true;
    });

    try {
      // Load data for the entire month using parallel API calls
      final records = await _attendanceService.getAttendanceRecordsForMonth(month);

      // Load itinerary data for the entire month to build store code/address maps
      await _loadItineraryDataForMonth(records);

      // Cache the data
      calendarDataCache[monthKey] = records;
      
      setState(() {
        attendanceRecords = records;
        isCalendarLoading = false;
      });
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() {
        isCalendarLoading = false;
      });
    }
  }

  // Load itinerary data for the entire month to build store code/address maps
  Future<void> _loadItineraryDataForMonth(List<AttendanceRecord> records) async {
    final Map<int, String> codeMap = {};
    final Map<int, String> addrMap = {};

    try {
      // Get all unique dates in the month that have attendance records
      final Set<DateTime> uniqueDates = {};
      for (final record in records) {
        uniqueDates.add(DateTime(record.date.year, record.date.month, record.date.day));
      }

      print('📅 Found attendance records for ${uniqueDates.length} dates: ${uniqueDates.map((d) => '${d.day}').join(', ')}');

      // If no attendance records, load today's itinerary as fallback
      if (uniqueDates.isEmpty) {
        uniqueDates.add(DateTime.now());
        print('⚠️ No attendance records found, loading today\'s itinerary as fallback');
      }

      // Fetch itinerary for each unique date in parallel for better performance
      final List<Future<void>> itineraryFutures = uniqueDates.map((date) async {
        final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        print('🔍 Loading itinerary for date: $dateStr');
        
        try {
          final itineraryResp = await ItineraryService.getItineraryByDate(dateStr);

          if (itineraryResp.success) {
            for (final itin in itineraryResp.data) {
              for (final store in itin.stores) {
                // Only add if not already present (prioritize first occurrence)
                if (!codeMap.containsKey(store.id)) {
                  codeMap[store.id] = store.code;
                  addrMap[store.id] = store.address ?? '';
                }
              }
            }
            print('✅ Loaded itinerary for $dateStr: ${itineraryResp.data.length} itineraries');
          } else {
            print('❌ Failed to load itinerary for $dateStr: ${itineraryResp.message}');
          }
        } catch (e) {
          print('❌ Error loading itinerary for $dateStr: $e');
        }
      }).toList();

      // Wait for all itinerary requests to complete
      await Future.wait(itineraryFutures);

      setState(() {
        storeCodeMap = codeMap;
        storeAddressMap = addrMap;
      });

      print('✅ Loaded itinerary data for ${uniqueDates.length} dates');
      print('✅ Built store maps with ${codeMap.length} store entries');
    } catch (e) {
      print('❌ Error loading itinerary data for month: $e');
      // Don't show error to user as this is not critical for attendance display
    }
  }

  void _setPeriod(DateTime date) {
    firstDayOfMonth = DateTime(date.year, date.month, 1);
    lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    totalHari = lastDayOfMonth.day;
    _refreshKpi();
    // Load calendar data for new month (only if not already cached)
    _loadCalendarDataForMonth(date);
    setState(() {});
  }

  void _refreshKpi() {
    // Hitung KPI berdasarkan attendanceData untuk bulan yang dipilih
    int masuk = 0;
    int _plan = 0;
    int _actual = 0;
    int _noOut = 0;
    int _lessThan5Min = 0;
    Set<String> storeSet = {};

    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      String key =
          "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
      final data = attendanceData[key];
      if (data != null && data['checkin'] != null) {
        masuk++;
        _actual++;
        if (data['store'] != null) storeSet.add(data['store']);
        if (data['noOut'] == true) _noOut++;
        if (data['duration'] != null && data['duration'] < 5) _lessThan5Min++;
      }
      // Plan: misal hari kerja (Senin-Jumat)
      DateTime d = DateTime(selectedDate.year, selectedDate.month, i);
      if (d.weekday >= 1 && d.weekday <= 5) _plan++;
    }
    setState(() {
      totalMasuk = masuk;
      plan = _plan;
      actual = _actual;
      uniqueStore = storeSet.length;
      noOut = _noOut;
      lessThan5Min = _lessThan5Min;
      ach = (plan == 0) ? double.nan : (actual / plan);
    });
  }

  void _onCalendarDayTap(DateTime day) async {
    setState(() {
      selectedDate = day;
    });

    // Data sudah ada di cache, tidak perlu API call lagi
    // Hanya update selectedDate untuk menampilkan detail yang sesuai
  }



  Widget _buildCuteLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: CuteLoadingWidget(
        message: 'Loading attendance data...',
        size: 80,
        primaryColor: const Color(0xFF29BDCE),
      ),
    );
  }

  Widget _buildCalendarDayLabel(String label, double daySize, double fontSize) {
    return SizedBox(
      width: daySize,
      height: 24,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }




  Widget _buildCalendar() {
    if (isCalendarLoading) {
      return Container(
        height: 300,
        child: _buildCuteLoadingIndicator(),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 400;
        final daySize = isLargeScreen ? 50.0 : 45.0;
        final fontSize = isLargeScreen ? 16.0 : 14.0;
        final smallFontSize = isLargeScreen ? 12.0 : 10.0;

        // Calendar for current month
        List<Widget> rows = [];
        DateTime firstDay = firstDayOfMonth;
        int weekdayOffset = firstDay.weekday % 7; // 0 for Sunday
        int daysInMonth = lastDayOfMonth.day;
        List<Widget> dayWidgets = [];

        // Add empty widgets for offset
        for (int i = 0; i < weekdayOffset; i++) {
          dayWidgets.add(SizedBox(width: daySize, height: daySize));
        }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime thisDay = DateTime(firstDay.year, firstDay.month, day);
      bool isToday =
          thisDay.day == DateTime.now().day &&
          thisDay.month == DateTime.now().month &&
          thisDay.year == DateTime.now().year;
      bool isSelected =
          thisDay.day == selectedDate.day &&
          thisDay.month == selectedDate.month &&
          thisDay.year == selectedDate.year;

      // Find attendance record for this day from API data
      Color dayColor = Colors.grey.shade200; // Default: no activity (grey)
      bool isPresent = false;
      int attendanceCount = 0;

      // Find all records for this specific day
      final dayRecords = attendanceRecords.where(
        (r) =>
            r.date.year == thisDay.year &&
            r.date.month == thisDay.month &&
            r.date.day == thisDay.day,
      ).toList();

      if (dayRecords.isNotEmpty) {
        // Sum up all details from all records for this day
        final allDetails = dayRecords.expand((r) => r.details).toList();
        attendanceCount = allDetails.length;
        
        // Determine color based on attendance status
        if (attendanceCount > 0) {
          // Check if all details are approved (is_approved = true)
          bool allApproved = allDetails.every((detail) => detail.isApproved);
          bool hasApproved = allDetails.any((detail) => detail.isApproved);
          bool hasPending = allDetails.any((detail) => !detail.isApproved);
          
          if (allApproved) {
            // Green: All present and approved
            dayColor = Colors.green.shade100;
            isPresent = true;
          } else if (hasApproved && hasPending) {
            // Orange: Mixed approved and pending
            dayColor = Colors.orange.shade200;
            isPresent = true;
          } else if (hasPending) {
            // Yellow: Present but pending approval (is_approved = false)
            dayColor = Colors.yellow.shade200;
            isPresent = true;
          }
        } else {
          // Red: Absent (no details but has record)
          dayColor = Colors.red.shade100;
        }
      } else {
        // Grey: No attendance recorded for this date
        dayColor = Colors.grey.shade200;
      }

      dayWidgets.add(
        GestureDetector(
          onTap: () => _onCalendarDayTap(thisDay),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.cyan
                  : isSelected
                  ? Colors.purple.shade100
                  : dayColor,
              shape: BoxShape.circle,
              border: isPresent
                  ? Border.all(color: Colors.green, width: 2)
                  : Border.all(color: Colors.grey[400]!, width: 1),
            ),
            width: daySize,
            height: daySize,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : isSelected
                            ? Colors.purple[800]
                            : isPresent
                            ? Colors.green[900]
                            : Colors.black87,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: fontSize,
                      ),
                    ),
                    // Show dots for attendance status like in the image
                    if (attendanceCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Main attendance dot
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dayColor == Colors.green.shade100 
                                    ? Colors.green[600]
                                    : dayColor == Colors.yellow.shade200
                                        ? Colors.orange[600]
                                        : dayColor == Colors.orange.shade200
                                            ? Colors.orange[700]
                                            : Colors.red[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Unique store dot (if more than 1 store)
                            if (dayRecords.isNotEmpty) ...[
                              Builder(
                                builder: (context) {
                                  final uniqueStores = dayRecords
                                      .expand((r) => r.details)
                                      .map((d) => d.storeId)
                                      .toSet()
                                      .length;
                                  if (uniqueStores > 1) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 2),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fill the last row with empty widgets if needed
    while (dayWidgets.length % 7 != 0) {
      dayWidgets.add(SizedBox(width: daySize, height: daySize));
    }

    // Build rows
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: dayWidgets.sublist(i, i + 7),
        ),
      );
    }

        return Column(
          children: [
            // Month Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month - 1,
                          1,
                        );
                        _setPeriod(selectedDate);
                      });
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        "${_monthName(selectedDate.month)} ${selectedDate.year}",
                        style: TextStyle(
                          fontSize: isLargeScreen ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        "${_getDayName(selectedDate.weekday)}",
                        style: TextStyle(
                          fontSize: isLargeScreen ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month + 1,
                          1,
                        );
                        _setPeriod(selectedDate);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCalendarDayLabel('S', daySize, smallFontSize),
            _buildCalendarDayLabel('M', daySize, smallFontSize),
            _buildCalendarDayLabel('T', daySize, smallFontSize),
            _buildCalendarDayLabel('W', daySize, smallFontSize),
            _buildCalendarDayLabel('T', daySize, smallFontSize),
            _buildCalendarDayLabel('F', daySize, smallFontSize),
            _buildCalendarDayLabel('S', daySize, smallFontSize),
          ],
        ),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Sunday',
      'Monday', 
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[weekday % 7];
  }

  @override
  Widget build(BuildContext context) {

    Widget _buildLegendItem({
      required Color color,
      Color? borderColor,
      required String label,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color.fromARGB(255, 41, 189, 206),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear cache and reload data
              calendarDataCache.clear();
              _loadCalendarDataForMonth(selectedDate);
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Period Statistics at the top
            _buildMonthlyStatisticsCard(),
            const SizedBox(height: 24),
            
            // 2. Calendar in the middle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildLegendItem(
                          color: Colors.green.shade100,
                          borderColor: Colors.green,
                          label: 'Present (Approved)',
                        ),
                        _buildLegendItem(
                          color: Colors.yellow.shade200,
                          borderColor: Colors.orange,
                          label: 'Present (Pending)',
                        ),
                        _buildLegendItem(
                          color: Colors.red.shade100,
                          borderColor: Colors.red,
                          label: 'Absent',
                        ),
                        _buildLegendItem(
                          color: Colors.grey.shade200,
                          borderColor: null,
                          label: 'No Data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Additional legend for dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Attendance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Multiple Stores',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 3. Working Hours, Progress, Duration and List at the bottom
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: _buildCuteLoadingIndicator(),
      );
    }

    // Get records for selected date
    final selectedDateRecords = attendanceRecords.where((record) {
      return record.date.day == selectedDate.day &&
             record.date.month == selectedDate.month && 
             record.date.year == selectedDate.year;
    }).toList();

    // Calculate working hours, progress, and duration for selected date
    final allDetails = selectedDateRecords.expand((r) => r.details).toList();
    
    // Progress calculation: is_approved = 1 for completed, 0 for in progress
    final completedDetails = allDetails.where((d) => d.isApproved == true).toList();
    
    final totalWorkingMinutes = allDetails
        .where((d) => d.checkOutTime != null)
        .map((d) => _calculateDetailDuration(d))
        .fold(0, (sum, duration) => sum + duration);

    final workingHours = totalWorkingMinutes / 60;
    final progress = completedDetails.length;
    final totalDetails = allDetails.length;
    final duration = totalWorkingMinutes;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with selected date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Map view button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceMapsScreen(
                      attendanceRecords: attendanceRecords,
                      selectedDate: selectedDate,
                      storeCodeMap: storeCodeMap,
                      storeAddressMap: storeAddressMap,
                    ),
                  ),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF29BDCE).withOpacity(0.1),
                      const Color(0xFF1E9BA8).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF29BDCE).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Map preview background
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[100],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF29BDCE).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.map,
                                size: 48,
                                color: Color(0xFF29BDCE),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'View on Map',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF29BDCE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to see all stores on map',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tap overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Working Hours, Progress, Duration summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Working Hour',
                        workingHours > 0 ? '${workingHours.toStringAsFixed(1)}h' : '-',
                        Icons.access_time,
                        Colors.blue,
                      ),
                      _buildSummaryItem(
                        'Progress',
                        '($progress/$totalDetails)',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        'Duration',
                        duration > 0 ? '${(duration / 60).floor()}h ${duration % 60}m' : '0m',
                        Icons.timer,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Attendance Details List for selected date
            if (selectedDateRecords.isNotEmpty)
              AttendanceListWidget(
                attendanceRecords: selectedDateRecords,
                selectedDate: selectedDate,
                storeCodeMap: storeCodeMap,
                storeAddressMap: storeAddressMap,
              )
            else
              Container(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No attendance data for this date',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }


  int _calculateDetailDuration(AttendanceDetail detail) {
    if (detail.checkOutTime == null) return 0;
    
    final checkInMinutes = detail.checkInTime.hour * 60 + detail.checkInTime.minute;
    final checkOutMinutes = detail.checkOutTime!.hour * 60 + detail.checkOutTime!.minute;
    
    return checkOutMinutes - checkInMinutes;
  }


  Widget _buildMonthlyStatisticsCard() {
    // Calculate monthly statistics
    final monthlyRecords = attendanceRecords.where((record) {
      return record.date.month == selectedDate.month && 
             record.date.year == selectedDate.year;
    }).toList();

    
    // Get all details from monthly records
    final allDetails = monthlyRecords.expand((r) => r.details).toList();
    
    // Progress calculation: is_approved = 1 for completed, 0 for in progress
    final completedDetails = allDetails.where((d) => d.isApproved == true).toList();
    
    // Plan = total stores to visit (all details), Actual = completed stores
    final plan = allDetails.length;
    final actual = completedDetails.length;
    
    // Unique stores = unique store IDs visited
    final uniqueStores = allDetails.map((d) => d.storeId).toSet().length;
    
    // No out count = details without checkout time
    final noOutCount = allDetails.where((d) => d.checkOutTime == null).length;
    
    // Less than 5 minutes count
    final lessThan5MinCount = allDetails.where((d) {
      if (d.checkOutTime == null) return false;
      final duration = _calculateDetailDuration(d);
      return duration < 5;
    }).length;

    // Working hours = total duration from all details
    final totalWorkingMinutes = allDetails
        .where((d) => d.checkOutTime != null)
        .map((d) => _calculateDetailDuration(d))
        .fold(0, (sum, duration) => sum + duration);
    
    final workingHours = totalWorkingMinutes / 60;
    
    // Achievement = percentage of completed vs planned
    final achievement = plan > 0 ? (actual / plan * 100).round() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
        
        // Responsive sizing
        final periodFontSize = isSmallScreen ? 11.0 : isMediumScreen ? 12.0 : 13.0;
        final progressSize = isSmallScreen ? 50.0 : isMediumScreen ? 55.0 : 65.0;
        final progressFontSize = isSmallScreen ? 10.0 : isMediumScreen ? 11.0 : 12.0;
        final progressStrokeWidth = isSmallScreen ? 4.0 : isMediumScreen ? 5.0 : 6.0;
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Header with improved styling
                  // Header and progress indicator sejajar & responsive
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF29BDCE), Color(0xFF1E9BA8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF29BDCE).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Periode: ${firstDayOfMonth.day.toString().padLeft(2, '0')} ${_monthName(firstDayOfMonth.month).substring(0, 3)} ${firstDayOfMonth.year} s/d ${lastDayOfMonth.day.toString().padLeft(2, '0')} ${_monthName(lastDayOfMonth.month).substring(0, 3)} ${lastDayOfMonth.year}',
                                  style: TextStyle(
                                    fontSize: periodFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: isSmallScreen ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 16),
                      // Progress indicator
                      Container(
                        width: progressSize,
                        height: progressSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              Colors.grey[50]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background circle
                            Center(
                              child: Container(
                                width: progressSize - 8,
                                height: progressSize - 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                ),
                              ),
                            ),
                            // Progress circle
                            Center(
                              child: SizedBox(
                                width: progressSize - 8,
                                height: progressSize - 8,
                                child: CircularProgressIndicator(
                                  value: achievement / 100,
                                  strokeWidth: progressStrokeWidth,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    achievement >= 80
                                        ? Colors.green[600]!
                                        : achievement >= 60
                                            ? Colors.orange[600]!
                                            : Colors.red[600]!,
                                  ),
                                ),
                              ),
                            ),
                            // Percentage text
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$achievement%',
                                    style: TextStyle(
                                      fontSize: progressFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: achievement >= 80
                                          ? Colors.green[700]
                                          : achievement >= 60
                                              ? Colors.orange[700]
                                              : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // KPI Row 1
                  Row(
                    children: [
                      Expanded(
                        child: _buildKPIItem(
                          'Progress',
                          '$actual/$plan',
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildKPIItem(
                          'Plan',
                          '$plan',
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildKPIItem(
                          'Actual',
                          '$actual',
                          Colors.orange,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildKPIItem(
                          'Ach',
                          '${achievement.toStringAsFixed(0)}%',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  
                  // KPI Row 2
                  Row(
                    children: [
                      Expanded(
                        child: _buildKPIItem(
                          'Unique Store',
                          '$uniqueStores',
                          Colors.teal,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildKPIItem(
                          'No Out',
                          '$noOutCount',
                          Colors.red,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildKPIItem(
                          '<5 Menit',
                          '$lessThan5MinCount',
                          Colors.amber,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildKPIItem(
                          'Working Hours',
                          '${workingHours.toStringAsFixed(1)}h',
                          Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPIItem(String title, String value, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        
        // Responsive sizing for KPI items
        final padding = isSmallScreen ? 6.0 : 8.0;
        final valueFontSize = isSmallScreen ? 10.0 : 12.0;
        final titleFontSize = isSmallScreen ? 8.0 : 9.0;
        final borderRadius = isSmallScreen ? 6.0 : 8.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

