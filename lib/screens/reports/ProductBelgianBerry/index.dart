import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_completion_service.dart';

class ProductBelgianBerryReportScreen extends StatefulWidget {
  const ProductBelgianBerryReportScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });
  final int storeId;
  final String storeName;

  @override
  State<ProductBelgianBerryReportScreen> createState() =>
      _ProductBelgianBerryReportScreenState();
}

class _ProductBelgianBerryReportScreenState
    extends State<ProductBelgianBerryReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime? _selectedDate;
  int? _finalStock;
  int? _manySellToday;
  DateTime? _expiredDate;
  String _description = '';

  // Controllers
  final TextEditingController _finalStockController = TextEditingController();
  final TextEditingController _manySellTodayController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // UI state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _finalStockController.dispose();
    _manySellTodayController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _expiredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
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

      // Create multipart request for form-data
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/reports/product-belgian-berry'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['store_id'] = widget.storeId.toString();
      request.fields['final_stock'] = _finalStock.toString();
      request.fields['many_sell_today'] = _manySellToday.toString();
      request.fields['expired_date'] = DateFormat('yyyy-MM-dd').format(_expiredDate!);
      request.fields['description'] = _description;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save completion status to local storage
        final submissionTime = DateTime.now();
        await ReportCompletionService.markReportCompleted(
          storeId: widget.storeId,
          reportType: 'product_belgian_berry',
          date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          completedAt: submissionTime,
          reportData: {
            'finalStock': _finalStock,
            'manySellToday': _manySellToday,
            'expiredDate': DateFormat('yyyy-MM-dd').format(_expiredDate!),
            'description': _description,
            'submittedAt': submissionTime.toIso8601String(),
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product Belgian Berry report submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful submission
      } else {
        final errorData = jsonDecode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${errorData['message'] ?? 'Failed to submit report'}',
            ),
          ),
        );
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
          'Product Belgian Berry Report',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.brown[600],
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
                    const SizedBox(height: 16),
                    _buildFinalStockField(),
                    const SizedBox(height: 16),
                    _buildManySellTodayField(),
                    const SizedBox(height: 16),
                    _buildExpiredDateField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
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
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.brown[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submit Product Belgian Berry report with stock and sales information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.brown[800],
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

  Widget _buildFinalStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Final Stock *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _finalStockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter final stock quantity',
            prefixIcon: Icon(Icons.inventory, color: Colors.brown),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _finalStock = int.tryParse(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Final stock is required';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildManySellTodayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Many Sell Today *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _manySellTodayController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter quantity sold today',
            prefixIcon: Icon(Icons.shopping_cart, color: Colors.brown),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _manySellToday = int.tryParse(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Many sell today is required';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExpiredDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expired Date *',
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
              initialDate: _expiredDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _expiredDate = date;
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
                Icon(Icons.event_busy, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _expiredDate != null
                      ? DateFormat('dd MMM yyyy').format(_expiredDate!)
                      : 'Select Expired Date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _expiredDate != null
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

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter description (optional)',
            prefixIcon: Icon(Icons.description, color: Colors.brown),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _description = value;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[600],
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
                'Submit Product Belgian Berry Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
