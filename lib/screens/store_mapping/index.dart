import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import '../../models/store_mapping.dart';
import '../../services/store_mapping_service.dart';

class StoreMappingScreen extends StatefulWidget {
  const StoreMappingScreen({super.key});

  @override
  State<StoreMappingScreen> createState() => _StoreMappingScreenState();
}

class _StoreMappingScreenState extends State<StoreMappingScreen>
    with TickerProviderStateMixin {
  final StoreMappingService _storeMappingService = StoreMappingService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Area> _areas = [];
  List<Store> _stores = [];
  List<Store> _allStores = []; // All stores for filtering
  List<Store> _visitedStores = [];
  List<Store> _filteredStores = []; // Filtered stores for display
  
  Area? _selectedArea;
  String _searchQuery = '';
  
  bool _isLoadingAreas = false;
  bool _isLoadingStores = false;
  bool _isLoadingVisitedStores = false;
  bool _isInitialLoading = true; // For initial loading check
  
  Position? _currentPosition;
  File? _selectedImage;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      if (_currentTabIndex == 1) {
        _loadVisitedStores();
      }
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isInitialLoading = true;
    });
    
    await Future.wait([
      _loadAreas(),
      _getCurrentLocation(),
    ]);
    
    // Load all stores by default
    await _loadAllStores();
    
    setState(() {
      _isInitialLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoadingAreas = true;
    });
    try {
      // For demo purposes, load sample data
      await Future.delayed(const Duration(seconds: 1));
      
      final sampleAreas = [
        Area(id: 1, name: 'Makassar', description: 'SULAWESI SELATAN'),
        Area(id: 2, name: 'Pekanbaru', description: 'RIAU'),
        Area(id: 3, name: 'Kendari', description: 'Sulawesi Tenggara'),
        Area(id: 4, name: 'Palembang', description: 'SUMATERA SELATAN'),
        Area(id: 5, name: 'Manado', description: 'Sulawesi Utara'),
        Area(id: 6, name: 'Ambon', description: 'Maluku'),
        Area(id: 7, name: 'Samarinda', description: 'Kalimantan Timur'),
        Area(id: 8, name: 'Malang', description: 'JAWA TIMUR'),
        Area(id: 9, name: 'Lampung', description: 'LAMPUNG'),
        Area(id: 10, name: 'Solo', description: 'JAWA TENGAH'),
        Area(id: 11, name: 'Bandung', description: 'JAWA BARAT'),
        Area(id: 12, name: 'Karawang', description: 'JAWA BARAT'),
      ];
      
      setState(() {
        _areas = sampleAreas;
        _isLoadingAreas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAreas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading areas: $e')),
        );
      }
    }
  }

  Future<void> _loadVisitedStores() async {
    setState(() {
      _isLoadingVisitedStores = true;
    });
    try {
      // Simulate loading visited stores - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Show some visited stores based on the first few stores from each area
      final visitedStores = <Store>[];
      final areaGroups = <int, List<Store>>{};
      
      // Group stores by area
      for (final store in _allStores) {
        if (store.areaId != null) {
          areaGroups.putIfAbsent(store.areaId!, () => []).add(store);
        }
      }
      
      // Take first store from each area as visited
      for (final stores in areaGroups.values) {
        if (stores.isNotEmpty) {
          visitedStores.add(stores.first);
        }
      }
      
      setState(() {
        _visitedStores = visitedStores;
        _isLoadingVisitedStores = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVisitedStores = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading visited stores: $e')),
        );
      }
    }
  }

  Future<void> _loadAllStores() async {
    setState(() {
      _isLoadingStores = true;
    });

    try {
      // For demo purposes, load sample data for all areas
      await Future.delayed(const Duration(seconds: 1));
      
      final allSampleStores = <Store>[];
      
      // Generate stores for each area
      for (int i = 0; i < _areas.length; i++) {
        final area = _areas[i];
        final areaStores = [
          Store(
            id: 30929 + (i * 10),
            name: '${area.name} Store ${i + 1}',
            address: 'Jl. Raya ${area.name} No.${i + 1}, ${area.description}',
            latitude: -6.2615 + (i * 0.001),
            longitude: 106.8106 + (i * 0.001),
            areaId: area.id,
            areaName: area.name,
          ),
          Store(
            id: 57078 + (i * 10),
            name: '${area.name} Mini Market ${i + 1}',
            address: 'Blok ${String.fromCharCode(65 + i)} No.${i + 1}, ${area.description}',
            latitude: -6.2600 + (i * 0.001),
            longitude: 106.8110 + (i * 0.001),
            areaId: area.id,
            areaName: area.name,
          ),
          Store(
            id: 57079 + (i * 10),
            name: '${area.name} Supermarket ${i + 1}',
            address: 'Kompleks ${area.name} Blok ${String.fromCharCode(65 + i)} No.${i + 1}',
            latitude: -6.2620 + (i * 0.001),
            longitude: 106.8100 + (i * 0.001),
            areaId: area.id,
            areaName: area.name,
          ),
        ];
        allSampleStores.addAll(areaStores);
      }
      
      setState(() {
        _allStores = allSampleStores;
        _stores = allSampleStores;
        _filteredStores = allSampleStores;
        _isLoadingStores = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStores = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stores: $e')),
        );
      }
    }
  }

  Future<void> _loadStoresForArea(int areaId) async {
    setState(() {
      _isLoadingStores = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Filter stores by area
      final filteredStores = _allStores.where((store) => store.areaId == areaId).toList();
      
      setState(() {
        _stores = filteredStores;
        _filteredStores = filteredStores;
        _isLoadingStores = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStores = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stores: $e')),
        );
      }
    }
  }

  void _filterStores() {
    List<Store> filtered = _stores;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((store) => 
        store.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        store.address.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by selected area
    if (_selectedArea != null) {
      filtered = filtered.where((store) => store.areaId == _selectedArea!.id).toList();
    }
    
    setState(() {
      _filteredStores = filtered;
    });
  }


  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Store Mapping',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Store Data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Store Mapping',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F), // Red color like in mockup
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  text: 'STORE COVERAGE(${_filteredStores.length})',
                ),
                Tab(
                  text: 'LAST VISIT(${_visitedStores.length})',
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoreCoverageTab(),
                _buildLastVisitTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAreaSelectionDialog();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStoreCoverageTab() {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah Toko : ${_filteredStores.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_filteredStores.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Reset filter to show all stores
                    setState(() {
                      _selectedArea = null;
                      _searchQuery = '';
                      _searchController.clear();
                      _filteredStores = _allStores;
                      _stores = _allStores;
                    });
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Store List
        Expanded(
          child: _isLoadingStores
              ? const Center(child: CircularProgressIndicator())
              : _filteredStores.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Tidak ada toko yang tersedia',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStores.length,
                      itemBuilder: (context, index) {
                        final store = _filteredStores[index];
                        return _buildStoreCard(store, index + 1);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLastVisitTab() {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Text(
            'Jumlah Toko : ${_visitedStores.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Visited Store List
        Expanded(
          child: _isLoadingVisitedStores
              ? const Center(child: CircularProgressIndicator())
              : _visitedStores.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada toko yang dikunjungi',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _visitedStores.length,
                      itemBuilder: (context, index) {
                        final store = _visitedStores[index];
                        return _buildStoreCard(store, index + 1, isVisited: true);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(Store store, int index, {bool isVisited = false}) {
    return GestureDetector(
      onTap: () {
        _showLocationUpdateDialog(store);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Store Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Name
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Store ID and Type
                        Text(
                          '${store.id} - ${store.areaName ?? 'Unknown'} - ${store.name.split(' ').first.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                store.address,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Distance
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Jarak : ${_calculateDistance(store)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Document Icon
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                  
                  // Tap to update indicator
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Update',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
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
            
            // Visited Tag
            if (isVisited)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'VISITED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _calculateDistance(Store store) {
    if (_currentPosition == null || store.latitude == null || store.longitude == null) {
      return '0,00 KM';
    }
    
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      store.latitude!,
      store.longitude!,
    );
    
    return '${(distance / 1000).toStringAsFixed(2).replaceAll('.', ',')} KM';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari & Filter Toko'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama toko...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter Area',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Area>(
              initialValue: _selectedArea,
              decoration: const InputDecoration(
                labelText: 'Pilih Area',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Area>(
                  value: null,
                  child: Text('Semua Area'),
                ),
                ..._areas.map((area) {
                  return DropdownMenuItem<Area>(
                    value: area,
                    child: Text(area.name),
                  );
                }),
              ],
              onChanged: (Area? area) {
                setState(() {
                  _selectedArea = area;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedArea = null;
                _searchQuery = '';
                _searchController.clear();
                _filteredStores = _allStores;
                _stores = _allStores;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterStores();
              Navigator.of(context).pop();
            },
            child: const Text('Filter'),
          ),
        ],
      ),
    );
  }

  void _showAreaSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pilih Area',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari area...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Area List
            Expanded(
              child: _isLoadingAreas
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _areas.length,
                      itemBuilder: (context, index) {
                        final area = _areas[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            area.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          subtitle: Text(
                            area.description ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _selectedArea = area;
                            });
                            _loadStoresForArea(area.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationUpdateDialog(Store store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Lokasi Toko',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          store.name,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Google Maps Section
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _currentPosition != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 15.0,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          // Map controller created
                        },
                        markers: {
                          Marker(
                            markerId: MarkerId('current_location'),
                            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                            infoWindow: const InfoWindow(
                              title: 'Lokasi Anda',
                            ),
                          ),
                          if (store.latitude != null && store.longitude != null)
                            Marker(
                              markerId: MarkerId('store_location'),
                              position: LatLng(store.latitude!, store.longitude!),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              infoWindow: InfoWindow(
                                title: store.name,
                                snippet: store.address,
                              ),
                            ),
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Lokasi tidak tersedia',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '⚠️ Pastikan Anda berada di lokasi toko saat update!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Lokasi:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentPosition != null
                              ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}'
                              : 'Lokasi tidak tersedia',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _currentPosition != null
                              ? 'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                              : '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jarak ke toko: ${_calculateDistance(store)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Photo Section
                  const Text(
                    'Foto Lokasi (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(),
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tambahkan Foto',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reason Field
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Alasan Update *',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan alasan update lokasi...',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _reasonController.clear();
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _updateStoreLocationWithDialog(store),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Update Lokasi'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _updateStoreLocationWithDialog(Store store) async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon untuk mengisi alasan terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak tersedia. Pastikan GPS aktif.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Start updating process

    try {
      final locationUpdate = StoreLocationUpdate(
        storeId: store.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        notes: _reasonController.text.trim(),
      );

      final success = await _storeMappingService.updateStoreLocation(locationUpdate);
      
      if (success && mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        _reasonController.clear();
        setState(() {
          _selectedImage = null;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Berhasil request update lokasi toko, anda belum bisa check in jika lokasi belum disetujui oleh admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating store location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Update completed
    }
  }
}
