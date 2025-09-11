import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/services/itinerary_service.dart';
import 'package:stockira/models/attendance_record.dart';
import 'package:stockira/widgets/attendance_list_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _setPeriod(selectedDate);
    _loadAttendanceData();
    _loadAttendanceRecords();
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

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final records = await _attendanceService.getRecordsByDateRange(
        firstDayOfMonth,
        lastDayOfMonth,
      );
      final stats = await _attendanceService.getStatistics(
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      );

      // Load itinerary data for the entire month to build store code/address maps
      await _loadItineraryDataForMonth(records);

      setState(() {
        attendanceRecords = records;
        statistics = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance data: $e')),
      );
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

      // If no attendance records, load today's itinerary as fallback
      if (uniqueDates.isEmpty) {
        uniqueDates.add(DateTime.now());
      }

      // Fetch itinerary for each unique date
      for (final date in uniqueDates) {
        final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final itineraryResp = await ItineraryService.getItineraryByDate(dateStr);

        if (itineraryResp.success) {
          for (final itin in itineraryResp.data) {
            for (final store in itin.stores) {
              // Only add if not already present (prioritize first occurrence)
              if (!codeMap.containsKey(store.id)) {
                codeMap[store.id] = store.code ?? '';
                addrMap[store.id] = store.address ?? '';
              }
            }
          }
        }
      }

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
    _loadAttendanceRecords(); // Reload records for new period
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
      isLoading = true;
    });

    try {
      // Fetch attendance data for the selected day
      final records = await _attendanceService.getAttendanceRecordsForDate(day);

      // Fetch itinerary for store code/address mapping
      final dateStr = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final itineraryResp = await ItineraryService.getItineraryByDate(dateStr);

      final Map<int, String> codeMap = {};
      final Map<int, String> addrMap = {};
      if (itineraryResp.success) {
        for (final itin in itineraryResp.data) {
          for (final store in itin.stores) {
            codeMap[store.id] = store.code ?? '';
            addrMap[store.id] = store.address ?? '';
          }
        }
      }

      setState(() {
        attendanceRecords = records;
        storeCodeMap = codeMap;
        storeAddressMap = addrMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance details: $e')),
      );
    }
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 400;
        final daySize = isLargeScreen ? 44.0 : 40.0;
        final fontSize = isLargeScreen ? 14.0 : 12.0;
        final smallFontSize = isLargeScreen ? 10.0 : 8.0;

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

      final record = attendanceRecords.firstWhere(
        (r) =>
            r.date.year == thisDay.year &&
            r.date.month == thisDay.month &&
            r.date.day == thisDay.day,
        orElse: () => AttendanceRecord(id: 0, date: thisDay),
      );

      if (record.id != 0) {
        // Green: Has total masuk (attendance records)
        dayColor = Colors.green.shade100;
        isPresent = true;
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
                  ? Colors.red.shade100
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
                            ? Colors.red
                            : isPresent
                            ? Colors.green[900]
                            : Colors.black87,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: fontSize,
                      ),
                    ),
                    // Show store count for present days with better responsive design
                    if (isPresent && record.details.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 3 : 2,
                          vertical: isLargeScreen ? 2 : 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${record.details.length}',
                          style: TextStyle(
                            color: Colors.green[900],
                            fontSize: smallFontSize,
                            fontWeight: FontWeight.bold,
                          ),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
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
              Text(
                "${_monthName(selectedDate.month)} ${selectedDate.year}",
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
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
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAttendanceRecords(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar
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
                          color: Colors.yellow.shade200,
                          borderColor: Colors.yellow,
                          label: 'Pending/Approved',
                        ),
                        _buildLegendItem(
                          color: Colors.green.shade100,
                          borderColor: Colors.green,
                          label: 'Present',
                        ),
                        _buildLegendItem(
                          color: Colors.grey.shade200,
                          borderColor: null,
                          label: 'No Activity',
                        ),
                        _buildLegendItem(
                          color: Colors.red.shade100,
                          borderColor: Colors.red,
                          label: 'Absent',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Results and Statistics Section
            _buildResultsSection(),
            const SizedBox(height: 24),
            // Info
            Center(
              child: Text(
                'Periode: ${firstDayOfMonth.day}/${firstDayOfMonth.month}/${firstDayOfMonth.year} - ${lastDayOfMonth.day}/${lastDayOfMonth.month}/${lastDayOfMonth.year}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  _formatDate(selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistics for selected date/period
            _buildSelectedDateStatistics(),
            
            const SizedBox(height: 16),

            // Attendance Details for selected date
            AttendanceListWidget(
              attendanceRecords: attendanceRecords,
              selectedDate: selectedDate,
              storeCodeMap: storeCodeMap,
              storeAddressMap: storeAddressMap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateStatistics() {
    // Calculate statistics for selected date or current period
    final recordsForPeriod = attendanceRecords.where((record) {
      if (selectedDate.day == DateTime.now().day && 
          selectedDate.month == DateTime.now().month && 
          selectedDate.year == DateTime.now().year) {
        // If today is selected, show monthly statistics
        return record.date.month == selectedDate.month && 
               record.date.year == selectedDate.year;
      } else {
        // If specific date selected, show that date only
        return record.date.day == selectedDate.day &&
               record.date.month == selectedDate.month && 
               record.date.year == selectedDate.year;
      }
    }).toList();

    final totalMasuk = recordsForPeriod.length;
    final uniqueStores = recordsForPeriod
        .expand((r) => r.details)
        .map((d) => d.storeId)
        .toSet()
        .length;
    
    final noOutCount = recordsForPeriod
        .expand((r) => r.details)
        .where((d) => d.checkOutTime == null)
        .length;
    
    final lessThan5MinCount = recordsForPeriod
        .expand((r) => r.details)
        .where((d) {
          if (d.checkOutTime == null) return false;
          final duration = _calculateDetailDuration(d);
          return duration < 5;
        })
        .length;

    final totalWorkingMinutes = recordsForPeriod
        .expand((r) => r.details)
        .where((d) => d.checkOutTime != null)
        .map((d) => _calculateDetailDuration(d))
        .fold(0, (sum, duration) => sum + duration);

    final averageDaily = recordsForPeriod.isNotEmpty 
        ? totalWorkingMinutes ~/ recordsForPeriod.length 
        : 0;

    final completionRate = recordsForPeriod.isNotEmpty
        ? (recordsForPeriod.where((r) => r.details.any((d) => d.checkOutTime != null)).length / recordsForPeriod.length * 100).round()
        : 0;

    return Column(
      children: [
        // First row statistics
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Masuk',
                '$totalMasuk',
                Icons.login,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Unique Store',
                '$uniqueStores',
                Icons.store,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'No Out',
                '$noOutCount',
                Icons.logout,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Second row statistics
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '<5 Menit',
                '$lessThan5MinCount',
                Icons.timer,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Working Hours',
                '${(totalWorkingMinutes / 60).toStringAsFixed(1)}h',
                Icons.access_time,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Avg Daily',
                '${(averageDaily / 60).toStringAsFixed(1)}h',
                Icons.trending_up,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Progress bar for completion rate
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completion Rate: $completionRate%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: completionRate / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completionRate >= 80 ? Colors.green : 
                      completionRate >= 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
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
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

