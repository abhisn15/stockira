import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';

class RegularDisplayReportScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const RegularDisplayReportScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<RegularDisplayReportScreen> createState() => _RegularDisplayReportScreenState();
}

class _RegularDisplayReportScreenState extends State<RegularDisplayReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Form fields
  int? _selectedProductSubBrandId;
  int? _selectedTypeRegulerId;
  final TextEditingController _remarkController = TextEditingController();
  File? _selectedImageBefore;
  File? _selectedImageAfter;
  
  bool _isLoading = false;
  
  // Dropdown data
  List<Map<String, dynamic>> _productSubBrands = [];
  List<Map<String, dynamic>> _typeRegulers = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;

      // Load all dropdown data in parallel
      final results = await Future.wait([
        _fetchProductSubBrands(token),
        _fetchTypeRegulers(token),
      ]);

      setState(() {
        _productSubBrands = results[0];
        _typeRegulers = results[1];
      });
    } catch (e) {
      print('Error loading dropdown data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProductSubBrands(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/products/sub-brands'),
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

  Future<List<Map<String, dynamic>>> _fetchTypeRegulers(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/type/reguler'),
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

  Future<void> _pickImage(bool isBefore) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          if (isBefore) {
            _selectedImageBefore = File(image.path);
          } else {
            _selectedImageAfter = File(image.path);
          }
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

    if (_selectedProductSubBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select product sub brand')),
      );
      return;
    }

    if (_selectedTypeRegulerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select type reguler')),
      );
      return;
    }

    if (_selectedImageBefore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select documentation image before')),
      );
      return;
    }

    if (_selectedImageAfter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select documentation image after')),
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
        Uri.parse('${Env.apiBaseUrl}/reports/reguler-display'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['store_id'] = widget.storeId.toString();
      request.fields['product_sub_brand_id'] = _selectedProductSubBrandId.toString();
      request.fields['type_reguler_id'] = _selectedTypeRegulerId.toString();
      request.fields['remark'] = _remarkController.text;

      // Add image files
      if (_selectedImageBefore != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'documentation_image_before',
            _selectedImageBefore!.path,
          ),
        );
      }

      if (_selectedImageAfter != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'documentation_image_after',
            _selectedImageAfter!.path,
          ),
        );
      }

      print('=== REGULAR DISPLAY REQUEST ===');
      print('store_id: ${widget.storeId}');
      print('product_sub_brand_id: $_selectedProductSubBrandId');
      print('type_reguler_id: $_selectedTypeRegulerId');
      print('remark: ${_remarkController.text}');
      print('documentation_image_before: ${_selectedImageBefore?.path}');
      print('documentation_image_after: ${_selectedImageAfter?.path}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== REGULAR DISPLAY RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regular Display report submitted successfully!'),
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
          'Regular Display Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E9BA8),
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
              _buildProductSubBrandDropdown(),
              const SizedBox(height: 16),
              _buildTypeRegulerDropdown(),
              const SizedBox(height: 16),
              _buildRemarkField(),
              const SizedBox(height: 16),
              _buildImageFields(),
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
          colors: [const Color(0xFF1E9BA8).withOpacity(0.8), const Color(0xFF1E9BA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.storefront, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Regular Display Report',
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
            Icon(Icons.store, color: const Color(0xFF1E9BA8)),
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

  Widget _buildProductSubBrandDropdown() {
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
                Icon(Icons.branding_watermark, color: const Color(0xFF1E9BA8)),
                const SizedBox(width: 8),
                const Text(
                  'Product Sub Brand *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedProductSubBrandId,
              decoration: InputDecoration(
                hintText: 'Select product sub brand',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: _productSubBrands.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductSubBrandId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select product sub brand';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeRegulerDropdown() {
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
                Icon(Icons.category, color: const Color(0xFF1E9BA8)),
                const SizedBox(width: 8),
                const Text(
                  'Type Reguler *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedTypeRegulerId,
              decoration: InputDecoration(
                hintText: 'Select type reguler',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: _typeRegulers.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypeRegulerId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select type reguler';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarkField() {
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
                Icon(Icons.note, color: const Color(0xFF1E9BA8)),
                const SizedBox(width: 8),
                const Text(
                  'Remark',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarkController,
              decoration: InputDecoration(
                hintText: 'Enter remark',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter remark';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFields() {
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
                Icon(Icons.image, color: const Color(0xFF1E9BA8)),
                const SizedBox(width: 8),
                const Text(
                  'Documentation Images *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImageField('Before', _selectedImageBefore, true),
            const SizedBox(height: 16),
            _buildImageField('After', _selectedImageAfter, false),
          ],
        ),
      ),
    );
  }

  Widget _buildImageField(String label, File? selectedImage, bool isBefore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentation Image $label *',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(isBefore),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedImage != null ? Colors.green : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: selectedImage != null ? Colors.green[50] : Colors.grey[50],
            ),
            child: Column(
              children: [
                Icon(
                  selectedImage != null ? Icons.check_circle : Icons.add_photo_alternate,
                  color: selectedImage != null ? Colors.green : Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedImage != null ? 'Image $label Selected' : 'Tap to select image $label',
                  style: TextStyle(
                    color: selectedImage != null ? Colors.green[700] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedImage.path.split('/').last,
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
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E9BA8),
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
                'Submit Regular Display Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
