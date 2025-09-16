import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/out_of_stock_report.dart';
import '../../../services/out_of_stock_service.dart';
import '../../../widgets/cute_loading_widget.dart';
import 'package:flutter_translate/flutter_translate.dart';

class OutOfStockReportScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const OutOfStockReportScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<OutOfStockReportScreen> createState() => _OutOfStockReportScreenState();
}

class _OutOfStockReportScreenState extends State<OutOfStockReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  bool _isOutOfStock = true;
  final List<OutOfStockProductData> _products = [];
  final List<XFile> _selectedImages = [];

  // API data
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isDropdownOpen = false;

  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final response = await OutOfStockService.getProducts(
        originId: 1,
        perPage: 100, // Load more products for better search
      );

      setState(() {
        _allProducts = response.data;
        _filteredProducts = response.data;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
                 product.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      // Keep dropdown open when filtering
      if (!_isDropdownOpen && query.isNotEmpty) {
        _isDropdownOpen = true;
      }
    });
  }

  void _addProduct() {
    setState(() {
      _products.add(OutOfStockProductData());
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery (Multiple)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickMultipleImagesFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera (Single)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await OutOfStockService.pickImageFromCamera();

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await OutOfStockService.pickMultipleImages();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking images: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_products.isEmpty) {
      _showErrorSnackBar('Please add at least one product');
      return;
    }

    // Validate all products
    for (int i = 0; i < _products.length; i++) {
      final product = _products[i];
      if (product.productId == null) {
        _showErrorSnackBar('Please select product for item ${i + 1}');
        return;
      }
      if (product.actualQty == null) {
        _showErrorSnackBar('Please enter actual quantity for item ${i + 1}');
        return;
      }
      if (product.estimatedPo == null) {
        _showErrorSnackBar('Please enter estimated PO for item ${i + 1}');
        return;
      }
      if (product.averageWeeklySaleOut == null) {
        _showErrorSnackBar('Please enter average weekly sale out for item ${i + 1}');
        return;
      }
      if (product.averageWeeklySaleIn == null) {
        _showErrorSnackBar('Please enter average weekly sale in for item ${i + 1}');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final products = _products.map((product) => OutOfStockProduct(
        productId: product.productId!,
        actualQty: product.actualQty!,
        estimatedPo: product.estimatedPo!,
        averageWeeklySaleOut: product.averageWeeklySaleOut!,
        averageWeeklySaleIn: product.averageWeeklySaleIn!,
        oosDistributor: product.oosDistributor ? 1 : 0,
      )).toList();

      final response = await OutOfStockService.submitOutOfStockReport(
        storeId: widget.storeId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        isOutOfStock: _isOutOfStock,
        products: products,
        images: _selectedImages,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        _showSuccessSnackBar('Out of stock report submitted successfully!');
        // Return success to trigger todo refresh
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error submitting form: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Out of Stock Report'),
          backgroundColor: const Color(0xFF29BDCE),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CuteLoadingWidget(
            message: 'Loading data...',
            size: 80,
            primaryColor: Color(0xFF29BDCE),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Out of Stock Report'),
        backgroundColor: const Color(0xFF29BDCE),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store info card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF29BDCE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Color(0xFF29BDCE),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.storeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date field
              _buildDateField(),

              const SizedBox(height: 16),

              // Out of stock toggle
              _buildOutOfStockToggle(),

              const SizedBox(height: 20),

              // Products section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Products *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29BDCE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Products list
              if (_products.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      translate('noProductsAdded'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(index);
                  },
                ),

              const SizedBox(height: 20),

              // Images section
              _buildImagesField(),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29BDCE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Out of Stock Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF29BDCE), size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutOfStockToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isOutOfStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isOutOfStock ? Icons.inventory_2_outlined : Icons.inventory,
                color: _isOutOfStock ? Colors.red : Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _isOutOfStock ? 'Out of Stock' : 'In Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isOutOfStock ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isOutOfStock,
              onChanged: (value) {
                setState(() {
                  _isOutOfStock = value;
                });
              },
              activeColor: Colors.red,
              inactiveThumbColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(int index) {
    final product = _products[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF29BDCE),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeProduct(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Product selection
            _buildProductDropdown(product),

            const SizedBox(height: 16),

            // Quantity fields in a row
            Row(
              children: [
                Expanded(
                  child: _buildNumericField(
                    label: 'Actual Qty *',
                    value: product.actualQty?.toString(),
                    onChanged: (value) {
                      final number = int.tryParse(value.trim());
                      product.actualQty = number;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumericField(
                    label: 'Estimated PO *',
                    value: product.estimatedPo?.toString(),
                    onChanged: (value) {
                      final number = int.tryParse(value.trim());
                      product.estimatedPo = number;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sales fields in a row
            Row(
              children: [
                Expanded(
                  child: _buildNumericField(
                    label: 'Avg Weekly Sale Out *',
                    value: product.averageWeeklySaleOut?.toString(),
                    onChanged: (value) {
                      final number = int.tryParse(value.trim());
                      product.averageWeeklySaleOut = number;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumericField(
                    label: 'Avg Weekly Sale In *',
                    value: product.averageWeeklySaleIn?.toString(),
                    onChanged: (value) {
                      final number = int.tryParse(value.trim());
                      product.averageWeeklySaleIn = number;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // OOS Distributor toggle
            Row(
              children: [
                const Text(
                  'OOS from Distributor: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: product.oosDistributor,
                  onChanged: (value) {
                    setState(() {
                      product.oosDistributor = value;
                    });
                  },
                  activeColor: Colors.red,
                  inactiveThumbColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDropdown(OutOfStockProductData product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // Integrated Searchable Dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Search field that opens dropdown
              InkWell(
                onTap: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                    if (_isDropdownOpen) {
                      _searchController.clear();
                      _filterProducts('');
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.productId != null 
                            ? _allProducts.firstWhere(
                                (p) => p.id == product.productId,
                                orElse: () => _allProducts.first,
                              ).name
                            : 'Search and select product...',
                          style: TextStyle(
                            fontSize: 14,
                            color: product.productId != null ? Colors.black87 : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              
              // Search field for filtering (visible when dropdown is open)
              if (_isDropdownOpen)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Type to search products...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      isDense: true,
                    ),
                    onChanged: _filterProducts,
                    autofocus: true,
                  ),
                ),
              
              // Dropdown with filtered results
              if (_isDropdownOpen && _filteredProducts.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index];
                      final isSelected = product.productId == p.id;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            product.productId = p.id;
                            _isDropdownOpen = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 13,
                                        color: isSelected ? Colors.blue[700] : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.code} • ${p.subbrand.name}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: Colors.blue[700],
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Show message when no results found
              if (_isDropdownOpen && _filteredProducts.isEmpty && _searchController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No products found for "${_searchController.text}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumericField({
    required String label,
    required String? value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF29BDCE)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // Add image button
        InkWell(
          onTap: _pickImages,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo,
                  color: Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap to add images',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected images preview
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Selected Images (${_selectedImages.length}):',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final image = _selectedImages[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class OutOfStockProductData {
  int? productId;
  int? actualQty;
  int? estimatedPo;
  int? averageWeeklySaleOut;
  int? averageWeeklySaleIn;
  bool oosDistributor = false;

  OutOfStockProductData({
    this.productId,
    this.actualQty,
    this.estimatedPo,
    this.averageWeeklySaleOut,
    this.averageWeeklySaleIn,
    this.oosDistributor = false,
  });
}
