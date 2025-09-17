import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../services/attendance_service.dart';
import 'CompetitorActivity/index.dart';
import 'Display/index.dart';
import 'ExpiredDate/index.dart';
import 'OutOfStock/index.dart';
import 'PricePrincipal/index.dart';
import 'PriceCompetitor/index.dart';
import 'ProductBelgianBerry/index.dart';
import 'ProductFocus/index.dart';
import 'PromoTracking/index.dart';
import 'RegularDisplay/index.dart';
import 'Survey/index.dart';
import 'Sales/index.dart';
import 'ActivityOther/index.dart';
import '../Availability/index.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await AuthService.getUser();
      
      if (user != null && user.employee != null) {
        final position = user.employee!.position;
        if (position != null && position.name.isNotEmpty) {
          setState(() {
            _userRole = position.name;
            _isLoading = false;
          });
        } else {
          setState(() {
            _userRole = 'Unknown';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _userRole = 'Unknown';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        _userRole = 'Unknown';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF29BDCE), Color.fromARGB(255, 255, 255, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Main content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: _isLoading 
                      ? _buildLoadingContent()
                      : _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_userRole != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userRole!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29BDCE)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading reports...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and search
          Row(
            children: [
              const Text(
                'List Reports',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _userRole == 'MD CVS' 
                      ? const Color(0xFF29BDCE).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _userRole ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _userRole == 'MD CVS' 
                        ? const Color(0xFF29BDCE)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // // Search bar
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[100],
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.grey[300]!),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(Icons.search, color: Colors.grey[600], size: 20),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: TextField(
          //           onChanged: (value) => setState(() => _searchQuery = value),
          //           decoration: InputDecoration(
          //             hintText: 'Search reports...',
          //             hintStyle: TextStyle(color: Colors.grey[500]),
          //             border: InputBorder.none,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          
          // const SizedBox(height: 24),
          
          // Report categories
          Expanded(
            child: () {
              print('🔍 User role: "$_userRole"');
              if (_userRole == 'MD CVS') {
                print('📋 Building MD CVS Reports');
                return _buildMDCVSReports();
              } else if (_userRole == 'SPG') {
                print('📋 Building SPG Reports');
                return _buildSPGReports();
              } else {
                print('📋 Building Unknown Role Reports for: "$_userRole"');
                return _buildUnknownRoleReports();
              }
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildMDCVSReports() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All MD CVS Reports in one grid
          _buildReportGrid([
            _buildReportItem(translate('productFocus'), Icons.center_focus_strong, const Color(0xFF29BDCE)),
            _buildReportItem(translate('oos'), Icons.inventory_2, Colors.red),
            _buildReportItem(translate('expiredDate'), Icons.calendar_today, Colors.orange),
            _buildReportItem(translate('display'), Icons.storefront, const Color(0xFF1E9BA8)),
            _buildReportItem(translate('pricePrincipal'), Icons.attach_money, Colors.blue),
            _buildReportItem(translate('priceCompetitor'), Icons.compare, Colors.purple),
            _buildReportItem(translate('promoTracking'), Icons.local_offer, Colors.pink),
            _buildReportItem(translate('competitorActivity'), Icons.trending_up, Colors.indigo),
            _buildReportItem(translate('survey'), Icons.assignment, Colors.green),
            _buildReportItem(translate('productBelgianBerry'), Icons.local_drink, Colors.brown),
            _buildReportItem('Kegiatan Lain-lain', Icons.event_note, const Color(0xFF9C27B0)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSPGReports() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Reports
          _buildSectionTitle(translate('dailyReports')),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem(translate('sales'), Icons.shopping_cart, const Color(0xFF29BDCE)),
            _buildReportItem(translate('oos'), Icons.inventory_2, Colors.red),
            _buildReportItem(translate('expiredDate'), Icons.calendar_today, Colors.orange),
            _buildReportItem(translate('pricePrincipal'), Icons.attach_money, Colors.blue),
            _buildReportItem(translate('priceCompetitor'), Icons.compare, Colors.purple),
            _buildReportItem(translate('survey'), Icons.assignment, Colors.green),
          ]),
          
          const SizedBox(height: 24),
          
          // Display Reports
          _buildSectionTitle(translate('displayReports')),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem(translate('regularDisplay'), Icons.storefront, const Color(0xFF1E9BA8)),
          ]),
          
          const SizedBox(height: 24),
          
          // Survey Reports
          _buildSectionTitle(translate('surveyReports')),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem(translate('pricePrincipal'), Icons.attach_money, Colors.blue),
            _buildReportItem(translate('priceCompetitor'), Icons.compare, Colors.purple),
            _buildReportItem(translate('promoTracking'), Icons.local_offer, Colors.pink),
            _buildReportItem(translate('competitorActivity'), Icons.trending_up, Colors.indigo),
          ]),
          
          const SizedBox(height: 24),
          
          // Other Reports
          _buildSectionTitle('Laporan Lain-lain'),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem('Kegiatan Lain-lain', Icons.event_note, const Color(0xFF9C27B0)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildUnknownRoleReports() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Reports - Available for all roles
          _buildSectionTitle(translate('dailyReports')),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem(translate('sales'), Icons.shopping_cart, const Color(0xFF29BDCE)),
            _buildReportItem(translate('oos'), Icons.inventory_2, Colors.red),
            _buildReportItem(translate('expiredDate'), Icons.calendar_today, Colors.orange),
            _buildReportItem(translate('pricePrincipal'), Icons.attach_money, Colors.blue),
            _buildReportItem(translate('priceCompetitor'), Icons.compare, Colors.purple),
            _buildReportItem(translate('survey'), Icons.assignment, Colors.green),
          ]),
          
          const SizedBox(height: 24),
          
          // Display Reports
          _buildSectionTitle(translate('displayReports')),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem(translate('regularDisplay'), Icons.storefront, const Color(0xFF1E9BA8)),
          ]),
          
          const SizedBox(height: 24),
          
          // Survey Reports
          _buildSectionTitle(translate('surveyReports')),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem(translate('pricePrincipal'), Icons.attach_money, Colors.blue),
            _buildReportItem(translate('priceCompetitor'), Icons.compare, Colors.purple),
            _buildReportItem(translate('promoTracking'), Icons.local_offer, Colors.pink),
            _buildReportItem(translate('competitorActivity'), Icons.trending_up, Colors.indigo),
          ]),
          
          const SizedBox(height: 24),
          
          // Other Reports
          _buildSectionTitle('Laporan Lain-lain'),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem('Kegiatan Lain-lain', Icons.event_note, const Color(0xFF9C27B0)),
          ]),
        ],
      ),
    );
  }


  Widget _buildReportGrid(List<Widget> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildReportItem(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _onReportTap(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReportTap(String reportName) {
    print('🔍 Report tapped: "$reportName"');
    if (reportName == 'Competitor Activity' || reportName == 'Aktivitas Kompetitor') {
      _navigateToCompetitorActivity();
    } else if (reportName == 'Display') {
      _navigateToDisplayReport();
    } else if (reportName == 'Expired Date' || reportName == 'Tanggal Kedaluwarsa') {
      _navigateToExpiredDateReport();
    } else if (reportName == 'OOS' || reportName == 'Stok Habis') {
      _navigateToOutOfStockReport();
    } else if (reportName == 'Price Principal' || reportName == 'Price Competitor' || 
               reportName == 'Harga Principal' || reportName == 'Harga Kompetitor') {
      _navigateToPriceReport(reportName);
    } else if (reportName == 'Product Belgian Berry' || reportName == 'Produk Belgian Berry') {
      _navigateToProductBelgianBerryReport();
    } else if (reportName == 'Product Focus' || reportName == 'Fokus Produk') {
      _navigateToProductFocusReport();
    } else if (reportName == 'Promo Tracking' || reportName == 'Pelacakan Promo') {
      _navigateToPromoTrackingReport();
    } else if (reportName == 'Regular Display' || reportName == 'Display Reguler') {
      _navigateToRegularDisplayReport();
    } else if (reportName == 'Survey') {
      _navigateToSurveyReport();
    } else if (reportName == 'Sales' || reportName == 'Penjualan') {
      print('🎯 Navigating to Sales Report...');
      print('🎯 Sales Report button clicked successfully!');
      _navigateToSalesReport();
    } else if (reportName == 'Kegiatan Lain-lain') {
      _navigateToActivityOtherReport();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $reportName report...'),
          backgroundColor: const Color(0xFF29BDCE),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToCompetitorActivity() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CompetitorActivityScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating competitor activity report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToDisplayReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating display report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToExpiredDateReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExpiredDateReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating expired date report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToOutOfStockReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => OutOfStockReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
        // Return success to dashboard if report was submitted
        if (result == true) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating out of stock report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToPriceReport(String reportName) async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        print('🎯 Navigating to Price Report: $reportName');
        print('🏪 Store ID: ${todayRecord.storeId}, Store Name: ${todayRecord.storeName}');
        
        if (reportName == 'Price Principal' || reportName == 'Harga Principal') {
          print('✅ Opening Price Principal Report...');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PricePrincipalReportScreen(
                storeId: todayRecord.storeId!,
                storeName: todayRecord.storeName!,
              ),
            ),
          );
        } else if (reportName == 'Price Competitor' || reportName == 'Harga Kompetitor') {
          print('✅ Opening Price Competitor Report...');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PriceCompetitorReportScreen(
                storeId: todayRecord.storeId!,
                storeName: todayRecord.storeName!,
              ),
            ),
          );
        } else {
          print('❌ Unknown price report name: $reportName');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating price report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToProductBelgianBerryReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductBelgianBerryReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating Product Belgian Berry report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToProductFocusReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductFocusReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating Product Focus report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToPromoTrackingReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PromoTrackingReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating Promo Tracking report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToRegularDisplayReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegularDisplayReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating Regular Display report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToSurveyReport() async {
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SurveyReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in to a store first before creating Survey report'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToSalesReport() async {
    print('🚀 _navigateToSalesReport called');
    try {
      // Get current store information from attendance service
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();
      
      print('📋 Today record: ${todayRecord != null ? "exists" : "null"}');
      if (todayRecord != null) {
        print('🏪 Store ID: ${todayRecord.storeId}');
        print('🏪 Store Name: ${todayRecord.storeName}');
      }

      if (todayRecord != null && todayRecord.storeId != null && todayRecord.storeName != null) {
        print('✅ All conditions met, navigating to SalesReportScreen...');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SalesReportScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        print('❌ Conditions not met, showing error message');
        print('   - todayRecord: ${todayRecord != null ? "exists" : "null"}');
        if (todayRecord != null) {
          print('   - storeId: ${todayRecord.storeId}');
          print('   - storeName: ${todayRecord.storeName}');
        }
      
        // For testing, let's allow opening Sales Report even without attendance
        print('🧪 Testing mode: Opening Sales Report with default values...');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SalesReportScreen(
              storeId: 4, // Default store ID for testing
              storeName: 'JENDERAL SUDIRMAN 12', // Default store name for testing
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToActivityOtherReport() async {
    try {
      print('🚀 _navigateToActivityOtherReport called');
      
      // Get today's attendance record
      final attendanceService = AttendanceService();
      final todayRecord = await attendanceService.getTodayRecord();
      
      print('📋 Today record: ${todayRecord != null ? "exists" : "null"}');
      
      if (todayRecord != null && 
          todayRecord.storeId != null && 
          todayRecord.storeName != null &&
          todayRecord.storeId! > 0 &&
          todayRecord.storeName!.isNotEmpty) {
        
        print('🏪 Store ID: ${todayRecord.storeId}');
        print('🏪 Store Name: ${todayRecord.storeName}');
        print('✅ All conditions met, navigating to ActivityOtherScreen...');
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActivityOtherScreen(
              storeId: todayRecord.storeId!,
              storeName: todayRecord.storeName!,
            ),
          ),
        );
      } else {
        print('❌ Conditions not met for Activity Other Report');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Silakan check-in terlebih dahulu untuk mengakses laporan'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _navigateToActivityOtherReport: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

}
