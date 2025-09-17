import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/activity_other_service.dart';

class ActivityOtherScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const ActivityOtherScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<ActivityOtherScreen> createState() => _ActivityOtherScreenState();
}

class _ActivityOtherScreenState extends State<ActivityOtherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  // State variables
  List<String> _selectedApproves = [];
  XFile? _documentationImageFirst;
  XFile? _documentationImageSecond;
  XFile? _documentationImageThird;
  bool _isSubmitting = false;

  // Available approve options
  final List<String> _approveOptions = ['RSM', 'AM', 'SM', 'DM'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          switch (imageType) {
            case 'first':
              _documentationImageFirst = image;
              break;
            case 'second':
              _documentationImageSecond = image;
              break;
            case 'third':
              _documentationImageThird = image;
              break;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedApproves.isEmpty) {
      _showSnackBar('Pilih minimal satu persetujuan', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ActivityOtherService.submitActivityOther(
        activityName: _activityNameController.text.trim(),
        approves: _selectedApproves,
        storeId: widget.storeId,
        documentationImageFirst: _documentationImageFirst,
        documentationImageSecond: _documentationImageSecond,
        documentationImageThird: _documentationImageThird,
      );

      if (response.success) {
        _showSnackBar(response.message, Colors.green);
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar(response.message, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error submitting report: $e', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kegiatan Lain-lain',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF9C27B0), // Purple theme
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Info Card
              _buildStoreInfoCard(),
              const SizedBox(height: 16),

              // Activity Name Field
              _buildActivityNameField(),
              const SizedBox(height: 16),

              // Approves Selection
              _buildApprovesSelection(),
              const SizedBox(height: 16),

              // Documentation Images
              _buildDocumentationImages(),
              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: const Color(0xFF9C27B0),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  translate('storeInformation'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${translate('storeName')}: ${widget.storeName}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${translate('storeId')}: ${widget.storeId}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityNameField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Kegiatan *',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _activityNameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kegiatan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.event_note),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kegiatan harus diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovesSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Persetujuan *',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 26,
              runSpacing: 26,
              children: _approveOptions.map((approve) {
                final isSelected = _selectedApproves.contains(approve);
                return FilterChip(
                  label: Text(approve),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedApproves.add(approve);
                      } else {
                        _selectedApproves.remove(approve);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF9C27B0).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF9C27B0),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
            if (_selectedApproves.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pilih minimal satu persetujuan',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentationImages() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dokumentasi Foto',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 12),
            _buildImagePicker('Foto Dokumentasi 1', 'first', _documentationImageFirst),
            const SizedBox(height: 12),
            _buildImagePicker('Foto Dokumentasi 2', 'second', _documentationImageSecond),
            const SizedBox(height: 12),
            _buildImagePicker('Foto Dokumentasi 3', 'third', _documentationImageThird),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, String imageType, XFile? image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(imageType),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: image != null ? const Color(0xFF9C27B0) : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: image != null ? const Color(0xFF9C27B0).withOpacity(0.1) : Colors.grey[50],
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Foto Terpilih',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap untuk mengambil foto',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Foto telah dipilih',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitReport,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Mengirim...' : translate('submit'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0), // Purple theme
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
