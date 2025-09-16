import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../services/availability_service.dart';
import '../../models/availability.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  // Form controllers
  final _searchController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<AvailabilityData> _itineraries = [];
  List<Product> _allProducts = [];
  List<Product> _availableProducts = [];
  List<Product> _selectedProducts = [];
  Store? _selectedStore;
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0 = NEW, 1 = HISTORY
  String _selectedStoreName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load itineraries first
      final itineraryResponse = await AvailabilityService.getItineraries();
      
      if (itineraryResponse.success) {
        setState(() {
          _itineraries = itineraryResponse.data;
        });
        
        // If we have itineraries, set the first store as default
        if (_itineraries.isNotEmpty && _itineraries.first.stores.isNotEmpty) {
          final firstStore = _itineraries.first.stores.first;
          setState(() {
            _selectedStore = firstStore;
            _selectedStoreName = firstStore.name;
          });
          
          // Load products for the selected store
          await _loadStoreProducts(firstStore.id);
        }
      } else {
        _showSnackBar('Failed to load itineraries: ${itineraryResponse.message}', Colors.red);
      }
      
    } catch (e) {
      print('Error loading data: $e');
      _showSnackBar('Error loading data: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStoreProducts(int storeId) async {
    try {
      // Load all products and available products in parallel
      final futures = await Future.wait([
        AvailabilityService.getAllProducts(),
        AvailabilityService.getStoreProducts(storeId),
      ]);
      
      final productsResponse = futures[0];
      final availableResponse = futures[1];
      
      if (productsResponse.success) {
        setState(() {
          _allProducts = productsResponse.data;
        });
      }
      
      if (availableResponse.success) {
        setState(() {
          _availableProducts = availableResponse.data;
        });
      }
      
    } catch (e) {
      print('Error loading store products: $e');
      _showSnackBar('Error loading store products: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _allProducts;
    return _allProducts.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.code.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  bool _isProductSelected(Product product) {
    return _selectedProducts.any((p) => p.id == product.id);
  }

  bool _isProductAvailable(Product product) {
    return _availableProducts.any((p) => p.id == product.id);
  }

  void _toggleProductSelection(Product product) {
    setState(() {
      if (_isProductSelected(product)) {
        _selectedProducts.removeWhere((p) => p.id == product.id);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  Future<void> _addProducts() async {
    if (_selectedStore == null) {
      _showSnackBar('Please check in to a store first', Colors.red);
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showSnackBar('Please select at least one product to add', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final productIds = _selectedProducts.map((p) => p.id).toList();
      
      print('🔄 Adding products to store ${_selectedStore!.id}: $productIds');
      
      final response = await AvailabilityService.addProductsToStore(
        storeId: _selectedStore!.id,
        productIds: productIds,
      );

      print('📤 Add Products Response: ${response}');

      if (response['success']) {
        _showSnackBar('Products added successfully!', Colors.green);
        // Reload available products for current store
        if (_selectedStore != null) {
          await _loadStoreProducts(_selectedStore!.id);
        }
        // Clear selection
        setState(() {
          _selectedProducts.clear();
        });
      } else {
        _showSnackBar(response['message'] ?? 'Failed to add products', Colors.red);
      }
    } catch (e) {
      print('Error adding products: $e');
      _showSnackBar('Error adding products: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateProducts() async {
    if (_selectedStore == null) {
      _showSnackBar('Please check in to a store first', Colors.red);
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showSnackBar('Please select products to update', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final productIds = _selectedProducts.map((p) => p.id).toList();
      
      print('🔄 Updating products for store ${_selectedStore!.id}: $productIds');
      
      final response = await AvailabilityService.updateStoreProducts(
        storeId: _selectedStore!.id,
        productIds: productIds,
      );

      print('📤 Update Products Response: ${response}');

      if (response['success']) {
        _showSnackBar('Products updated successfully!', Colors.green);
        // Reload available products for current store
        if (_selectedStore != null) {
          await _loadStoreProducts(_selectedStore!.id);
        }
        // Clear selection
        setState(() {
          _selectedProducts.clear();
        });
      } else {
        _showSnackBar(response['message'] ?? 'Failed to update products', Colors.red);
      }
    } catch (e) {
      print('Error updating products: $e');
      _showSnackBar('Error updating products: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          translate('Ketersediaan'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _itineraries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No itineraries found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your itinerary data',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildMainContent(),
      floatingActionButton: _selectedTabIndex == 0 && _selectedStore != null
          ? FloatingActionButton(
              onPressed: () => _showProductSelectionDialog(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Store Selection Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.store,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedStoreName.isNotEmpty ? _selectedStoreName : 'Select Store',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue,
              ),
            ],
          ),
        ),

        // Tab Buttons
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  'NEW',
                  _selectedTabIndex == 0,
                  () => setState(() => _selectedTabIndex = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTabButton(
                  'HISTORY (${_availableProducts.length})',
                  _selectedTabIndex == 1,
                  () => setState(() => _selectedTabIndex = 1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Content based on selected tab
        Expanded(
          child: _selectedTabIndex == 0 ? _buildNewTab() : _buildHistoryTab(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildNewTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration placeholder
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oopss Data Not Found!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add products',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_availableProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No products available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _availableProducts.length,
              itemBuilder: (context, index) {
                final product = _availableProducts[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Listing',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Product (${_allProducts.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedProducts.clear();
                        });
                      },
                      child: const Text(
                        'Unselect',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton('Product', true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton('Brand', false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton('Category', false),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Products List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final isSelected = _isProductSelected(product);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.blue[700] : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          product.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.blue[600])
                            : Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                        onTap: () => _toggleProductSelection(product),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Jumlah Produk: ${_selectedProducts.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _selectedProducts.isEmpty ? null : () {
                        Navigator.of(context).pop(); // Close modal
                        _addProducts();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Produk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildFilterButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.black87 : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isActive ? Icons.keyboard_arrow_up : Icons.filter_list,
            size: 16,
            color: isActive ? Colors.black87 : Colors.grey[600],
          ),
        ],
      ),
    );
  }

  String _formatPrice(String price) {
    try {
      final double value = double.parse(price);
      return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (e) {
      return price;
    }
  }
}