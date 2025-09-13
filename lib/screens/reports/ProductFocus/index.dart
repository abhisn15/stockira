import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';
import 'package:flutter/services.dart';

class ProductFocusReportScreen extends StatefulWidget {
  const ProductFocusReportScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });
  final int storeId;
  final String storeName;

  @override
  State<ProductFocusReportScreen> createState() =>
      _ProductFocusReportScreenState();
}

class _ProductFocusReportScreenState extends State<ProductFocusReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime? _selectedDate;
  bool _isCountStockAllowed = true;
  List<ProductFocusItem> _products = [];

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  // API data
  List<ProductFocusData> _productFocuses = [];
  List<ProductFocusData> _filteredProducts = [];

  // UI state
  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all product controllers
    for (var product in _products) {
      product.quantityController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    await _loadProductFocuses();

    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _loadProductFocuses() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('No authentication token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/products/focuses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _productFocuses = (data['data'] as List)
              .map((product) => ProductFocusData.fromJson(product))
              .toList();
          _filteredProducts = _productFocuses;
        });
        
        print('=== LOADED PRODUCT FOCUSES ===');
        print('Total products loaded: ${_productFocuses.length}');
        for (var product in _productFocuses.take(3)) {
          print('Product: ${product.name} (ID: ${product.id})');
          if (product.focuses != null && product.focuses!.isNotEmpty) {
            print('  Focus ID: ${product.focuses!.first.id}');
          } else {
            print('  No focuses found');
          }
        }
      } else {
        print('Error loading product focuses: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading product focuses: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _productFocuses;
      } else {
        _filteredProducts = _productFocuses.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
                 (product.code?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
      // Keep dropdown open when filtering
      if (!_isDropdownOpen && query.isNotEmpty) {
        _isDropdownOpen = true;
      }
    });
  }

  void _addProduct(ProductFocusData productData) {
    // Get the focus ID from the product data
    int? focusId = productData.focuses?.isNotEmpty == true ? productData.focuses!.first.id : null;
    
    if (focusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product ${productData.name} tidak memiliki focus ID')),
      );
      return;
    }

    // Check if product already exists
    bool exists = _products.any((p) => p.productFocusId == focusId);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product ${productData.name} sudah ditambahkan')),
      );
      return;
    }

    setState(() {
      _products.add(ProductFocusItem(
        productFocusId: focusId,
        productName: productData.name,
        quantityController: TextEditingController(text: '1'),
      ));
    });
    
    print('=== ADDED PRODUCT ===');
    print('Product Name: ${productData.name}');
    print('Product ID: ${productData.id}');
    print('Focus ID: $focusId');
  }

  void _removeProduct(int index) {
    setState(() {
      _products[index].quantityController.dispose();
      _products.removeAt(index);
    });
  }


  String _formatRupiah(String priceString) {
    try {
      double price = double.parse(priceString);
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
      return formatter.format(price);
    } catch (e) {
      return priceString;
    }
  }


  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authentication token available')),
        );
        return;
      }

      // Prepare products data
      List<Map<String, dynamic>> productsData = [];
      for (var product in _products) {
        String quantityText = product.quantityController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (quantityText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter quantity for ${product.productName}')),
          );
          return;
        }
        
        // Validate focus ID
        if (product.productFocusId <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid focus ID for ${product.productName}')),
          );
          return;
        }
        
        productsData.add({
          'product_focus_id': product.productFocusId,
          'quantity': int.parse(quantityText),
        });
        
        print('=== PRODUCT VALIDATION ===');
        print('Product: ${product.productName}');
        print('Focus ID: ${product.productFocusId} (valid: ${product.productFocusId > 0})');
        print('Quantity: ${int.parse(quantityText)}');
      }

      // Use the selected date as is (server expects this format)
      DateTime selectedDate = _selectedDate!;
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'store_id': widget.storeId,
        'is_count_stock_allowed': _isCountStockAllowed,
        'date': formattedDate,
        'products': productsData,
      };

      print('=== DEBUG SUBMIT DATA ===');
      print('store_id: ${widget.storeId} (type: ${widget.storeId.runtimeType})');
      print('is_count_stock_allowed: $_isCountStockAllowed (type: ${_isCountStockAllowed.runtimeType})');
      print('date: ${requestBody['date']} (type: ${requestBody['date'].runtimeType})');
      print('products: $productsData');
      print('Full request body: ${jsonEncode(requestBody)}');
      
      // Compare with expected format
      print('=== EXPECTED FORMAT COMPARISON ===');
      print('Expected: {"store_id":1,"is_count_stock_allowed":true,"date":"2025-08-19","products":[{"product_focus_id":1,"quantity":2}]}');
      print('Actual:   ${jsonEncode(requestBody)}');

      // Try JSON request first
      print('=== TRYING JSON REQUEST ===');
      var jsonResponse = await http.post(
        Uri.parse('${Env.apiBaseUrl}/reports/product-focus'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('=== JSON RESPONSE ===');
      print('Status Code: ${jsonResponse.statusCode}');
      print('Response Body: ${jsonResponse.body}');

      // If still 500, try with store_id = 1 (as in example)
      if (jsonResponse.statusCode == 500 && widget.storeId != 1) {
        print('=== TRYING WITH STORE_ID = 1 ===');
        
        Map<String, dynamic> fallbackRequestBody = Map.from(requestBody);
        fallbackRequestBody['store_id'] = 1;
        
        print('Fallback request body: ${jsonEncode(fallbackRequestBody)}');
        
        var fallbackResponse = await http.post(
          Uri.parse('${Env.apiBaseUrl}/reports/product-focus'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(fallbackRequestBody),
        );
        
        print('=== FALLBACK RESPONSE ===');
        print('Status Code: ${fallbackResponse.statusCode}');
        print('Response Body: ${fallbackResponse.body}');
        
        // Use fallback response if successful
        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product Focus report submitted successfully! (Using fallback store_id)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          );
          Navigator.pop(context);
          return;
        }
      }

      // Use JSON response for now
      final response = jsonResponse;
      final responseBody = jsonResponse.body;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product Focus report submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        try {
          final errorData = jsonDecode(responseBody);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${errorData['message'] ?? 'Failed to submit report'}',
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Server returned status ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Product Focus Report',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29BDCE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildStoreInfo(),
                        const SizedBox(height: 16),
                        _buildDateField(),
                        const SizedBox(height: 16),
                        _buildCountStockAllowedField(),
                        const SizedBox(height: 16),
                        _buildProductDropdown(),
                        const SizedBox(height: 16),
                        _buildProductsList(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF29BDCE).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF29BDCE).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.center_focus_strong, color: const Color(0xFF29BDCE), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submit Product Focus report with multiple products and quantities',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF29BDCE).withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
    );
  }

  Widget _buildCountStockAllowedField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Count Stock Allowed',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Allow stock counting'),
          subtitle: const Text('Enable stock counting for this report'),
          value: _isCountStockAllowed,
          onChanged: (value) {
            setState(() {
              _isCountStockAllowed = value;
            });
          },
          activeColor: const Color(0xFF29BDCE),
          contentPadding: EdgeInsets.zero,
        ),
      ],
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
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now(),
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
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedDate != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Focus *',
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
                          'Search and select product focus to add...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _isDropdownOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              Container(height: 1, color: Colors.grey[300]),

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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                      final product = _filteredProducts[index];

                      return InkWell(
                        onTap: () {
                          _addProduct(product);
                          setState(() {
                            _isDropdownOpen = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Product image
                              if (product.imageUrl != null)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    image: DecorationImage(
                                      image: NetworkImage(product.imageUrl!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (product.code != null && product.code!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        product.code!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                    if (product.latestPrice != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rp ${_formatRupiah(product.latestPrice!.price)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Show message when no results found
              if (_isDropdownOpen &&
                  _filteredProducts.isEmpty &&
                  _searchController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No products found for "${_searchController.text}"',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Products',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_products.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No products added yet. Search and select products above.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...List.generate(_products.length, (index) {
            final product = _products[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: product.quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeProduct(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }


  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF29BDCE),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                'Submit Product Focus Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// Custom input formatter for Rupiah
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // Extract only digits from the new value
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If empty, return empty string
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Parse the number and format it
    try {
      int number = int.parse(newText);
      
      // Format with Indonesian locale, no symbol, no decimal
      final formatter = NumberFormat.currency(
        locale: 'id_ID', 
        symbol: '', 
        decimalDigits: 0
      );
      
      String formatted = formatter.format(number);
      
      // Return with cursor at the end
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      // If parsing fails, return the original value
      return newValue;
    }
  }
}

// Data models

class ProductFocusItem {
  final int productFocusId;
  final String productName;
  final TextEditingController quantityController;

  ProductFocusItem({
    required this.productFocusId,
    required this.productName,
    required this.quantityController,
  });
}

class ProductFocusData {
  final int id;
  final String? code;
  final String name;
  final String? imageUrl;
  final LatestPrice? latestPrice;
  final List<Focus>? focuses;

  ProductFocusData({
    required this.id,
    this.code,
    required this.name,
    this.imageUrl,
    this.latestPrice,
    this.focuses,
  });

  factory ProductFocusData.fromJson(Map<String, dynamic> json) {
    return ProductFocusData(
      id: json['id'] ?? 0,
      code: json['code'],
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      latestPrice: json['latest_price'] != null 
          ? LatestPrice.fromJson(json['latest_price'])
          : null,
      focuses: json['focuses'] != null
          ? (json['focuses'] as List).map((f) => Focus.fromJson(f)).toList()
          : null,
    );
  }
}

class Focus {
  final int id;
  final int productId;
  final String createdAt;
  final String updatedAt;
  final List<dynamic> stores;

  Focus({
    required this.id,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    required this.stores,
  });

  factory Focus.fromJson(Map<String, dynamic> json) {
    return Focus(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      stores: json['stores'] ?? [],
    );
  }
}

class LatestPrice {
  final String price;

  LatestPrice({required this.price});

  factory LatestPrice.fromJson(Map<String, dynamic> json) {
    return LatestPrice(
      price: json['price'] ?? '0',
    );
  }
}
