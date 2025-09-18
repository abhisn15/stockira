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

  // Main screen data
  List<Store> _mappedStores = []; // Stores yang sudah ditambahkan ke mapping
  bool _isLoadingMappedStores = false;
  
  // Add store screen data
  final List<Area> _areas = [];
  List<SubArea> _subAreas = [];
  List<Store> _availableStores = []; // Stores yang bisa dipilih untuk ditambahkan
  List<Store> _visitedStores = [];
  
  Area? _selectedArea;
  SubArea? _selectedSubArea;
  final Set<int> _selectedStoreIds = {}; // Store IDs yang dipilih untuk ditambahkan
  
  bool _isLoadingStores = false;
  bool _isLoadingVisitedStores = false;
  bool _isAddingStores = false;
  
  Position? _currentPosition;
  
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
    _loadMappedStores();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMappedStores() async {
    setState(() {
      _isLoadingMappedStores = true;
    });
    try {
      // Load stores that are already mapped/assigned to employee
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, load sample mapped stores
      final sampleMappedStores = [
        Store(
          id: 30929,
          name: 'Hari Hari ITC Fatmawati',
          address: 'Jl. Raya Karang Bolong No.11, RT.1/RW.5, Cipete Utara, Kec. Kby. Baru, Kota Jakarta Selatan',
          latitude: -6.2615,
          longitude: 106.8106,
          areaId: 1,
          areaName: 'Jakarta Selatan',
        ),
        Store(
          id: 57078,
          name: 'warkop A',
          address: 'Blok B2 No.26, Jl. Fatmawati No.26, RT.1/RW.5, Cipete Utara',
          latitude: -6.2600,
          longitude: 106.8110,
          areaId: 1,
          areaName: 'Jakarta Selatan',
        ),
      ];
      
      setState(() {
        _mappedStores = sampleMappedStores;
        _isLoadingMappedStores = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMappedStores = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading mapped stores: $e')),
        );
      }
    }
  }


  Future<void> _loadSubAreas(int areaId) async {
    setState(() {
      _subAreas = [];
    });
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, load sample sub areas
      final sampleSubAreas = [
        SubArea(id: 1, name: 'Jakarta Selatan', areaId: areaId),
        SubArea(id: 2, name: 'Jakarta Utara', areaId: areaId),
        SubArea(id: 3, name: 'Jakarta Timur', areaId: areaId),
        SubArea(id: 4, name: 'Jakarta Barat', areaId: areaId),
      ];
      
      setState(() {
        _subAreas = sampleSubAreas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sub areas: $e')),
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
      setState(() {
        _visitedStores = _availableStores.where((store) => 
          store.name.contains('Hari Hari') || store.name.contains('warkop')).toList();
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

  Future<void> _loadAvailableStores(int subAreaId) async {
    setState(() {
      _isLoadingStores = true;
      _availableStores = [];
    });

    try {
      // For demo purposes, load sample data
      await Future.delayed(const Duration(seconds: 1));
      
      final sampleStores = [
        Store(
          id: 30930,
          name: 'Alfamart Ahmad Razak',
          address: 'Jl. K.H. Ahmad Razak No.85, Takkalala, Kec. Wara Sel., Kota Palopo, Sulawesi Selatan',
          latitude: -3.0076207,
          longitude: 120.1890001,
          areaId: _selectedArea?.id ?? 1,
          areaName: _selectedArea?.name ?? 'Unknown',
        ),
        Store(
          id: 38871,
          name: 'ALFAMART AHMAD RAZAK PALOPO',
          address: 'Jl. Ahmad Razak, Palopo, Sulawesi Selatan',
          latitude: -3.0128025,
          longitude: 120.2021205,
          areaId: _selectedArea?.id ?? 1,
          areaName: _selectedArea?.name ?? 'Unknown',
        ),
        Store(
          id: 7075,
          name: 'alfamart ahmad razak TDTK',
          address: 'X6P2+VRH, Tompotika, Kec. Wara, Kota Palopo, Sulawesi Selatan',
          latitude: -3.0128025,
          longitude: 120.2021205,
          areaId: _selectedArea?.id ?? 1,
          areaName: _selectedArea?.name ?? 'Unknown',
        ),
        Store(
          id: 39162,
          name: 'ALFAMART AHMAD YANI MASAMBA',
          address: 'Jl. Ahmad Yani, Masamba, Sulawesi Selatan',
          latitude: -3.0100000,
          longitude: 120.1900000,
          areaId: _selectedArea?.id ?? 1,
          areaName: _selectedArea?.name ?? 'Unknown',
        ),
      ];
      
      setState(() {
        _availableStores = sampleStores;
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

  Future<void> _addStoresToMapping() async {
    if (_selectedStoreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu toko untuk ditambahkan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingStores = true;
    });

    try {
      final storeIds = _selectedStoreIds.toList();
      final success = await _storeMappingService.addStoresToEmployee(storeIds);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toko berhasil ditambahkan ke mapping'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset selection and go back to main screen
        _selectedStoreIds.clear();
        _selectedArea = null;
        _selectedSubArea = null;
        _availableStores.clear();
        _visitedStores.clear();
        
        // Reload mapped stores
        _loadMappedStores();
        
        // Go back to main screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding stores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAddingStores = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
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
      ),
      body: _buildMainScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStoreScreen();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMainScreen() {
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
                'Jumlah Toko : ${_mappedStores.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_mappedStores.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Refresh data
                    _loadMappedStores();
                  },
                  child: const Text(
                    'Refresh',
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
          child: _isLoadingMappedStores
              ? _buildSkeletonLoading()
              : _mappedStores.isEmpty
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
                            'Belum ada toko yang ditambahkan',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap tombol + untuk menambah toko',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _mappedStores.length,
                      itemBuilder: (context, index) {
                        final store = _mappedStores[index];
                        return _buildMappedStoreCard(store, index + 1);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Skeleton number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                // Skeleton content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMappedStoreCard(Store store, int index) {
    return GestureDetector(
      onTap: () {
        _navigateToStoreLocation(store);
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
        child: Padding(
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
                    
                    // Tap to view indicator
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
                            'Tap to View Location',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStoreScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
              
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Tambah Toko ke Mapping',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Filter Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Area Selection
                    DropdownButtonFormField<Area>(
                      initialValue: _selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Area',
                        border: OutlineInputBorder(),
                      ),
                      items: _areas.map((area) {
                        return DropdownMenuItem<Area>(
                          value: area,
                          child: Text(area.name),
                        );
                      }).toList(),
                      onChanged: (Area? area) {
                        setState(() {
                          _selectedArea = area;
                          _selectedSubArea = null;
                          _subAreas.clear();
                        });
                        if (area != null) {
                          _loadSubAreas(area.id);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Sub Area Selection
                    DropdownButtonFormField<SubArea>(
                      initialValue: _selectedSubArea,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Sub Area',
                        border: OutlineInputBorder(),
                      ),
                      items: _subAreas.map((subArea) {
                        return DropdownMenuItem<SubArea>(
                          value: subArea,
                          child: Text(subArea.name),
                        );
                      }).toList(),
                      onChanged: _selectedArea != null ? (SubArea? subArea) {
                        setState(() {
                          _selectedSubArea = subArea;
                        });
                        if (subArea != null) {
                          _loadAvailableStores(subArea.id);
                        }
                      } : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Store Selection Tabs
              if (_availableStores.isNotEmpty) ...[
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blue,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(
                        text: 'STORE COVERAGE(${_availableStores.length})',
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
                      _buildStoreSelectionTab(),
                      _buildLastVisitSelectionTab(),
                    ],
                  ),
                ),
                
                // Add Button
                if (_selectedStoreIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAddingStores ? null : _addStoresToMapping,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isAddingStores
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Menambahkan...'),
                                ],
                              )
                            : Text('Tambah ${_selectedStoreIds.length} Toko'),
                      ),
                    ),
                  ),
              ] else if (_selectedArea != null && _selectedSubArea != null && _isLoadingStores) ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat toko...'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
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
                          'Pilih area dan sub area untuk melihat toko',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreSelectionTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableStores.length,
      itemBuilder: (context, index) {
        final store = _availableStores[index];
        final isSelected = _selectedStoreIds.contains(store.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CheckboxListTile(
            title: Text(
              store.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.id} - ${store.areaName ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.address,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedStoreIds.add(store.id);
                } else {
                  _selectedStoreIds.remove(store.id);
                }
              });
            },
            activeColor: Colors.blue,
          ),
        );
      },
    );
  }

  Widget _buildLastVisitSelectionTab() {
    return _isLoadingVisitedStores
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
                  final isSelected = _selectedStoreIds.contains(store.id);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${store.id} - ${store.areaName ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedStoreIds.add(store.id);
                          } else {
                            _selectedStoreIds.remove(store.id);
                          }
                        });
                      },
                      activeColor: Colors.blue,
                      secondary: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'VISITED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
  }

  void _navigateToStoreLocation(Store store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoreLocationScreen(store: store),
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


}

// Store Location Screen with Google Maps and Update Form
class StoreLocationScreen extends StatefulWidget {
  final Store store;

  const StoreLocationScreen({super.key, required this.store});

  @override
  State<StoreLocationScreen> createState() => _StoreLocationScreenState();
}

class _StoreLocationScreenState extends State<StoreLocationScreen> {
  final StoreMappingService _storeMappingService = StoreMappingService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _reasonController = TextEditingController();
  
  Position? _currentPosition;
  File? _selectedImage;
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

  Future<void> _updateStoreLocation() async {
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

    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      final locationUpdate = StoreLocationUpdate(
        storeId: widget.store.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        notes: _reasonController.text.trim(),
      );

      final success = await _storeMappingService.updateStoreLocation(locationUpdate);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil request update lokasi toko'),
            backgroundColor: Colors.green,
          ),
        );
        
        _reasonController.clear();
        setState(() {
          _selectedImage = null;
        });
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
      setState(() {
        _isUpdatingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Update Lokasi Toko',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Store Info
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.store.id} - ${widget.store.areaName ?? 'Unknown'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.store.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jarak: ${_calculateDistance(widget.store)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Google Maps
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                            markerId: const MarkerId('current_location'),
                            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                            infoWindow: const InfoWindow(
                              title: 'Lokasi Anda',
                            ),
                          ),
                          if (widget.store.latitude != null && widget.store.longitude != null)
                            Marker(
                              markerId: const MarkerId('store_location'),
                              position: LatLng(widget.store.latitude!, widget.store.longitude!),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              infoWindow: InfoWindow(
                                title: widget.store.name,
                                snippet: widget.store.address,
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
            
            // Update Form
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                          'Jarak ke toko: ${_calculateDistance(widget.store)}',
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
                  
                  const SizedBox(height: 20),
                  
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdatingLocation ? null : _updateStoreLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isUpdatingLocation
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Updating...'),
                              ],
                            )
                          : const Text('Update Lokasi'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
