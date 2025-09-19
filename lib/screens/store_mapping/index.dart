import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/store_mapping.dart';
import '../../services/store_mapping_service.dart';
import 'location_update_screen.dart';

class StoreMappingScreen extends StatefulWidget {
  const StoreMappingScreen({super.key});

  @override
  State<StoreMappingScreen> createState() => _StoreMappingScreenState();
}

class _StoreMappingScreenState extends State<StoreMappingScreen>
    with TickerProviderStateMixin {

  // Main screen data
  List<Store> _mappedStores = []; // Stores yang sudah ditambahkan ke mapping
  bool _isLoadingMappedStores = false;
  bool _isLoadingAreas = false;
  
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
  
  // Animation controllers for tab transitions
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;

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
    
    // Initialize animation controller
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    );
    
    _loadMappedStores();
    _loadAreas();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _tabController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadMappedStores() async {
    setState(() {
      _isLoadingMappedStores = true;
    });
    try {
      // Get current employee ID
      final employeeId = await StoreMappingService.getCurrentEmployeeId();
      if (employeeId == null) {
        throw Exception('Employee ID tidak ditemukan');
      }

      // Load stores that are already mapped/assigned to employee
      final response = await StoreMappingService.getStoresByEmployee(employeeId);
      
      setState(() {
        _mappedStores = response.data;
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

  Future<void> _loadAreas() async {
    if (_isLoadingAreas) return; // Prevent multiple calls
    
    setState(() {
      _isLoadingAreas = true;
    });
    
    try {
      print('Loading areas...');
      final response = await StoreMappingService.getAreas();
      print('Areas response: ${response.data.length} areas loaded');
      
      // Clear existing data and reset selections
      setState(() {
        _areas.clear();
        _selectedArea = null;
        _selectedSubArea = null;
        _subAreas.clear();
        _availableStores.clear();
        _selectedStoreIds.clear();
        _isLoadingAreas = false;
      });
      
      // Add new areas
      setState(() {
        _areas.addAll(response.data);
      });
      
      // Update selected area to use the same object from the list if it exists
      if (_selectedArea != null) {
        final updatedArea = _areas.firstWhere(
          (area) => area.id == _selectedArea!.id,
          orElse: () => _selectedArea!,
        );
        if (updatedArea != _selectedArea) {
          setState(() {
            _selectedArea = updatedArea;
          });
        }
      }
      
      print('Areas loaded: ${_areas.map((a) => '${a.id}: ${a.name}').join(', ')}');
      print('Areas list length: ${_areas.length}');
    } catch (e) {
      print('Error loading areas: $e');
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

  Future<void> _loadSubAreas(int areaId, {Function()? onUpdate}) async {
    print('🔄 _loadSubAreas called with areaId: $areaId');
    setState(() {
      _subAreas = [];
      _selectedSubArea = null; // Reset selected sub area
    });
    try {
      print('Loading sub areas for area ID: $areaId');
      final response = await StoreMappingService.getSubAreas(areaId);
      print('Sub areas response: ${response.data.length} sub areas loaded');
      print('Sub areas data: ${response.data}');
      
      setState(() {
        _subAreas = response.data;
      });
      
      // Also update modal state if callback provided
      onUpdate?.call();
      
      print('✅ Sub areas loaded: ${_subAreas.map((sa) => '${sa.id}: ${sa.name}').join(', ')}');
      print('📋 Sub areas list length: ${_subAreas.length}');
      
      // Update selected area to use the same object from the list
      if (_selectedArea != null) {
        final updatedArea = _areas.firstWhere(
          (area) => area.id == _selectedArea!.id,
          orElse: () => _selectedArea!,
        );
        if (updatedArea != _selectedArea) {
          setState(() {
            _selectedArea = updatedArea;
          });
          onUpdate?.call();
        }
      }
    } catch (e) {
      print('❌ Error loading sub areas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sub areas: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailableStores(int subAreaId, {Function()? onUpdate}) async {
    setState(() {
      _isLoadingStores = true;
    });
    try {
      print('Loading available stores for sub area ID: $subAreaId');
      final response = await StoreMappingService.getStoresBySubArea(subAreaId);
      print('Available stores response: ${response.data.length} stores loaded');
      setState(() {
        _availableStores = response.data;
        _isLoadingStores = false;
      });
      
      // Also update modal state if callback provided
      onUpdate?.call();
      
      // Update selected sub area to use the same object from the list if it exists
      if (_selectedSubArea != null) {
        final updatedSubArea = _subAreas.firstWhere(
          (subArea) => subArea.id == _selectedSubArea!.id,
          orElse: () => _selectedSubArea!,
        );
        if (updatedSubArea != _selectedSubArea) {
          setState(() {
            _selectedSubArea = updatedSubArea;
          });
          onUpdate?.call();
        }
      }
      print('Available stores loaded: ${_availableStores.map((s) => '${s.id}: ${s.name}').join(', ')}');
    } catch (e) {
      print('Error loading available stores: $e');
      setState(() {
        _isLoadingStores = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading available stores: $e')),
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

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting current location: $e');
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
      final response = await StoreMappingService.addStoresToEmployee(storeIds);
      
      if (response.success && mounted) {
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
        backgroundColor: Colors.indigo, // Match dashboard icon color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildMainScreen(),
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: FloatingActionButton(
              onPressed: () {
                _showAddStoreScreen();
              },
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
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
                        return _buildAnimatedStoreCard(store, index + 1);
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
        return _buildAnimatedSkeletonCard(index);
      },
    );
  }

  Widget _buildAnimatedSkeletonCard(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 150)), // Staggered animation
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStoreCard(Store store, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)), // Staggered animation
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: _buildMappedStoreCard(store, index),
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
            children: [
              // Store number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Store info
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
                      '${store.id} - ${store.areaName ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address ?? 'No address',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Distance indicator
              if (_currentPosition != null && store.latitude != null && store.longitude != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${StoreMappingService.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      store.latitude!,
                      store.longitude!,
                    ).toStringAsFixed(0)}m',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStoreScreen() {
    // Reset state sebelum membuka bottomsheet
    setState(() {
      _selectedArea = null;
      _selectedSubArea = null;
      _subAreas.clear();
      _availableStores.clear();
      _visitedStores.clear();
      _selectedStoreIds.clear();
    });
    
    // Reload areas to ensure fresh data
    _loadAreas();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
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
                      value: _selectedArea != null && _areas.any((area) => area.id == _selectedArea!.id) 
                          ? _areas.firstWhere((area) => area.id == _selectedArea!.id)
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Pilih Area',
                        border: const OutlineInputBorder(),
                        hintText: _areas.isEmpty 
                            ? 'Loading areas...' 
                            : 'Pilih area terlebih dahulu',
                        suffixIcon: _areas.isEmpty 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      items: _areas.map((area) {
                        return DropdownMenuItem<Area>(
                          value: area,
                          child: Text('${area.id} - ${area.name}'),
                        );
                      }).toList(),
                      onChanged: _areas.isEmpty ? null : (Area? area) {
                        print('Area selected: ${area?.id} - ${area?.name}');
                        setModalState(() {
                          _selectedArea = area;
                          _selectedSubArea = null;
                          _subAreas.clear();
                          _availableStores.clear();
                        });
                        if (area != null) {
                          _loadSubAreas(area.id, onUpdate: () {
                            setModalState(() {});
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    
                    // Sub Area Selection
                    DropdownButtonFormField<SubArea>(
                      value: _selectedSubArea != null && _subAreas.any((subArea) => subArea.id == _selectedSubArea!.id) 
                          ? _subAreas.firstWhere((subArea) => subArea.id == _selectedSubArea!.id)
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Pilih Sub Area',
                        border: const OutlineInputBorder(),
                        hintText: _selectedArea == null 
                            ? 'Pilih area terlebih dahulu' 
                            : _subAreas.isEmpty 
                                ? 'Loading sub areas...'
                                : 'Pilih sub area',
                        suffixIcon: _selectedArea != null && _subAreas.isEmpty
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      items: _subAreas.map((subArea) {
                        return DropdownMenuItem<SubArea>(
                          value: subArea,
                          child: Text('${subArea.id} - ${subArea.name}'),
                        );
                      }).toList(),
                      onChanged: _selectedArea == null 
                          ? null 
                          : (SubArea? subArea) {
                              print('Sub area selected: ${subArea?.id} - ${subArea?.name}');
                              setModalState(() {
                                _selectedSubArea = subArea;
                                _availableStores.clear();
                              });
                              if (subArea != null) {
                                _loadAvailableStores(subArea.id, onUpdate: () {
                                  setModalState(() {});
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Debug Info for Available Stores
              if (_selectedSubArea != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _availableStores.isEmpty 
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    border: Border.all(
                      color: _availableStores.isEmpty ? Colors.purple : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _availableStores.isEmpty ? Icons.info_outline : Icons.check_circle,
                        color: _availableStores.isEmpty ? Colors.purple : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _availableStores.isEmpty 
                              ? 'Loading stores for ${_selectedSubArea?.name}... ${_availableStores.length} loaded'
                              : 'Stores loaded: ${_availableStores.length} stores available for ${_selectedSubArea?.name}',
                          style: TextStyle(
                            color: _availableStores.isEmpty ? Colors.purple : Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Store Selection Tabs
              // Debug: Show available stores count
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Available Stores: ${_availableStores.length} | Loading: $_isLoadingStores',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              
              if (_availableStores.isNotEmpty) ...[
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.indigo,
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    onTap: (index) {
                      _tabAnimationController.forward(from: 0);
                    },
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
                
                // Tab Content with Animation
                Expanded(
                  child: FadeTransition(
                    opacity: _tabAnimation,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStoreSelectionTab(setModalState),
                        _buildLastVisitSelectionTab(setModalState),
                      ],
                    ),
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
                          backgroundColor: Colors.indigo,
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
                Expanded(
                  child: ListView.builder(
                    itemCount: 3, // Show 3 skeleton cards
                    itemBuilder: (context, index) {
                      return _buildAnimatedSkeletonCard(index);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreSelectionTab(Function setModalState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableStores.length,
      itemBuilder: (context, index) {
        final store = _availableStores[index];
        final isSelected = _selectedStoreIds.contains(store.id);
        
        return _buildAnimatedStoreSelectionCard(store, index, isSelected, setModalState);
      },
    );
  }

  Widget _buildAnimatedStoreSelectionCard(Store store, int index, bool isSelected, Function setModalState) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)), // Staggered animation
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.grey.withValues(alpha: 0.3),
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
                      store.address ?? 'No address',
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
                  setModalState(() {
                    if (value == true) {
                      _selectedStoreIds.add(store.id);
                    } else {
                      _selectedStoreIds.remove(store.id);
                    }
                  });
                },
                activeColor: Colors.indigo,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastVisitSelectionTab(Function setModalState) {
    return _isLoadingVisitedStores
        ? ListView.builder(
            itemCount: 3, // Show 3 skeleton cards
            itemBuilder: (context, index) {
              return _buildAnimatedSkeletonCard(index);
            },
          )
        : _visitedStores.isEmpty
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
                      'Tidak ada riwayat kunjungan',
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
                  
                  return _buildAnimatedLastVisitCard(store, index, isSelected, setModalState);
                },
              );
  }

  Widget _buildAnimatedLastVisitCard(Store store, int index, bool isSelected, Function setModalState) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 75)), // Staggered animation
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.grey.withValues(alpha: 0.3),
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
                      store.address ?? 'No address',
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
                  setModalState(() {
                    if (value == true) {
                      _selectedStoreIds.add(store.id);
                    } else {
                      _selectedStoreIds.remove(store.id);
                    }
                  });
                },
                activeColor: Colors.indigo,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VISITED',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        builder: (context) => LocationUpdateScreen(store: store),
      ),
    );
  }
}
