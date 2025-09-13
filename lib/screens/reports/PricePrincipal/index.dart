import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';

class PricePrincipalReportScreen extends StatefulWidget {
  const PricePrincipalReportScreen({super.key, required this.storeId, required this.storeName});
  final int storeId;
  final String storeName;

  @override
  State<PricePrincipalReportScreen> createState() => _PricePrincipalReportScreenState();
}

class _PricePrincipalReportScreenState extends State<PricePrincipalReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productsController = TextEditingController();
  
  // Form fields
  DateTime? _selectedDate;
  final List<PriceProductData> _products = [];
  
  // Store info from check-in
  int? _storeId;
  
  // API data
  List<ProductData> _allProducts = [];
  List<ProductData> _filteredProducts = [];
  
  // UI state
  bool _isLoading = false;
  int? _openDropdownIndex; // Track which product card's dropdown is open

  // Controllers and FocusNodes for price and promo price fields
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _promoPriceControllers = {};
  final Map<int, FocusNode> _priceFocusNodes = {};
  final Map<int, FocusNode> _promoPriceFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _productsController.dispose();
    // Dispose all controllers and focus nodes
    _priceControllers.values.forEach((c) => c.dispose());
    _promoPriceControllers.values.forEach((c) => c.dispose());
    _priceFocusNodes.values.forEach((f) => f.dispose());
    _promoPriceFocusNodes.values.forEach((f) => f.dispose());
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadStoreFromCheckIn(),
      _loadProducts(),
    ]);
  }

  Future<void> _loadStoreFromCheckIn() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('No authentication token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          final storeData = data['data'][0]; // Get first store from check-in
          setState(() {
            _storeId = storeData['id'];
          });
        }
      } else {
        print('Error loading store: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading store from check-in: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('No authentication token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/products?conditions[origin_id]=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allProducts = (data['data'] as List)
              .map((product) => ProductData.fromJson(product))
              .toList();
          _filteredProducts = _allProducts;
        });
      } else {
        print('Error loading products: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading products: $e');
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
      // Keep dropdown open when filtering - not needed with new dropdown system
    });
  }

  void _addProduct() {
    setState(() {
      _products.add(PriceProductData());
      final idx = _products.length - 1;
      // Initialize controllers and focus nodes for new product
      _priceControllers[idx] = TextEditingController();
      _promoPriceControllers[idx] = TextEditingController();
      _priceFocusNodes[idx] = FocusNode();
      _promoPriceFocusNodes[idx] = FocusNode();
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
      // Remove controllers and focus nodes for this index
      _priceControllers[index]?.dispose();
      _promoPriceControllers[index]?.dispose();
      _priceFocusNodes[index]?.dispose();
      _promoPriceFocusNodes[index]?.dispose();
      _priceControllers.remove(index);
      _promoPriceControllers.remove(index);
      _priceFocusNodes.remove(index);
      _promoPriceFocusNodes.remove(index);

      // Shift controllers/focus nodes for subsequent indices
      final newPriceControllers = <int, TextEditingController>{};
      final newPromoPriceControllers = <int, TextEditingController>{};
      final newPriceFocusNodes = <int, FocusNode>{};
      final newPromoPriceFocusNodes = <int, FocusNode>{};
      for (int i = 0; i < _products.length; i++) {
        newPriceControllers[i] = _priceControllers[i >= index ? i + 1 : i] ?? TextEditingController();
        newPromoPriceControllers[i] = _promoPriceControllers[i >= index ? i + 1 : i] ?? TextEditingController();
        newPriceFocusNodes[i] = _priceFocusNodes[i >= index ? i + 1 : i] ?? FocusNode();
        newPromoPriceFocusNodes[i] = _promoPriceFocusNodes[i >= index ? i + 1 : i] ?? FocusNode();
      }
      _priceControllers
        ..clear()
        ..addAll(newPriceControllers);
      _promoPriceControllers
        ..clear()
        ..addAll(newPromoPriceControllers);
      _priceFocusNodes
        ..clear()
        ..addAll(newPriceFocusNodes);
      _promoPriceFocusNodes
        ..clear()
        ..addAll(newPromoPriceFocusNodes);

      if (_openDropdownIndex == index) {
        _openDropdownIndex = null;
      } else if (_openDropdownIndex != null && _openDropdownIndex! > index) {
        _openDropdownIndex = _openDropdownIndex! - 1;
      }
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_storeId == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check in to a store first')),
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

      final requestBody = {
        'store_id': _storeId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'origin_id': 2, // Principal
        'products': _products.map((product) => {
          'product_id': product.productId,
          'price': product.price,
          'is_promo': product.isPromo,
          'promo_price': product.promoPrice,
          'promo_start_date': product.promoStartDate != null 
              ? DateFormat('yyyy-MM-dd').format(product.promoStartDate!)
              : null,
          'promo_end_date': product.promoEndDate != null 
              ? DateFormat('yyyy-MM-dd').format(product.promoEndDate!)
              : null,
          'is_price_tag': product.isPriceTag,
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/reports/price'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price report submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorData['message'] ?? 'Failed to submit report'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
          'Price Principal Report',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
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
                    const SizedBox(height: 24),
                    _buildProductsSection(),
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submit price information for principal products',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
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
        // Remove Expanded here, as it causes layout issues in a Column
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
                    color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_products.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No products added yet. Tap "Add Product" to start.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...List.generate(_products.length, (index) {
            // Ensure controllers and focus nodes are initialized
            _priceControllers.putIfAbsent(index, () => TextEditingController());
            _promoPriceControllers.putIfAbsent(index, () => TextEditingController());
            _priceFocusNodes.putIfAbsent(index, () => FocusNode());
            _promoPriceFocusNodes.putIfAbsent(index, () => FocusNode());
            return _buildProductCard(index);
          }),
      ],
    );
  }

  Widget _buildProductCard(int index) {
    final product = _products[index];

    // Helper to format as Rupiah
    String formatRupiah(num? value) {
      if (value == null) return '0';
      return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }

    // Use persistent controllers and focus nodes
    final priceController = _priceControllers[index]!;
    final promoPriceController = _promoPriceControllers[index]!;
    final priceFocusNode = _priceFocusNodes[index]!;
    final promoPriceFocusNode = _promoPriceFocusNodes[index]!;

    // Set initial text only if controller is empty (avoid reset on every build)
    if (priceController.text.isEmpty && product.price != null && product.price! > 0) {
      priceController.text = formatRupiah(product.price);
    }
    if (promoPriceController.text.isEmpty && product.promoPrice != null && product.promoPrice! > 0) {
      promoPriceController.text = formatRupiah(product.promoPrice);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () => _removeProduct(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProductDropdown(product, index),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: priceController,
                  focusNode: priceFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    // Remove non-digit characters
                    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                    int? intValue = int.tryParse(digits);

                    // If promo price is filled, set price = price - promoPrice
                    if (intValue != null) {
                      if (product.promoPrice != null && product.promoPrice! > 0) {
                        product.price = intValue - product.promoPrice!;
                        if (product.price! < 0) product.price = 0;
                      } else {
                        product.price = intValue.toDouble();
                      }
                    } else {
                      product.price = 0;
                    }

                    // Update controller text with formatted value
                    final formatted = formatRupiah(intValue ?? 0);
                    if (priceController.text != formatted) {
                      priceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }

                    // Keep focus after formatting
                    if (!priceFocusNode.hasFocus) {
                      priceFocusNode.requestFocus();
                    }

                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || value == '0') {
                      return 'Price is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: promoPriceController,
                  focusNode: promoPriceFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Promo Price',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                    int? intValue = int.tryParse(digits);
                    if (intValue != null) {
                      product.promoPrice = intValue.toDouble();
                      // If price is filled, update price = price - promoPrice
                      if (product.price != null && product.price! > 0) {
                        product.price = product.price! - intValue;
                        if (product.price! < 0) product.price = 0;
                      }
                    } else {
                      product.promoPrice = 0;
                    }
                    final formatted = formatRupiah(intValue ?? 0);
                    if (promoPriceController.text != formatted) {
                      promoPriceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }

                    // Keep focus after formatting
                    if (!promoPriceFocusNode.hasFocus) {
                      promoPriceFocusNode.requestFocus();
                    }

                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPromoDateField(product, 'Promo Start Date'),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildPromoDateField(product, 'Promo End Date')),
            ],
          ),
          const SizedBox(height: 16),
          // Improved Switch UI for "Is Promo" and "Is Price Tag"
          Row(
            children: [
              Expanded(
                child: _buildCustomSwitchField(
                  product,
                  isPromo: true,
                  onChanged: (value) => setState(() => product.isPromo = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomSwitchField(
                  product,
                  isPromo: false,
                  onChanged: (value) => setState(() => product.isPriceTag = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(PriceProductData product, int index) {
    final isDropdownOpen = _openDropdownIndex == index;
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
                    if (isDropdownOpen) {
                      _openDropdownIndex = null;
                    } else {
                      _openDropdownIndex = index;
                      _productsController.clear();
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
                              ? _allProducts
                                    .firstWhere(
                                      (p) => p.id == product.productId,
                                      orElse: () => _allProducts.isNotEmpty
                                          ? _allProducts.first
                                          : ProductData(
                                              id: 0,
                                              name: '',
                                              code: '',
                                              subbrand: SubbrandData(
                                                id: 0,
                                                name: '',
                                              ),
                                            ),
                                    )
                                    .name
                              : 'Search and select product...',
                          style: TextStyle(
                            fontSize: 14,
                            color: product.productId != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isDropdownOpen
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
              if (isDropdownOpen)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _productsController,
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
              if (isDropdownOpen && _filteredProducts.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, idx) {
                      final p = _filteredProducts[idx];
                      final isSelected = product.productId == p.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            product.productId = p.id;
                            _openDropdownIndex = null;
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
              if (isDropdownOpen &&
                  _filteredProducts.isEmpty &&
                  _productsController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No products found for "${_productsController.text}"',
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


  Widget _buildPromoDateField(PriceProductData product, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                if (label.contains('Start')) {
                  product.promoStartDate = date;
                } else {
                  product.promoEndDate = date;
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  label.contains('Start')
                      ? (product.promoStartDate != null
                          ? DateFormat('dd MMM yyyy').format(product.promoStartDate!)
                          : 'Select Start Date')
                      : (product.promoEndDate != null
                          ? DateFormat('dd MMM yyyy').format(product.promoEndDate!)
                          : 'Select End Date'),
                  style: TextStyle(
                    fontSize: 14,
                    color: (label.contains('Start') ? product.promoStartDate : product.promoEndDate) != null 
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

  // Improved custom switch field for "Is Promo" and "Is Price Tag"
  Widget _buildCustomSwitchField(
    PriceProductData product, {
    required bool isPromo,
    required Function(bool) onChanged,
  }) {
    final value = isPromo ? product.isPromo : product.isPriceTag;
    final activeColor = isPromo ? Colors.orange[600]! : Colors.blue[600]!;
    final borderColor = isPromo ? Colors.orange[200]! : Colors.blue[200]!;
    final icon = isPromo ? Icons.local_offer : Icons.price_check;
    final label = isPromo ? "Is Promo" : "Is Price Tag";
    final enabledText = "Enabled";

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.13) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? activeColor : borderColor,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: value ? activeColor : (isPromo ? Colors.orange[900] : Colors.blue[900]),
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  decoration: BoxDecoration(
                    color: value ? activeColor : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                // Switch
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: value
                            ? activeColor.withOpacity(0.8)
                            : Colors.grey[300],
                      ),
                      child: Align(
                        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: value ? Colors.white : Colors.grey[100],
                            border: Border.all(
                              color: value ? activeColor : Colors.grey[400]!,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            value ? Icons.check : Icons.close,
                            size: 18,
                            color: value ? activeColor : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Enabled text
            Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  enabledText,
                  style: TextStyle(
                    fontSize: 14,
                    color: value ? activeColor : (isPromo ? Colors.orange[700] : Colors.blue[700]),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
                'Submit Price Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// Data models

class ProductData {
  final int id;
  final String name;
  final String code;
  final SubbrandData subbrand;

  ProductData({
    required this.id,
    required this.name,
    required this.code,
    required this.subbrand,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      subbrand: SubbrandData.fromJson(json['subbrand'] ?? {}),
    );
  }
}

class SubbrandData {
  final int id;
  final String name;

  SubbrandData({required this.id, required this.name});

  factory SubbrandData.fromJson(Map<String, dynamic> json) {
    return SubbrandData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class PriceProductData {
  int? productId;
  double? price;
  bool isPromo = false;
  double? promoPrice;
  DateTime? promoStartDate;
  DateTime? promoEndDate;
  bool isPriceTag = false;

  PriceProductData();
}
