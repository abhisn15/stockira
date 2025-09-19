import 'package:flutter/material.dart';
import 'dart:io';
import '../services/photo_example_service.dart';
import 'survey_photo_field.dart';
import 'photo_examples_menu.dart';

class SurveyFormWithExamples extends StatelessWidget {
  final Map<String, File?> photoFields;
  final Map<String, String?> uploadedImageUrls;
  final Function(String) onPickImage;
  final Function(String)? onRemoveImage;
  final VoidCallback? onSubmit;

  const SurveyFormWithExamples({
    super.key,
    required this.photoFields,
    required this.uploadedImageUrls,
    required this.onPickImage,
    this.onRemoveImage,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo examples menu
          const PhotoExamplesMenu(),
          
          const SizedBox(height: 24),
          
          // Survey form title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Form Survey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Photo fields
          ...photoFields.entries.map((entry) {
            final fieldName = entry.key;
            final selectedImage = entry.value;
            final isUploaded = uploadedImageUrls[fieldName] != null;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: SurveyPhotoField(
                fieldName: fieldName,
                label: PhotoExampleService.getFieldTitle(fieldName),
                selectedImage: selectedImage,
                isUploaded: isUploaded,
                onPickImage: () => onPickImage(fieldName),
                onRemoveImage: onRemoveImage != null ? () => onRemoveImage!(fieldName) : null,
              ),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Submit button
          if (onSubmit != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SUBMIT SURVEY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SurveyFormWithExamplesSimple extends StatelessWidget {
  final Map<String, File?> photoFields;
  final Map<String, String?> uploadedImageUrls;
  final Function(String) onPickImage;
  final Function(String)? onRemoveImage;
  final VoidCallback? onSubmit;

  const SurveyFormWithExamplesSimple({
    super.key,
    required this.photoFields,
    required this.uploadedImageUrls,
    required this.onPickImage,
    this.onRemoveImage,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Survey form title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Form Survey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PhotoExamplesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.photo_library),
                  tooltip: 'Lihat Contoh Foto',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Photo fields
          ...photoFields.entries.map((entry) {
            final fieldName = entry.key;
            final selectedImage = entry.value;
            final isUploaded = uploadedImageUrls[fieldName] != null;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: SurveyPhotoFieldSimple(
                fieldName: fieldName,
                label: PhotoExampleService.getFieldTitle(fieldName),
                selectedImage: selectedImage,
                isUploaded: isUploaded,
                onPickImage: () => onPickImage(fieldName),
                onRemoveImage: onRemoveImage != null ? () => onRemoveImage!(fieldName) : null,
              ),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Submit button
          if (onSubmit != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SUBMIT SURVEY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}