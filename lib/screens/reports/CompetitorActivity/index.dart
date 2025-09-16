import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'dart:io';
import '../../../models/competitor_activity.dart';
import '../../../services/competitor_activity_service.dart';
import '../../../widgets/cute_loading_widget.dart';

class CompetitorActivityScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const CompetitorActivityScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<CompetitorActivityScreen> createState() => _CompetitorActivityScreenState();
}

class _CompetitorActivityScreenState extends State<CompetitorActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promoMechanismController = TextEditingController();
  final _productsController = TextEditingController();

  // Form data
  int? _selectedPrincipalId;
  int? _selectedTypePromotionId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isAdditionalDisplay = false;
  bool _isPosm = false;
  int? _selectedTypeAdditionalId;
  int? _selectedTypePosmId;
  List<int> _selectedProducts = [];
  XFile? _selectedImage;

  // API data
  List<TypePromotion> _typePromotions = [];
  List<TypeAdditional> _typeAdditionals = [];
  List<TypePosm> _typePosms = [];
  List<ProductPrincipal> _productPrincipals = [];
  List<ProductPrincipal> _filteredProducts = [];
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
    _promoMechanismController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load all required data in parallel
      final futures = await Future.wait([
        CompetitorActivityService.getTypePromotions(),
        CompetitorActivityService.getTypeAdditionals(),
        CompetitorActivityService.getTypePosms(),
        CompetitorActivityService.getProductPrincipals(originId: 1),
      ]);

      setState(() {
        _typePromotions = (futures[0] as TypePromotionResponse).data;
        _typeAdditionals = (futures[1] as TypeAdditionalResponse).data;
        _typePosms = (futures[2] as TypePosmResponse).data;
        _productPrincipals = (futures[3] as ProductPrincipalResponse).data;
        _filteredProducts = (futures[3] as ProductPrincipalResponse).data;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(translate('gallery')),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(translate('camera')),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = source == ImageSource.camera
          ? await CompetitorActivityService.pickImageFromCamera()
          : await CompetitorActivityService.pickImageFromGallery();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_selectedStartDate ?? DateTime.now()) : (_selectedEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(translate('selectProducts')),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _productPrincipals.length,
                  itemBuilder: (context, index) {
                    final product = _productPrincipals[index];
                    final isSelected = _selectedProducts.contains(product.id);
                    
                    return CheckboxListTile(
                      title: Text(product.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedProducts.add(product.id);
                          } else {
                            _selectedProducts.remove(product.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: Text(translate('done')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _productPrincipals;
      } else {
        _filteredProducts = _productPrincipals.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      // Keep dropdown open when filtering
      if (!_isDropdownOpen && query.isNotEmpty) {
        _isDropdownOpen = true;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPrincipalId == null) {
      _showErrorSnackBar(translate('pleaseSelectAPrincipal'));
      return;
    }

    if (_selectedTypePromotionId == null) {
      _showErrorSnackBar(translate('pleaseSelectATypePromotion'));
      return;
    }

    if (_selectedStartDate == null) {
      _showErrorSnackBar(translate('pleaseSelectStartDate'));
      return;
    }

    if (_selectedEndDate == null) {
      _showErrorSnackBar(translate('pleaseSelectEndDate'));
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar(translate('pleaseSelectAtLeastOneProduct'));
      return;
    }

    if (_isAdditionalDisplay && _selectedTypeAdditionalId == null) {
      _showErrorSnackBar(translate('pleaseSelectAdditionalDisplayType'));
      return;
    }

    if (_isPosm && _selectedTypePosmId == null) {
      _showErrorSnackBar(translate('pleaseSelectPOSMType'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await CompetitorActivityService.submitCompetitorActivity(
        principalId: _selectedPrincipalId!,
        storeId: widget.storeId,
        typePromotionId: _selectedTypePromotionId!,
        promoMechanism: _promoMechanismController.text.trim(),
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
        isAdditionalDisplay: _isAdditionalDisplay,
        isPosm: _isPosm,
        image: _selectedImage,
        products: _selectedProducts,
        typeAdditionalId: _isAdditionalDisplay ? _selectedTypeAdditionalId : null,
        typePosmId: _isPosm ? _selectedTypePosmId : null,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        _showSuccessSnackBar(translate('competitorActivitySubmittedSuccessfully'));
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(translate('errorSubmittingForm') + ': $e');
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
          title: Text(translate('competitorActivity')),
          backgroundColor: const Color(0xFF29BDCE),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CuteLoadingWidget(
            message: translate('loadingData'),
            size: 80,
            primaryColor: Color(0xFF29BDCE),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('competitorActivity')),
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
                            Text(
                              translate('store'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.storeName,
                              style: TextStyle(
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

              // Principal selection
              _buildDropdownField(
                label: translate('principal') + ' *',
                value: _selectedPrincipalId,
                items: _productPrincipals.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPrincipalId = value;
                  });
                },
              ),

              // Type promotion selection
              _buildDropdownField(
                label: translate('typePromotion') + ' *',
                value: _selectedTypePromotionId,
                items: _typePromotions.map((t) => DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypePromotionId = value;
                  });
                },
              ),

              // Promo mechanism
              _buildTextFormField(
                label: translate('promoMechanism') + ' *',
                controller: _promoMechanismController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return translate('pleaseEnterPromoMechanism');
                  }
                  return null;
                },
              ),

              // Date selection
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: translate('startDate') + ' *',
                      date: _selectedStartDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: translate('endDate') + ' *',
                      date: _selectedEndDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Products selection
              _buildProductsField(),

              const SizedBox(height: 16),

              // Additional display toggle
              _buildToggleField(
                label: translate('additionalDisplay'),
                value: _isAdditionalDisplay,
                onChanged: (value) {
                  setState(() {
                    _isAdditionalDisplay = value;
                    if (!value) {
                      _selectedTypeAdditionalId = null;
                    }
                  });
                },
              ),

              // Type additional selection (conditional)
              if (_isAdditionalDisplay)
                _buildDropdownField(
                  label: translate('typeAdditional') + ' *',
                  value: _selectedTypeAdditionalId,
                  items: _typeAdditionals.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTypeAdditionalId = value;
                    });
                  },
                ),

              const SizedBox(height: 16),

              // POSM toggle
              _buildToggleField(
                label: translate('posm'),
                value: _isPosm,
                onChanged: (value) {
                  setState(() {
                    _isPosm = value;
                    if (!value) {
                      _selectedTypePosmId = null;
                    }
                  });
                },
              ),

              // Type POSM selection (conditional)
              if (_isPosm)
                _buildDropdownField(
                  label: translate('typePosm') + ' *',
                  value: _selectedTypePosmId,
                  items: _typePosms.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTypePosmId = value;
                    });
                  },
                ),

              const SizedBox(height: 16),

              // Image selection
              _buildImageField(),

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
                      : Text(
                          translate('submitCompetitorActivity'),
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

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
  }) {
    if (label.contains('Product')) {
      // Special handling for Product dropdown with integrated search
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
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
                              _selectedProducts.isNotEmpty
                                ? '${_selectedProducts.length} ${translate('product')}(s) ${translate('selected')}'
                                : 'Search and select products...',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedProducts.isNotEmpty ? Colors.black87 : Colors.grey[600],
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
                        controller: _productsController,
                        decoration: InputDecoration(
                          hintText: translate('typeToSearchProducts') + '...',
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
                          final product = _filteredProducts[index];
                          final isSelected = _selectedProducts.contains(product.id);
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedProducts.remove(product.id);
                                } else {
                                  _selectedProducts.add(product.id);
                                }
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
                                          product.name,
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
                                          'ID: ${product.id} • Origin: ${product.originId}',
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
                  if (_isDropdownOpen && _filteredProducts.isEmpty && _productsController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        translate('noProductsFoundFor') + ' "${_productsController.text}"',
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
        ),
      );
    } else {
      // Regular dropdown for non-Product fields
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  isExpanded: true,
                  hint: Text(translate('select') + ' ${label.replaceAll('*', '').trim()}'),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
          TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: date != null ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleField({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF29BDCE),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('products') + ' *',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showProductSelectionDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedProducts.isEmpty
                          ? translate('selectProducts')
                          : '${_selectedProducts.length} ${translate('product')}(s) ${translate('selected')}',
                      style: TextStyle(
                        color: _selectedProducts.isEmpty ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_selectedProducts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedProducts.map((productId) {
                final product = _productPrincipals.firstWhere((p) => p.id == productId);
                return Chip(
                  label: Text(product.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedProducts.remove(productId);
                    });
                  },
                  backgroundColor: const Color(0xFF29BDCE).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color(0xFF29BDCE),
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('photo') + ' (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          translate('tapToAddPhoto'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
