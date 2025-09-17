import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_completion_service.dart';

class SurveyReportScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const SurveyReportScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<SurveyReportScreen> createState() => _SurveyReportScreenState();
}

class _SurveyReportScreenState extends State<SurveyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Form controllers
  final TextEditingController _storeCodeController = TextEditingController();
  final TextEditingController _skuCountController = TextEditingController();
  final TextEditingController _poTotalAmountController = TextEditingController();
  final TextEditingController _poTotalDuzController = TextEditingController();
  final TextEditingController _constraintController = TextEditingController();
  
  // Date and dropdown fields
  DateTime? _selectedDate;
  int _selectedFreezerCount = 1;
  
  // Dynamic freezer forms - List of controllers for each freezer
  List<TextEditingController> _freezerIdControllers = [];
  List<TextEditingController> _freezerCountControllers = [];
  List<TextEditingController> _skuCountControllers = [];
  
  // Boolean fields with photos
  Map<String, bool> _booleanFields = {
    'exist_sticker_crispy_ball': false,
    'exist_sticker_mochi': false,
    'exist_sticker_sharing_olympic': false,
    'exist_price_board_olympic': false,
    'exist_wobler_promo': false,
    'exist_pop_promo': false,
    'exist_price_board_led': false,
    'exist_sticker_glass_mochi': false,
    'exist_sticker_frame_crispy_balls': false,
    'exist_freezer_backup': false,
    'exist_drum_freezer': false,
    'exist_crispy_balls_tier': false,
    'exist_product_focus_crispy_ball': false,
    'exist_product_focus_histeria_macha': false,
    'exist_product_focus_almond_choco': false,
    'exist_product_focus_almond_classic': false,
    'exist_product_focus_histeria_peach': false,
    'exist_product_focus_histeria_vanilla': false,
    'exist_po': false,
  };

  
  // Photo fields
  Map<String, File?> _photoFields = {
    'photo_idn_freezer_1': null,
    'photo_idn_freezer_2': null,
    'freezer_position_image': null,
    'photo_sticker_crispy_ball': null,
    'photo_sticker_mochi': null,
    'photo_sticker_sharing_olympic': null,
    'photo_price_board_olympic': null,
    'photo_wobler_promo': null,
    'photo_pop_promo': null,
    'photo_price_board_led': null,
    'photo_sticker_glass_mochi': null,
    'photo_sticker_frame_crispy_balls': null,
    'photo_freezer_backup': null,
    'photo_drum_freezer': null,
    'photo_crispy_balls_tier': null,
    'photo_promo_running': null,
  };
  
  // Uploaded image URLs
  Map<String, String?> _uploadedImageUrls = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeFreezerForms();
  }

  void _initializeFreezerForms() {
    // Clear existing controllers
    for (var controller in _freezerIdControllers) {
      controller.dispose();
    }
    for (var controller in _freezerCountControllers) {
      controller.dispose();
    }
    for (var controller in _skuCountControllers) {
      controller.dispose();
    }
    
    _freezerIdControllers.clear();
    _freezerCountControllers.clear();
    _skuCountControllers.clear();
    
    // Initialize controllers based on selected freezer count
    for (int i = 0; i < _selectedFreezerCount; i++) {
      _freezerIdControllers.add(TextEditingController());
      _freezerCountControllers.add(TextEditingController());
      _skuCountControllers.add(TextEditingController());
    }
  }

  void _onFreezerCountChanged(int newCount) {
    setState(() {
      _selectedFreezerCount = newCount;
      _initializeFreezerForms();
    });
  }


  @override
  void dispose() {
    _storeCodeController.dispose();
    _skuCountController.dispose();
    _poTotalAmountController.dispose();
    _poTotalDuzController.dispose();
    _constraintController.dispose();
    
    // Dispose all dynamic controllers
    for (var controller in _freezerIdControllers) {
      controller.dispose();
    }
    for (var controller in _freezerCountControllers) {
      controller.dispose();
    }
    for (var controller in _skuCountControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return null;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/upload'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields for upload API
      request.fields['width'] = '300';
      request.fields['height'] = '300';
      request.fields['folder'] = 'uploads';
      request.fields['quality'] = '80';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['data']['url']; // Assuming the response contains URL
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }

  Future<void> _pickImage(String fieldName) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _photoFields[fieldName] = File(image.path);
        });
        
        // Upload image immediately
        final imageUrl = await _uploadImage(File(image.path));
        if (imageUrl != null) {
          setState(() {
            _uploadedImageUrls[fieldName] = imageUrl;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date')),
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

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'store_id': widget.storeId,
        'type_store_id': 3,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'store_code': _storeCodeController.text,
        'freezer_count': _selectedFreezerCount,
        'sku_count': int.tryParse(_skuCountController.text) ?? 0,
        
        // Dynamic freezer ID fields based on selected count
      };
      
      // Add dynamic freezer fields
      for (int i = 0; i < _selectedFreezerCount; i++) {
        requestBody['no_idn_freezer_${i + 1}'] = _freezerIdControllers[i].text;
        requestBody['photo_idn_freezer_${i + 1}'] = _uploadedImageUrls['photo_idn_freezer_${i + 1}'] ?? '';
      }
      
      // Add other fields
      requestBody.addAll({
        // Freezer details
        'freezer_category_id': 5,
        'freezer_position_id': 6,
        'freezer_position_image': _uploadedImageUrls['freezer_position_image'] ?? '',
        'freezer_volume_id': 'VOL-123',
        
        // All boolean and photo fields
        'exist_sticker_crispy_ball': _booleanFields['exist_sticker_crispy_ball']!,
        'photo_sticker_crispy_ball': _uploadedImageUrls['photo_sticker_crispy_ball'] ?? '',
        'exist_sticker_mochi': _booleanFields['exist_sticker_mochi']!,
        'photo_sticker_mochi': _uploadedImageUrls['photo_sticker_mochi'] ?? '',
        'exist_sticker_sharing_olympic': _booleanFields['exist_sticker_sharing_olympic']!,
        'photo_sticker_sharing_olympic': _uploadedImageUrls['photo_sticker_sharing_olympic'] ?? '',
        'exist_price_board_olympic': _booleanFields['exist_price_board_olympic']!,
        'photo_price_board_olympic': _uploadedImageUrls['photo_price_board_olympic'] ?? '',
        'exist_wobler_promo': _booleanFields['exist_wobler_promo']!,
        'photo_wobler_promo': _uploadedImageUrls['photo_wobler_promo'] ?? '',
        'exist_pop_promo': _booleanFields['exist_pop_promo']!,
        'photo_pop_promo': _uploadedImageUrls['photo_pop_promo'] ?? '',
        'exist_price_board_led': _booleanFields['exist_price_board_led']!,
        'photo_price_board_led': _uploadedImageUrls['photo_price_board_led'] ?? '',
        'exist_sticker_glass_mochi': _booleanFields['exist_sticker_glass_mochi']!,
        'photo_sticker_glass_mochi': _uploadedImageUrls['photo_sticker_glass_mochi'] ?? '',
        'exist_sticker_frame_crispy_balls': _booleanFields['exist_sticker_frame_crispy_balls']!,
        'photo_sticker_frame_crispy_balls': _uploadedImageUrls['photo_sticker_frame_crispy_balls'] ?? '',
        'exist_freezer_backup': _booleanFields['exist_freezer_backup']!,
        'photo_freezer_backup': _uploadedImageUrls['photo_freezer_backup'] ?? '',
        'exist_drum_freezer': _booleanFields['exist_drum_freezer']!,
        'photo_drum_freezer': _uploadedImageUrls['photo_drum_freezer'] ?? '',
        'product_quality_id': 7,
        'exist_crispy_balls_tier': _booleanFields['exist_crispy_balls_tier']!,
        'photo_crispy_balls_tier': _uploadedImageUrls['photo_crispy_balls_tier'] ?? '',
        'exist_product_focus_crispy_ball': _booleanFields['exist_product_focus_crispy_ball']!,
        'exist_product_focus_histeria_macha': _booleanFields['exist_product_focus_histeria_macha']!,
        'exist_product_focus_almond_choco': _booleanFields['exist_product_focus_almond_choco']!,
        'exist_product_focus_almond_classic': _booleanFields['exist_product_focus_almond_classic']!,
        'exist_product_focus_histeria_peach': _booleanFields['exist_product_focus_histeria_peach']!,
        'exist_product_focus_histeria_vanilla': _booleanFields['exist_product_focus_histeria_vanilla']!,
        'photo_promo_running': _uploadedImageUrls['photo_promo_running'] ?? '',
        'exist_po': _booleanFields['exist_po']!,
        'po_total_amount': int.tryParse(_poTotalAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'po_total_duz': int.tryParse(_poTotalDuzController.text) ?? 0,
        'constraint': _constraintController.text,
      });

      print('=== SURVEY REQUEST ===');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/reports/survey'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('=== SURVEY RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save completion status to local storage
        final submissionTime = DateTime.now();
        await ReportCompletionService.markReportCompleted(
          storeId: widget.storeId,
          reportType: 'survey',
          date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          completedAt: submissionTime,
          reportData: {
            'typeStoreId': 3,
            'storeCode': _storeCodeController.text,
            'freezerCount': _selectedFreezerCount,
            'skuCount': int.tryParse(_skuCountController.text) ?? 0,
            'constraint': _constraintController.text,
            'submittedAt': submissionTime.toIso8601String(),
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey report submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful submission
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
          'Survey Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
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
              _buildFreezerFields(),
              const SizedBox(height: 20),
              _buildStickerFields(),
              const SizedBox(height: 20),
              _buildPromoFields(),
              const SizedBox(height: 20),
              _buildProductFocusFields(),
              const SizedBox(height: 20),
              _buildPOFields(),
              const SizedBox(height: 20),
              _buildConstraintField(),
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
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Survey Report',
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
            Icon(Icons.store, color: Colors.green[600]),
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
                Icon(Icons.info, color: Colors.green[600]),
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
            _buildFreezerCountDropdown(),
            const SizedBox(height: 16),
            _buildTextField('SKU Count', _skuCountController, 'Enter SKU count'),
            const SizedBox(height: 16),
            _buildFreezerFormsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFreezerFields() {
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
                Icon(Icons.kitchen, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Freezer Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPhotoField('freezer_position_image', 'Freezer Position Image'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_freezer_backup', 'photo_freezer_backup', 'Freezer Backup'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_drum_freezer', 'photo_drum_freezer', 'Drum Freezer'),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerFields() {
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
                Icon(Icons.label, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Stickers & Boards',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_sticker_crispy_ball', 'photo_sticker_crispy_ball', 'Sticker Crispy Ball'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_sticker_mochi', 'photo_sticker_mochi', 'Sticker Mochi'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_sticker_sharing_olympic', 'photo_sticker_sharing_olympic', 'Sticker Sharing Olympic'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_price_board_olympic', 'photo_price_board_olympic', 'Price Board Olympic'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_price_board_led', 'photo_price_board_led', 'Price Board LED'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_sticker_glass_mochi', 'photo_sticker_glass_mochi', 'Sticker Glass Mochi'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_sticker_frame_crispy_balls', 'photo_sticker_frame_crispy_balls', 'Sticker Frame Crispy Balls'),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoFields() {
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
                Icon(Icons.local_offer, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Promo Materials',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_wobler_promo', 'photo_wobler_promo', 'Wobler Promo'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_pop_promo', 'photo_pop_promo', 'POP Promo'),
            const SizedBox(height: 16),
            _buildBooleanWithPhotoField('exist_crispy_balls_tier', 'photo_crispy_balls_tier', 'Crispy Balls Tier'),
            const SizedBox(height: 16),
            _buildPhotoField('photo_promo_running', 'Promo Running Photo'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFocusFields() {
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
                Icon(Icons.center_focus_strong, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Product Focus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBooleanField('exist_product_focus_crispy_ball', 'Crispy Ball'),
            const SizedBox(height: 12),
            _buildBooleanField('exist_product_focus_histeria_macha', 'Histeria Macha'),
            const SizedBox(height: 12),
            _buildBooleanField('exist_product_focus_almond_choco', 'Almond Choco'),
            const SizedBox(height: 12),
            _buildBooleanField('exist_product_focus_almond_classic', 'Almond Classic'),
            const SizedBox(height: 12),
            _buildBooleanField('exist_product_focus_histeria_peach', 'Histeria Peach'),
            const SizedBox(height: 12),
            _buildBooleanField('exist_product_focus_histeria_vanilla', 'Histeria Vanilla'),
          ],
        ),
      ),
    );
  }

  Widget _buildPOFields() {
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
                Icon(Icons.receipt, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Purchase Order (PO)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBooleanField('exist_po', 'Exist PO'),
            const SizedBox(height: 16),
            _buildCurrencyField('PO Total Amount', _poTotalAmountController, 'Enter PO total amount'),
            const SizedBox(height: 16),
            _buildNumberField('PO Total Duz', _poTotalDuzController, 'Enter PO total duz'),
          ],
        ),
      ),
    );
  }

  Widget _buildConstraintField() {
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
                Icon(Icons.note, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Constraint',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _constraintController,
              decoration: InputDecoration(
                hintText: 'Enter constraint',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 3,
            ),
          ],
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

  Widget _buildTextField(String label, TextEditingController? controller, String hint) {
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

  Widget _buildNumberField(String label, TextEditingController? controller, String hint) {
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

  Widget _buildCurrencyField(String label, TextEditingController? controller, String hint) {
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          onChanged: (value) {
            // Format the display value with dots (12.000)
            String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.isNotEmpty) {
              String formatted = digits.replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              );
              if (controller != null && controller.text != formatted) {
                controller.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            }
          },
        ),
      ],
    );
  }



  String _getPhotoFieldName(String booleanFieldName) {
    // Map boolean field names to their corresponding photo field names
    switch (booleanFieldName) {
      case 'exist_freezer_backup':
        return 'photo_freezer_backup';
      case 'exist_drum_freezer':
        return 'photo_drum_freezer';
      case 'exist_sticker_crispy_ball':
        return 'photo_sticker_crispy_ball';
      case 'exist_sticker_mochi':
        return 'photo_sticker_mochi';
      case 'exist_sticker_sharing_olympic':
        return 'photo_sticker_sharing_olympic';
      case 'exist_price_board_olympic':
        return 'photo_price_board_olympic';
      case 'exist_wobler_promo':
        return 'photo_wobler_promo';
      case 'exist_pop_promo':
        return 'photo_pop_promo';
      case 'exist_price_board_led':
        return 'photo_price_board_led';
      case 'exist_sticker_glass_mochi':
        return 'photo_sticker_glass_mochi';
      case 'exist_sticker_frame_crispy_balls':
        return 'photo_sticker_frame_crispy_balls';
      case 'exist_crispy_balls_tier':
        return 'photo_crispy_balls_tier';
      default:
        return 'photo_${booleanFieldName.replaceAll('exist_', '')}';
    }
  }

  Widget _buildBooleanField(String fieldName, String label) {
    return SwitchListTile(
      title: Text(label),
      value: _booleanFields[fieldName]!,
      onChanged: (value) {
        setState(() {
          _booleanFields[fieldName] = value;
          // Clear photo when boolean is disabled
          if (!value) {
            final photoFieldName = _getPhotoFieldName(fieldName);
            _photoFields[photoFieldName] = null;
            _uploadedImageUrls.remove(photoFieldName);
          }
        });
      },
      activeThumbColor: Colors.green,
    );
  }


  Widget _buildBooleanWithPhotoField(String booleanField, String photoField, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBooleanField(booleanField, label),
        if (_booleanFields[booleanField] == true) ...[
          const SizedBox(height: 8),
          _buildPhotoField(photoField, '$label Photo'),
        ],
      ],
    );
  }


  Widget _buildPhotoField(String fieldName, String label) {
    final selectedImage = _photoFields[fieldName];
    final isUploaded = _uploadedImageUrls[fieldName] != null;
    
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
          onTap: () => _pickImage(fieldName),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isUploaded ? Colors.green : (selectedImage != null ? Colors.orange : Colors.grey),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isUploaded ? Colors.green[50] : (selectedImage != null ? Colors.orange[50] : Colors.grey[50]),
            ),
            child: Column(
              children: [
                Icon(
                  isUploaded ? Icons.cloud_done : (selectedImage != null ? Icons.cloud_upload : Icons.add_photo_alternate),
                  color: isUploaded ? Colors.green : (selectedImage != null ? Colors.orange : Colors.grey),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  isUploaded ? 'Uploaded' : (selectedImage != null ? 'Uploading...' : 'Tap to select'),
                  style: TextStyle(
                    color: isUploaded ? Colors.green[700] : (selectedImage != null ? Colors.orange[700] : Colors.grey[600]),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreezerCountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Freezer Count *',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedFreezerCount,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          hint: const Text('Select freezer count'),
          items: List.generate(5, (index) => index + 1).map((count) {
            return DropdownMenuItem<int>(
              value: count,
              child: Text('$count Freezer${count > 1 ? 's' : ''}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _onFreezerCountChanged(value);
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Please select freezer count';
            }
            return null;
          },
        ),
      ],
    );
  }


  Widget _buildFreezerFormsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Freezer Forms (${_selectedFreezerCount} freezers)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_selectedFreezerCount, (index) {
          return _buildFreezerForm(index);
        }),
      ],
    );
  }

  Widget _buildFreezerForm(int index) {
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
                'Freezer ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Freezer ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('Freezer ${index + 1} ID', _freezerIdControllers[index], 'Enter freezer ${index + 1} ID'),
          const SizedBox(height: 8),
          _buildPhotoField('photo_idn_freezer_${index + 1}', 'Freezer ${index + 1} Photo'),
        ],
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
          backgroundColor: Colors.green,
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
                'Submit Survey Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}