import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/store.dart';
import '../../services/nearest_stores_service.dart';
import '../../widgets/store_item_widget.dart';
import '../../widgets/stores_map_widget.dart';
import 'create_location_form.dart';

class CreateLocationScreen extends StatefulWidget {
  const CreateLocationScreen({super.key});

  @override
  State<CreateLocationScreen> createState() => _CreateLocationScreenState();
}

class _CreateLocationScreenState extends State<CreateLocationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Location data
  double? _currentLatitude;
  double? _currentLongitude;
  
  // Stores data
  List<Store> _approvedStores = [];
  bool _isLoadingStores = false;
  String? _errorMessage;
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Store> _filteredStores = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission permanently denied';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });

      // Load stores after getting location
      await _loadStores();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
    }
  }

  Future<void> _loadStores() async {
    if (_currentLatitude == null || _currentLongitude == null) return;

    setState(() {
      _isLoadingStores = true;
      _errorMessage = null;
    });

    try {
      // Load approved stores only
      final approvedResponse = await NearestStoresService.getApprovedStores(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        radius: 5.0,
        limit: 50,
      );

      setState(() {
        _approvedStores = approvedResponse.data;
        _filteredStores = _approvedStores;
        _isLoadingStores = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading stores: $e';
        _isLoadingStores = false;
      });
    }
  }


  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredStores = _approvedStores;
      } else {
        _filteredStores = _approvedStores.where((store) {
          return store.name.toLowerCase().contains(query.toLowerCase()) ||
                 store.code.toLowerCase().contains(query.toLowerCase()) ||
                 store.account.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _onStoreTap(Store store) {
    // Switch to map tab and show store details
    _tabController.animateTo(1);
  }

  void _onCreateLocation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateLocationFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Store Locations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Peta'),
          ],
        ),
      ),
      body: _currentLatitude == null && _currentLongitude == null
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApprovedStoresTab(),
                    _buildMapTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateLocation,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Buat Lokasi'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Mendeteksi lokasi...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildApprovedStoresTab() {
    return Column(
      children: [
        // Search section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari store approved...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        
        // Stores list
        Expanded(
          child: _isLoadingStores
              ? const Center(child: CircularProgressIndicator())
              : StoreListWidget(
                  stores: _filteredStores,
                  onStoreTap: _onStoreTap,
                  showDistance: true,
                  showStatus: true,
                  emptyMessage: _isSearching
                      ? 'Tidak ada store yang cocok dengan pencarian'
                      : 'Tidak ada store yang sudah approved',
                ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return Column(
      children: [
        // Map
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: _isLoadingStores
                ? const Center(child: CircularProgressIndicator())
                : StoresMapWidget(
                    stores: _approvedStores,
                    userLatitude: _currentLatitude,
                    userLongitude: _currentLongitude,
                    onStoreTap: _onStoreTap,
                    initialZoom: 15.0,
                    showUserLocation: true,
                  ),
          ),
        ),
        // Store count info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_approvedStores.length} store approved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Radius: 5.0 km',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
