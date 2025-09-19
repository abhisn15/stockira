import 'package:flutter/material.dart';
import 'dart:io';
import '../services/photo_example_service.dart';
import 'photo_example_preview.dart';
import 'photo_example_button.dart';

class SurveyPhotoField extends StatelessWidget {
  final String fieldName;
  final String label;
  final File? selectedImage;
  final bool isUploaded;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;
  final bool showExamplePreview;
  final bool showExampleButton;

  const SurveyPhotoField({
    super.key,
    required this.fieldName,
    required this.label,
    required this.selectedImage,
    required this.isUploaded,
    required this.onPickImage,
    this.onRemoveImage,
    this.showExamplePreview = true,
    this.showExampleButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label with example button
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (showExampleButton)
              PhotoExampleButton(fieldName: fieldName),
          ],
        ),
        const SizedBox(height: 8),
        
        // Photo picker button
        InkWell(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImage != null ? Colors.green : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isUploaded)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      if (onRemoveImage != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: onRemoveImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 32,
                        color: Colors.grey[600],
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
        
        // Example preview
        if (showExamplePreview)
          PhotoExamplePreview(
            fieldName: fieldName,
            customTitle: label,
            maxExamples: 2,
          ),
      ],
    );
  }
}

class SurveyPhotoFieldSimple extends StatelessWidget {
  final String fieldName;
  final String label;
  final File? selectedImage;
  final bool isUploaded;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const SurveyPhotoFieldSimple({
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
        // Field label with example button
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            PhotoExampleButton(fieldName: fieldName),
          ],
        ),
        const SizedBox(height: 8),
        
        // Photo picker button
        InkWell(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImage != null ? Colors.green : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isUploaded)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      if (onRemoveImage != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: onRemoveImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 32,
                        color: Colors.grey[600],
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
      ],
    );
  }
}
