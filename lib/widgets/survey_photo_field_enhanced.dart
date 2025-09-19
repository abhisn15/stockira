import 'package:flutter/material.dart';
import 'dart:io';
import 'photo_example_helper.dart';

class SurveyPhotoFieldEnhanced extends StatelessWidget {
  final String fieldName;
  final String label;
  final File? selectedImage;
  final bool isUploaded;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const SurveyPhotoFieldEnhanced({
    super.key,
    required this.fieldName,
    required this.label,
    required this.selectedImage,
    required this.isUploaded,
    required this.onPickImage,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: onPickImage,
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
                  selectedImage != null ? Icons.check_circle : Icons.camera_alt,
                  size: 32,
                  color: isUploaded ? Colors.green : (selectedImage != null ? Colors.orange : Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedImage != null 
                    ? (isUploaded ? 'Foto berhasil diupload' : 'Foto siap diupload')
                    : 'Tap untuk mengambil foto',
                  style: TextStyle(
                    color: isUploaded ? Colors.green[700] : (selectedImage != null ? Colors.orange[700] : Colors.grey[700]),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (selectedImage != null && onRemoveImage != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRemoveImage,
                    child: const Text('Hapus Foto'),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Show example photo if available
        if (PhotoExampleHelper.getExampleImagePath(fieldName) != null) ...[
          const SizedBox(height: 12),
          _buildExamplePhoto(context),
        ],
      ],
    );
  }

  Widget _buildExamplePhoto(BuildContext context) {
    final exampleImagePath = PhotoExampleHelper.getExampleImagePath(fieldName)!;
    final description = PhotoExampleHelper.getFieldDescription(fieldName);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Contoh Foto yang Benar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[700],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showExampleDialog(context, exampleImagePath),
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  exampleImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          Text(
                            'Contoh tidak tersedia',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExampleDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contoh: $label',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              
              // Image
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contoh foto tidak tersedia',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}
