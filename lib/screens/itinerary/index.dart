import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/itinerary.dart';
import '../../models/store.dart' as StoreModel;
import '../../services/itinerary_service.dart';
import '../../services/employee_stores_service.dart';
import '../../services/create_itinerary_service.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<Itinerary> _itineraries = [];
  List<StoreModel.Store> _availableStores = [];
  List<Map<String, dynamic>> _lastVisitedStores = [];
  Set<int> _selectedStoreIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<StoreModel.Store> _filteredStores = [];
  
  // Location
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load itineraries
      final itineraryResponse = await ItineraryService.getItineraries();
      
      // Load available stores for employee
      await _loadAvailableStores();
      
      
      // Load last visited stores from yesterday's itineraries
      await _generateLastVisitedStores();
      

      setState(() {
        _itineraries = itineraryResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableStores() async {
    try {
      final response = await EmployeeStoresService.getStoresForCurrentUser();
      
      if (response.success) {
        setState(() {
          _availableStores = response.data;
          _filteredStores = response.data;
        });
      } else {
        print('Error loading available stores: ${response.message}');
      }
    } catch (e) {
      print('Error loading available stores: $e');
    }
  }



  Future<void> _generateLastVisitedStores() async {
    try {
      // Get yesterday's date in YYYY-MM-DD format
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      
      print('📅 Loading last visited stores for date: $yesterdayString');
      
      // Get itineraries from yesterday
      final response = await ItineraryService.getItinerariesByStartDate(yesterdayString);
      
      if (response.success && response.data.isNotEmpty) {
        final List<Map<String, dynamic>> lastVisitedList = [];
        
        // Process all itineraries from yesterday
        for (final itinerary in response.data) {
          for (final store in itinerary.stores) {
            // Calculate distance from current location if available
            double distance = 0.0;
            if (_currentLatitude != null && _currentLongitude != null) {
              final storeLat = double.tryParse(store.latitude ?? '0') ?? 0.0;
              final storeLon = double.tryParse(store.longitude ?? '0') ?? 0.0;
              distance = _calculateDistance(_currentLatitude, _currentLongitude, storeLat, storeLon);
            }
            
            lastVisitedList.add({
              'storeId': store.id,
              'storeName': store.name,
              'lastVisitDate': DateTime.parse(itinerary.date),
              'checkInTime': '08:00', // Default time since not provided in API
              'checkOutTime': '17:00', // Default time since not provided in API
              'isApproved': true,
              'isOutItinerary': false,
              'distance': distance,
              'latitude': double.tryParse(store.latitude ?? '0') ?? 0.0,
              'longitude': double.tryParse(store.longitude ?? '0') ?? 0.0,
              'code': store.code,
              'account': 'Store', // Default since not provided in API
              'address': store.address,
            });
          }
        }
        
        setState(() {
          _lastVisitedStores = lastVisitedList;
        });
        
        print('📊 Loaded ${_lastVisitedStores.length} last visited stores from yesterday\'s itineraries');
      } else {
        print('📊 No itineraries found for yesterday: ${response.message}');
        setState(() {
          _lastVisitedStores = [];
        });
      }
    } catch (e) {
      print('Error loading last visited stores: $e');
      setState(() {
        _lastVisitedStores = [];
      });
    }
  }

  double _calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return 0.0;
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(2)}KM';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)}KM';
    }
  }

  void _filterStores(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStores = _availableStores;
      } else {
        _filteredStores = _availableStores.where((store) {
          return store.name.toLowerCase().contains(query.toLowerCase()) ||
                 (store.code?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 store.account.name.toLowerCase().contains(query.toLowerCase()) ||
                 (store.address?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari Store'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari berdasarkan nama, kode, atau alamat...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: _filterStores,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _filterStores('');
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddStoreDialog();
            },
            child: const Text('Pilih Store'),
          ),
        ],
      ),
    );
  }

  void _showStoreMenu(StoreModel.Store store) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Detail Store'),
              onTap: () {
                Navigator.pop(context);
                _showStoreDetail(store);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Lihat di Map'),
              onTap: () {
                Navigator.pop(context);
                _showStoreOnMap(store);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Tambah ke Itinerary'),
              onTap: () {
                Navigator.pop(context);
                _addSingleStoreToItinerary(store);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Hubungi Store'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement phone call
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreDetail(StoreModel.Store store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kode: ${store.code ?? 'N/A'}'),
            Text('Account: ${store.account.name}'),
            if (store.address != null) ...[
              const SizedBox(height: 8),
              Text('Alamat: ${store.address}'),
            ],
            const SizedBox(height: 8),
            Text('Koordinat: ${store.latitude}, ${store.longitude}'),
            const SizedBox(height: 8),
            Text('Status: ${store.isRequested ? 'Requested' : 'Approved'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showStoreOnMap(StoreModel.Store store) {
    // TODO: Implement map view for specific store
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menampilkan ${store.name} di map'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _addSingleStoreToItinerary(StoreModel.Store store) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Call API to add store to itinerary
      final response = await CreateItineraryService.createItinerary(
        date: dateString,
        storeIds: [store.id],
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store ${store.name} berhasil ditambahkan ke itinerary'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reload data to show updated itinerary
        await _loadData();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan store: ${response.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAddStoreDialog() {
    _selectedStoreIds.clear(); // Reset selection
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Pilih Store',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedStoreIds.isNotEmpty)
                      Text(
                        '${_selectedStoreIds.length} dipilih',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              if (_selectedStoreIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _addSelectedStoresToItinerary(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tambah ke Itinerary'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedStoreIds.clear();
                          });
                        },
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari store...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (query) {
                    setModalState(() {
                      if (query.isEmpty) {
                        _filteredStores = _availableStores;
                      } else {
                        _filteredStores = _availableStores.where((store) {
                          return store.name.toLowerCase().contains(query.toLowerCase()) ||
                                 (store.code?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                                 store.account.name.toLowerCase().contains(query.toLowerCase()) ||
                                 (store.address?.toLowerCase().contains(query.toLowerCase()) ?? false);
                        }).toList();
                      }
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Store list
              Expanded(
                child: _filteredStores.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada store ditemukan',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredStores.length,
                        itemBuilder: (context, index) {
                          final store = _filteredStores[index];
                    final distance = _currentLatitude != null && _currentLongitude != null
                        ? _calculateDistance(
                            _currentLatitude,
                            _currentLongitude,
                            double.tryParse(store.latitude ?? '0'),
                            double.tryParse(store.longitude ?? '0'),
                          )
                        : 0.0;
                    final isSelected = _selectedStoreIds.contains(store.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.blue[600] : Colors.blue[100],
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          store.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue[700] : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${store.code ?? 'N/A'} - ${store.account.name}'),
                            if (store.address != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  Expanded(
                                    child: Text(
                                      store.address!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                                Text(
                                  'Jarak : ${_formatDistance(distance)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showStoreMenu(store),
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                            ),
                            isSelected
                                ? IconButton(
                                    onPressed: () {
                                      setModalState(() {
                                        _selectedStoreIds.remove(store.id);
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  )
                                : IconButton(
                                    onPressed: () {
                                      setModalState(() {
                                        _selectedStoreIds.add(store.id);
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                                  ),
                          ],
                        ),
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              _selectedStoreIds.remove(store.id);
                            } else {
                              _selectedStoreIds.add(store.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSelectedStoresToItinerary() async {
    if (_selectedStoreIds.isEmpty) return;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Call API to add stores to itinerary
      final response = await CreateItineraryService.createItinerary(
        date: dateString,
        storeIds: _selectedStoreIds.toList(),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.success) {
        // Close the store selection modal
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedStoreIds.length} store berhasil ditambahkan ke itinerary'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reload data to show updated itinerary
        await _loadData();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan store: ${response.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Itinerary',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
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
          tabs: [
            Tab(text: 'STORE COVERAGE(${_itineraries.length})'),
            Tab(text: 'LAST VISIT(${_lastVisitedStores.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStoreCoverageTab(),
                    _buildLastVisitTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStoreDialog,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCoverageTab() {
    // Get all stores from all itineraries
    final allStores = <StoreModel.Store>[];
    for (var itinerary in _itineraries) {
      for (var store in itinerary.stores) {
        // Convert itinerary Store to StoreModel.Store
        allStores.add(StoreModel.Store(
          id: store.id,
          name: store.name,
          code: store.code,
          address: store.address,
          latitude: store.latitude ?? '0',
          longitude: store.longitude ?? '0',
          isDistributor: store.isDistributor,
          isClose: store.isClose,
          isRequested: store.isRequested,
          distance: 0.0,
          account: StoreModel.StoreAccount(
            id: 0,
            name: 'Unknown',
          ),
          employees: [],
        ));
      }
    }

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(
                'Jumlah Toko : ${allStores.length}',
            style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement "Lihat Semua" functionality
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
        ),
        
        // Store list
        Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
            itemCount: allStores.length,
        itemBuilder: (context, index) {
              final store = allStores[index];
              final distance = _currentLatitude != null && _currentLongitude != null
                  ? _calculateDistance(
                      _currentLatitude,
                      _currentLongitude,
                      double.tryParse(store.latitude),
                      double.tryParse(store.longitude),
                    )
                  : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                                      store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                                        fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                                      '${store.code ?? 'N/A'} - ${store.account.name}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                            ],
                          ),
                          
                          if (store.address != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                  child: Text(
                                    store.address!,
                                    style: TextStyle(
                      fontSize: 12,
                                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
                          ],
                          
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
            Text(
                                'Jarak : ${_formatDistance(distance)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          
            const SizedBox(height: 8),
                          Icon(Icons.description, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
                    
                    // Visited badge
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Visited',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Menu button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => _showStoreMenu(store),
                        icon: const Icon(Icons.more_vert, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLastVisitTab() {
    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah Toko : ${_lastVisitedStores.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement "Lihat Semua" functionality
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Last visited stores list
        Expanded(
          child: _lastVisitedStores.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat kunjungan',
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
                  itemCount: _lastVisitedStores.length,
                  itemBuilder: (context, index) {
                    final store = _lastVisitedStores[index];
                    final distance = _currentLatitude != null && _currentLongitude != null
                        ? _calculateDistance(
                            _currentLatitude,
                            _currentLongitude,
                            store['latitude'] as double?,
                            store['longitude'] as double?,
                          )
                        : store['distance'] as double? ?? 0.0;

    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
                        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
        children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                            store['storeName'] as String,
                  style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ID: ${store['storeId']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                Text(
                                      'Terakhir: ${_formatDate(store['lastVisitDate'] as DateTime)}',
                                      style: TextStyle(
                    fontSize: 12,
                                        color: Colors.grey[600],
                  ),
                ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                Row(
                  children: [
                                    Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Jarak : ${_formatDistance(distance)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status: ${store['isApproved'] ? 'Approved' : 'Pending'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: store['isApproved'] ? Colors.green[600] : Colors.orange[600],
                                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
                          
                          // Visited badge
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
              ),
              child: const Text(
                                'Visited',
                style: TextStyle(
                                  color: Colors.white,
                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                ),
              ),
            ),
                          
                          // Menu button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () {
                                // TODO: Implement menu functionality
                              },
                              icon: const Icon(Icons.more_vert, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
      final now = DateTime.now();
    final difference = now.difference(date).inDays;

      if (difference == 0) {
      return 'Hari ini';
      } else if (difference == 1) {
      return 'Kemarin';
    } else if (difference < 7) {
      return '$difference hari lalu';
      } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}