import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format with thousand separators
    String formatted = _formatRupiah(digitsOnly);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatRupiah(String value) {
    if (value.isEmpty) return '';
    
    // Add thousand separators
    String formatted = value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    
    return formatted;
  }
}

class SalesReportScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const SalesReportScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  DateTime? _selectedDate;
  bool _isCountStockAllowed = true;
  final TextEditingController _totalValueController = TextEditingController();
  
  // Product data
  List<Map<String, dynamic>> _allProducts = [];
  List<SalesItem> _salesItems = [];
  
  bool _isLoading = false;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadProducts();
  }

  @override
  void dispose() {
    _totalValueController.dispose();
    for (var item in _salesItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/stores/products?store_id=${widget.storeId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=== PRODUCTS RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
        setState(() {
            _allProducts = List<Map<String, dynamic>>.from(data['data']);
          });
          print('Loaded ${_allProducts.length} products');
        }
      }
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  void _addProduct() {
    if (_allProducts.isNotEmpty) {
          setState(() {
        _salesItems.add(SalesItem());
      });
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _salesItems[index].dispose();
      _salesItems.removeAt(index);
      _calculateTotalValue();
    });
  }

  void _calculateTotalValue() {
    double total = 0;
    for (var item in _salesItems) {
      final value = double.tryParse(_sanitizeRupiahInput(item.valueController.text)) ?? 0;
      total += value;
    }
    _totalValueController.text = _formatRupiah(total.toInt());
  }

  String _formatRupiah(int value) {
    if (value == 0) return '';
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(value);
  }

  String _sanitizeRupiahInput(String input) {
    // Remove all non-digit characters (dots, spaces, etc.)
    return input.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date')),
      );
      return;
    }

    if (_salesItems.isEmpty) {
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

      // Prepare items array
      List<Map<String, dynamic>> items = [];
      for (var item in _salesItems) {
        if (item.productId != null) {
          items.add({
            'product_id': item.productId,
            'opening_stock': int.tryParse(item.openingStockController.text) ?? 0,
            'sell_in': int.tryParse(item.sellInController.text) ?? 0,
            'return': int.tryParse(item.returnController.text) ?? 0,
            'closing_stock': int.tryParse(item.closingStockController.text) ?? 0,
            'sell_out': int.tryParse(item.sellOutController.text) ?? 0,
             'price_cbp': int.tryParse(_sanitizeRupiahInput(item.priceCbpController.text)) ?? 0,
             'value_cbp': int.tryParse(_sanitizeRupiahInput(item.valueCbpController.text)) ?? 0,
             'price_promo': int.tryParse(_sanitizeRupiahInput(item.pricePromoController.text)) ?? 0,
             'value_promo': int.tryParse(_sanitizeRupiahInput(item.valuePromoController.text)) ?? 0,
             'promo_start_date': item.promoStartDate != null ? DateFormat('yyyy-MM-dd').format(item.promoStartDate!) : '',
             'value': int.tryParse(_sanitizeRupiahInput(item.valueController.text)) ?? 0,
          });
        }
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'store_id': widget.storeId,
        'is_count_stock_allowed': _isCountStockAllowed,
         'value': int.tryParse(_sanitizeRupiahInput(_totalValueController.text)) ?? 0,
        'items': items,
      };

      print('=== SALES REQUEST ===');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/reports/sales'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('=== SALES RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales report submitted successfully!'),
              backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            ),
          );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        try {
          final errorData = jsonDecode(response.body);
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
          'Sales Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF29BDCE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              _buildHeader(),
                    const SizedBox(height: 20),
              _buildStoreInfo(),
                    const SizedBox(height: 20),
              _buildBasicFields(),
                    const SizedBox(height: 20),
              _buildProductsSection(),
              const SizedBox(height: 24),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF29BDCE), Color(0xFF1E9BA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sales Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.store, color: Color(0xFF29BDCE)),
            const SizedBox(width: 12),
            Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  const Text(
                    'Store Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
          Text(
                    widget.storeName,
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
    );
  }

  Widget _buildBasicFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF29BDCE)),
                const SizedBox(width: 8),
                const Text(
                  'Basic Information',
                  style: TextStyle(
              fontWeight: FontWeight.bold,
                    fontSize: 16,
            ),
                ),
              ],
          ),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 16),
            _buildCountStockAllowedField(),
          const SizedBox(height: 16),
            _buildTotalValueField(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                const Icon(Icons.inventory, color: Color(0xFF29BDCE)),
                const SizedBox(width: 8),
                const Text(
                  'Product Items',
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                    fontSize: 16,
                ),
              ),
                const Spacer(),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            if (_isLoadingProducts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_salesItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No products added yet',
                style: TextStyle(
                  color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add Product" to start adding items',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
              ),
            )
          else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _salesItems.length,
                itemBuilder: (context, index) {
                  return _buildSalesItem(_salesItems[index], index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesItem(SalesItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Product ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  fontSize: 16,
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeProduct(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Remove Product',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProductDropdown(item),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildNumberField('Opening Stock', item.openingStockController, '0')),
              const SizedBox(width: 12),
              Expanded(child: _buildNumberField('Sell In', item.sellInController, '0')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildNumberField('Return', item.returnController, '0')),
              const SizedBox(width: 12),
              Expanded(child: _buildNumberField('Closing Stock', item.closingStockController, '0')),
            ],
          ),
          const SizedBox(height: 12),
          _buildNumberField('Sell Out', item.sellOutController, '0'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCurrencyField('Price CBP', item.priceCbpController, '0')),
              const SizedBox(width: 12),
              Expanded(child: _buildCurrencyField('Value CBP', item.valueCbpController, '0')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCurrencyField('Price Promo', item.pricePromoController, '0')),
              const SizedBox(width: 12),
              Expanded(child: _buildCurrencyField('Value Promo', item.valuePromoController, '0')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPromoDateField(item)),
              const SizedBox(width: 12),
              Expanded(child: _buildCurrencyField('Total Value', item.valueController, '0')),
            ],
              ),
            ],
          ),
    );
  }

  Widget _buildProductDropdown(SalesItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        const Text(
          'Product *',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownButtonFormField<int>(
              value: item.productId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              hint: const Text('Select Product'),
              isExpanded: true, // Make dropdown expand to full width
              items: _allProducts.map((product) {
                return DropdownMenuItem<int>(
                  value: product['id'],
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 50, // Account for padding and icon
                    ),
                    child: Text(
                      '${product['name']} (${product['code']})',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  item.productId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a product';
                }
                return null;
              },
            );
          },
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
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
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
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                        : 'Select Date',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey[600],
                    ),
                ),
          ),
        ],
      ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountStockAllowedField() {
    return SwitchListTile(
      title: const Text('Count Stock Allowed'),
      subtitle: const Text('Enable stock counting for this report'),
      value: _isCountStockAllowed,
      onChanged: (value) {
        setState(() {
          _isCountStockAllowed = value;
        });
      },
      activeColor: const Color(0xFF29BDCE),
    );
  }

  Widget _buildTotalValueField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
                  'Total Value',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _totalValueController,
          keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
          decoration: InputDecoration(
            hintText: 'Enter total value',
            prefixText: 'Rp ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          readOnly: true,
          onTap: _calculateTotalValue,
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, String hint) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
          label,
            style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
                  ),
                  const SizedBox(height: 8),
        TextFormField(
          controller: controller,
      keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyField(String label, TextEditingController controller, String hint) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Text(
          label,
            style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
                  ),
                  const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
          decoration: InputDecoration(
            hintText: hint,
            prefixText: 'Rp ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          onChanged: (value) => _calculateTotalValue(),
                    ),
                  ],
                );
  }

  Widget _buildPromoDateField(SalesItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
        const Text(
          'Promo Start Date',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: item.promoStartDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                item.promoStartDate = date;
              });
            }
          },
                        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.promoStartDate != null
                        ? DateFormat('yyyy-MM-dd').format(item.promoStartDate!)
                        : 'Select Date',
                    style: TextStyle(
                      color: item.promoStartDate != null ? Colors.black : Colors.grey[600],
                        ),
            ),
          ),
        ],
      ),
            ),
          ),
        ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
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
                'Submit Sales Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class SalesItem {
  int? productId;
  DateTime? promoStartDate;
  
  final TextEditingController openingStockController = TextEditingController();
  final TextEditingController sellInController = TextEditingController();
  final TextEditingController returnController = TextEditingController();
  final TextEditingController closingStockController = TextEditingController();
  final TextEditingController sellOutController = TextEditingController();
  final TextEditingController priceCbpController = TextEditingController();
  final TextEditingController valueCbpController = TextEditingController();
  final TextEditingController pricePromoController = TextEditingController();
  final TextEditingController valuePromoController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  void dispose() {
    openingStockController.dispose();
    sellInController.dispose();
    returnController.dispose();
    closingStockController.dispose();
    sellOutController.dispose();
    priceCbpController.dispose();
    valueCbpController.dispose();
    pricePromoController.dispose();
    valuePromoController.dispose();
    valueController.dispose();
  }
}