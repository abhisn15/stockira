import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';

// Custom formatter for Rupiah currency
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
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format with thousand separators
    String formatted = _formatNumber(digitsOnly);
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(String value) {
    // Reverse the string to add separators from right to left
    String reversed = value.split('').reversed.join('');
    String formatted = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }
    
    // Reverse back to original order
    return formatted.split('').reversed.join('');
  }
}

class PromoTrackingReportScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const PromoTrackingReportScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<PromoTrackingReportScreen> createState() => _PromoTrackingReportScreenState();
}

class _PromoTrackingReportScreenState extends State<PromoTrackingReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Form fields
  int? _selectedTypePromotionId;
  String _promoMechanism = 'Promo';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedDate; // Add date field for server requirement
  final TextEditingController _normalPriceController = TextEditingController();
  final TextEditingController _promoPriceController = TextEditingController();
  int? _selectedRangePromoId;
  int? _selectedTypeAdditionalId;
  int? _selectedTypePosmId;
  File? _selectedImage;
  
  bool _isLoading = false;
  
  // Dropdown data
  List<Map<String, dynamic>> _typePromotions = [];
  List<Map<String, dynamic>> _rangePromos = [];
  List<Map<String, dynamic>> _typeAdditionals = [];
  List<Map<String, dynamic>> _typePosms = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _normalPriceController.dispose();
    _promoPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;

      // Load all dropdown data in parallel
      final results = await Future.wait([
        _fetchTypePromotions(token),
        _fetchRangePromos(token),
        _fetchTypeAdditionals(token),
        _fetchTypePosms(token),
      ]);

      setState(() {
        _typePromotions = results[0];
        _rangePromos = results[1];
        _typeAdditionals = results[2];
        _typePosms = results[3];
      });
    } catch (e) {
      print('Error loading dropdown data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTypePromotions(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/type/promotion'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchRangePromos(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/helpers?conditions[code]=range_promo'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchTypeAdditionals(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/type/additional'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchTypePosms(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/type/posm'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTypePromotionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select type promotion')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date')),
      );
      return;
    }

    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date')),
      );
      return;
    }

    if (_selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end date')),
      );
      return;
    }

    if (_selectedRangePromoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select range promo')),
      );
      return;
    }

    if (_selectedTypeAdditionalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select type additional')),
      );
      return;
    }

    if (_selectedTypePosmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select type POSM')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select documentation image')),
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

      // Prepare form data
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/reports/promo-tracking'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['type_promotion_id'] = _selectedTypePromotionId.toString();
      request.fields['promo_mechanism'] = _promoMechanism;
      request.fields['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(_selectedStartDate!);
      request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(_selectedEndDate!);
      request.fields['normal_price'] = _normalPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      request.fields['promo_price'] = _promoPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      request.fields['range_promo_id'] = _selectedRangePromoId.toString();
      request.fields['type_additional_id'] = _selectedTypeAdditionalId.toString();
      request.fields['type_posm_id'] = _selectedTypePosmId.toString();
      request.fields['store_id'] = widget.storeId.toString();
      request.fields['product_id'] = '1'; // Default product_id as per server requirement

      // Add image file
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'documentation_image',
            _selectedImage!.path,
          ),
        );
      }

      print('=== PROMO TRACKING REQUEST ===');
      print('type_promotion_id: $_selectedTypePromotionId');
      print('promo_mechanism: $_promoMechanism');
      print('date: ${request.fields['date']}');
      print('start_date: ${request.fields['start_date']}');
      print('end_date: ${request.fields['end_date']}');
      print('normal_price: ${request.fields['normal_price']}');
      print('promo_price: ${request.fields['promo_price']}');
      print('range_promo_id: $_selectedRangePromoId');
      print('type_additional_id: $_selectedTypeAdditionalId');
      print('type_posm_id: $_selectedTypePosmId');
      print('store_id: ${request.fields['store_id']}');
      print('product_id: ${request.fields['product_id']}');
      print('documentation_image: ${_selectedImage?.path}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== PROMO TRACKING RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promo Tracking report submitted successfully!'),
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
          'Promo Tracking Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange,
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
              _buildTypePromotionDropdown(),
              const SizedBox(height: 16),
              _buildPromoMechanismField(),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildDateFields(),
              const SizedBox(height: 16),
              _buildPriceFields(),
              const SizedBox(height: 16),
              _buildRangePromoDropdown(),
              const SizedBox(height: 16),
              _buildTypeAdditionalDropdown(),
              const SizedBox(height: 16),
              _buildTypePosmDropdown(),
              const SizedBox(height: 16),
              _buildImageField(),
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
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Promo Tracking Report',
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
            Icon(Icons.store, color: Colors.orange[600]),
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

  Widget _buildTypePromotionDropdown() {
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
                Icon(Icons.category, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Type Promotion *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedTypePromotionId,
              decoration: InputDecoration(
                hintText: 'Select type promotion',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: _typePromotions.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypePromotionId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select type promotion';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoMechanismField() {
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
                Icon(Icons.settings, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Promo Mechanism',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _promoMechanism,
              decoration: InputDecoration(
                hintText: 'Enter promo mechanism',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                _promoMechanism = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter promo mechanism';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
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
                Icon(Icons.calendar_today, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Date *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  Widget _buildDateFields() {
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
                Icon(Icons.date_range, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Date Range *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerField(
                    'Start Date',
                    _selectedStartDate,
                    (date) {
                      setState(() {
                        _selectedStartDate = date;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePickerField(
                    'End Date',
                    _selectedEndDate,
                    (date) {
                      setState(() {
                        _selectedEndDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
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
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              onDateSelected(date);
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
                    selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDate)
                        : 'Select $label',
                    style: TextStyle(
                      color: selectedDate != null ? Colors.black : Colors.grey[600],
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

  Widget _buildPriceFields() {
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
                Icon(Icons.attach_money, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Price Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceField(
                    'Normal Price',
                    _normalPriceController,
                    'Enter normal price',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceField(
                    'Promo Price',
                    _promoPriceController,
                    'Enter promo price',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller, String hint) {
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
          inputFormatters: [
            RupiahInputFormatter(),
          ],
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label.toLowerCase()';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRangePromoDropdown() {
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
                Icon(Icons.location_on, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Range Promo *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedRangePromoId,
              decoration: InputDecoration(
                hintText: 'Select range promo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: _rangePromos.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRangePromoId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select range promo';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeAdditionalDropdown() {
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
                Icon(Icons.add_box, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Type Additional *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedTypeAdditionalId,
              decoration: InputDecoration(
                hintText: 'Select type additional',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: _typeAdditionals.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypeAdditionalId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select type additional';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePosmDropdown() {
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
                Icon(Icons.campaign, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Type POSM *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedTypePosmId,
              decoration: InputDecoration(
                hintText: 'Select type POSM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: _typePosms.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypePosmId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select type POSM';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageField() {
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
                Icon(Icons.image, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Documentation Image *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedImage != null ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedImage != null ? Colors.green[50] : Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedImage != null ? Icons.check_circle : Icons.add_photo_alternate,
                      color: _selectedImage != null ? Colors.green : Colors.grey,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImage != null ? 'Image Selected' : 'Tap to select image',
                      style: TextStyle(
                        color: _selectedImage != null ? Colors.green[700] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedImage!.path.split('/').last,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
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
                'Submit Promo Tracking Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
