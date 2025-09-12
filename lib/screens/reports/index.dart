import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _searchQuery = '';
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
        if (position != null && position.name != null && position.name!.isNotEmpty) {
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
            colors: [Color(0xFF29BDCE), Color(0xFF1E9BA8)],
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
            child: _userRole == 'MD CVS' 
                ? _buildMDCVSReports()
                : _userRole == 'SPG'
                    ? _buildSPGReports()
                    : _buildUnknownRoleReports(),
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
            _buildReportItem('Product Focus', Icons.center_focus_strong, const Color(0xFF29BDCE)),
            _buildReportItem('OOS', Icons.inventory_2, Colors.red),
            _buildReportItem('Expired Date', Icons.calendar_today, Colors.orange),
            _buildReportItem('Display', Icons.storefront, const Color(0xFF1E9BA8)),
            _buildReportItem('Price Principal', Icons.attach_money, Colors.blue),
            _buildReportItem('Price Competitor', Icons.compare, Colors.purple),
            _buildReportItem('Promo Tracking', Icons.local_offer, Colors.pink),
            _buildReportItem('Competitor Activity', Icons.trending_up, Colors.indigo),
            _buildReportItem('Survey', Icons.assignment, Colors.green),
            _buildReportItem('Product Belgian Berry', Icons.local_drink, Colors.brown),
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
          _buildSectionTitle('Daily'),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem('Sales', Icons.shopping_cart, const Color(0xFF29BDCE)),
            _buildReportItem('OOS', Icons.inventory_2, Colors.red),
            _buildReportItem('Expired Date', Icons.calendar_today, Colors.orange),
          ]),
          
          const SizedBox(height: 24),
          
          // Display Reports
          _buildSectionTitle('Display'),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem('Regular Display', Icons.storefront, const Color(0xFF1E9BA8)),
          ]),
          
          const SizedBox(height: 24),
          
          // Survey Reports
          _buildSectionTitle('Survey'),
          const SizedBox(height: 12),
          _buildReportGrid([
            _buildReportItem('Price Principal', Icons.attach_money, Colors.blue),
            _buildReportItem('Price Competitor', Icons.compare, Colors.purple),
            _buildReportItem('Promo Tracking', Icons.local_offer, Colors.pink),
            _buildReportItem('Competitor Activity', Icons.trending_up, Colors.indigo),
            _buildReportItem('Another Activity', Icons.more_horiz, Colors.grey),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Unknown Role',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No reports available for this role',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
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
