import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/survey_photo_field_enhanced.dart';

/// Example of how to integrate photo examples into existing survey form
/// 
/// To use this in your existing survey form:
/// 1. Import the SurveyPhotoFieldEnhanced widget
/// 2. Replace your existing _buildPhotoField method with this enhanced version
/// 3. The example photos will automatically appear below each photo field

class SurveyFormExample extends StatefulWidget {
  const SurveyFormExample({super.key});

  @override
  State<SurveyFormExample> createState() => _SurveyFormExampleState();
}

class _SurveyFormExampleState extends State<SurveyFormExample> {
  // Photo fields - same as your existing survey form
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
  
  // Uploaded image URLs - same as your existing survey form
  Map<String, String?> _uploadedImageUrls = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Form dengan Contoh Foto'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Form ini menunjukkan bagaimana contoh foto otomatis muncul di bawah setiap field foto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Photo fields with examples
            ..._photoFields.entries.map((entry) {
              final fieldName = entry.key;
              final selectedImage = entry.value;
              final isUploaded = _uploadedImageUrls[fieldName] != null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: SurveyPhotoFieldEnhanced(
                  fieldName: fieldName,
                  label: _getFieldLabel(fieldName),
                  selectedImage: selectedImage,
                  isUploaded: isUploaded,
                  onPickImage: () => _pickImage(fieldName),
                  onRemoveImage: () => _removeImage(fieldName),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getFieldLabel(String fieldName) {
    switch (fieldName) {
      case 'photo_idn_freezer_1':
        return 'Foto Freezer 1';
      case 'photo_idn_freezer_2':
        return 'Foto Freezer 2';
      case 'freezer_position_image':
        return 'Foto Posisi Freezer';
      case 'photo_sticker_crispy_ball':
        return 'Foto Sticker Crispy Ball';
      case 'photo_sticker_mochi':
        return 'Foto Sticker Mochi';
      case 'photo_sticker_sharing_olympic':
        return 'Foto Sticker Sharing Olympic';
      case 'photo_price_board_olympic':
        return 'Foto Papan Harga Olympic';
      case 'photo_wobler_promo':
        return 'Foto Wobler Promo';
      case 'photo_pop_promo':
        return 'Foto Pop Promo';
      case 'photo_price_board_led':
        return 'Foto Price Board LED';
      case 'photo_sticker_glass_mochi':
        return 'Foto Sticker Kaca Mochi';
      case 'photo_sticker_frame_crispy_balls':
        return 'Foto Sticker Frame Crispy Balls';
      case 'photo_freezer_backup':
        return 'Foto Freezer Cadangan';
      case 'photo_drum_freezer':
        return 'Foto Drum Freezer';
      case 'photo_crispy_balls_tier':
        return 'Foto Produk Fokus Crispy Balls';
      case 'photo_promo_running':
        return 'Foto Promo Berjalan';
      default:
        return 'Foto';
    }
  }

  void _pickImage(String fieldName) {
    // Simulate picking an image
    setState(() {
      _photoFields[fieldName] = File('dummy_path');
    });
    
    // Simulate upload
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _uploadedImageUrls[fieldName] = 'uploaded_url';
      });
    });
  }

  void _removeImage(String fieldName) {
    setState(() {
      _photoFields[fieldName] = null;
      _uploadedImageUrls.remove(fieldName);
    });
  }
}

/// Instructions for integrating into existing survey form:
/// 
/// 1. Replace your existing _buildPhotoField method with this:
/// 
/// Widget _buildPhotoField(String fieldName, String label) {
///   final selectedImage = _photoFields[fieldName];
///   final isUploaded = _uploadedImageUrls[fieldName] != null;
///   
///   return SurveyPhotoFieldEnhanced(
///     fieldName: fieldName,
///     label: label,
///     selectedImage: selectedImage,
///     isUploaded: isUploaded,
///     onPickImage: () => _pickImage(fieldName),
///     onRemoveImage: () => _removeImage(fieldName),
///   );
/// }
/// 
/// 2. Add the _removeImage method if you don't have it:
/// 
/// void _removeImage(String fieldName) {
///   setState(() {
///     _photoFields[fieldName] = null;
///     _uploadedImageUrls.remove(fieldName);
///   });
/// }
/// 
/// 3. That's it! The example photos will automatically appear below each photo field.
