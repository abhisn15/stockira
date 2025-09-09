import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/models/attendance_record.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  late DateTime firstDayOfMonth;
  late DateTime lastDayOfMonth;

  // Attendance service
  final AttendanceService _attendanceService = AttendanceService();
  
  // Data absensi per hari, key: yyyy-MM-dd, value: Map (checkin, checkout, dll)
  Map<String, Map<String, dynamic>> attendanceData = {};
  List<AttendanceRecord> attendanceRecords = [];

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
          (json.decode(raw) as Map).map((k, v) => MapEntry(
            k as String,
            Map<String, dynamic>.from(v as Map),
          )),
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

  Future<void> _saveAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendanceData', json.encode(attendanceData));
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
      String key = "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
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
      _setPeriod(day);
    });
    // Tampilkan dialog checkin/checkout
    String key = "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    Map<String, dynamic> data = attendanceData[key] ?? {};

    await showDialog(
      context: context,
      builder: (ctx) {
        bool isCheckedIn = data['checkin'] != null;
        bool isCheckedOut = data['checkout'] != null;
        return AlertDialog(
          title: Text("Absensi ${day.day}/${day.month}/${day.year}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCheckedIn)
                ListTile(
                  leading: const Icon(Icons.login, color: Colors.green),
                  title: const Text("Sudah Check In"),
                  subtitle: Text(data['checkin'] ?? ''),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Check In"),
                  onPressed: () async {
                    String now = TimeOfDay.now().format(context);
                    attendanceData[key] = {
                      ...data,
                      'checkin': now,
                      'store': 'Store${Random().nextInt(5) + 1}', // Simulasi store
                      'noOut': false,
                      'duration': Random().nextInt(10) + 1, // Simulasi durasi
                    };
                    await _saveAttendanceData();
                    Navigator.of(ctx).pop();
                    _refreshKpi();
                  },
                ),
              const SizedBox(height: 8),
              if (isCheckedIn && !isCheckedOut)
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Check Out"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    String now = TimeOfDay.now().format(context);
                    attendanceData[key] = {
                      ...data,
                      'checkout': now,
                    };
                    await _saveAttendanceData();
                    Navigator.of(ctx).pop();
                    _refreshKpi();
                  },
                ),
              if (isCheckedOut)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Sudah Check Out"),
                  subtitle: Text(data['checkout'] ?? ''),
                ),
            ],
          ),
        );
      },
    );
    _refreshKpi();
  }

  Widget _buildCircleProgress({
    required double percent,
    required Color color,
    required String label,
    required String value,
  }) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent.isNaN ? 0 : percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({required String label, required String value, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    // Calendar for current month
    List<Widget> rows = [];
    DateTime firstDay = firstDayOfMonth;
    int weekdayOffset = firstDay.weekday % 7; // 0 for Sunday
    int daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];
    // Add empty widgets for offset
    for (int i = 0; i < weekdayOffset; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime thisDay = DateTime(firstDay.year, firstDay.month, day);
      bool isToday = thisDay.day == DateTime.now().day &&
          thisDay.month == DateTime.now().month &&
          thisDay.year == DateTime.now().year;
      bool isSelected = thisDay.day == selectedDate.day &&
          thisDay.month == selectedDate.month &&
          thisDay.year == selectedDate.year;

      String key = "${thisDay.year.toString().padLeft(4, '0')}-${thisDay.month.toString().padLeft(2, '0')}-${thisDay.day.toString().padLeft(2, '0')}";
      final data = attendanceData[key];
      bool isCheckedIn = data != null && data['checkin'] != null;
      bool isCheckedOut = data != null && data['checkout'] != null;

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
                      : isCheckedIn
                          ? Colors.green.shade100
                          : Colors.transparent,
              shape: BoxShape.circle,
              border: isCheckedIn
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isToday
                        ? Colors.white
                        : isSelected
                            ? Colors.red
                            : isCheckedIn
                                ? Colors.green[900]
                                : Colors.black87,
                    fontWeight: isToday || isSelected || isCheckedIn
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isCheckedOut)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(Icons.check_circle, color: Colors.blue, size: 14),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Fill the last row with empty widgets if needed
    while (dayWidgets.length % 7 != 0) {
      dayWidgets.add(const SizedBox());
    }

    // Build rows
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dayWidgets.sublist(i, i + 7),
      ));
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
                    selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
                    _setPeriod(selectedDate);
                  });
                },
              ),
              Text(
                "${_monthName(selectedDate.month)} ${selectedDate.year}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
                    _setPeriod(selectedDate);
                  });
                },
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _CalendarDayLabel('S'),
            _CalendarDayLabel('M'),
            _CalendarDayLabel('T'),
            _CalendarDayLabel('W'),
            _CalendarDayLabel('T'),
            _CalendarDayLabel('F'),
            _CalendarDayLabel('S'),
          ],
        ),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    double achPercent = (plan == 0) ? double.nan : (actual / plan).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleProgress(
                  percent: totalHari == 0 ? 0 : totalMasuk / totalHari,
                  color: Colors.red,
                  label: 'Total Masuk',
                  value: '$totalMasuk/$totalHari',
                ),
                _buildCircleProgress(
                  percent: plan == 0 ? 0 : (actual / plan).clamp(0.0, 1.0),
                  color: Colors.orange,
                  label: 'Plan',
                  value: '$plan',
                ),
                _buildCircleProgress(
                  percent: plan == 0 ? 0 : (actual / plan).clamp(0.0, 1.0),
                  color: Colors.green,
                  label: 'Actual',
                  value: '$actual',
                ),
                _buildCircleProgress(
                  percent: achPercent.isNaN ? 0 : achPercent,
                  color: Colors.blue,
                  label: 'Ach',
                  value: plan == 0 ? 'NaN%' : '${((actual / plan) * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 18),
            // KPI details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildKpiCard(label: 'Unique Store', value: '$uniqueStore'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(label: 'No Out', value: '$noOut'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(label: '<5 Menit', value: '$lessThan5Min'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Calendar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'KPI Kalender',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCalendar(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Hari ini',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Sudah Check In',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.check_circle, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Sudah Check Out',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
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
            const Text(
              'Results & Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // Working Hours Summary
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Working Hours',
                    '${statistics['totalWorkingMinutes'] ?? 0} min',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Average Daily',
                    '${statistics['averageWorkingMinutes'] ?? 0} min',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Completion Rate
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completion Rate',
                    '${statistics['completionRate'] ?? 0}%',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed Days',
                    '${statistics['completedDays'] ?? 0}/${statistics['totalDays'] ?? 0}',
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            const Text(
              'Monthly Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: statistics['totalDays'] != null && statistics['totalDays'] > 0
                  ? (statistics['completedDays'] ?? 0) / statistics['totalDays']
                  : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              '${statistics['completedDays'] ?? 0} of ${statistics['totalDays'] ?? 0} days completed',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Records
            if (attendanceRecords.isNotEmpty) ...[
              const Text(
                'Recent Records',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...attendanceRecords.take(5).map((record) => _buildRecordItem(record)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: record.isCompleted ? Colors.green : 
                     record.isCheckedIn ? Colors.orange : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.day}/${record.date.month}/${record.date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (record.store != null)
                  Text(
                    'Store: ${record.store}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                if (record.isCompleted)
                  Text(
                    'Working: ${record.workingHoursFormatted}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
          if (record.checkInTime != null)
            Text(
              record.checkInTime!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarDayLabel extends StatelessWidget {
  final String label;
  const _CalendarDayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 24,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
