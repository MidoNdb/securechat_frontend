// lib/modules/chat/widgets/inputs/media_picker_widget.dart
// ✅ NOUVEAU WIDGET - Sélection média moderne et organisée

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerWidget extends StatelessWidget {
  final Function(List<File> images) onImagesSelected;
  final Function(File image) onSingleImageSelected;

  const MediaPickerWidget({
    Key? key,
    required this.onImagesSelected,
    required this.onSingleImageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            _buildHandleBar(),
            
            const SizedBox(height: 20),
            
            // Titre
            _buildTitle(),
            
            const SizedBox(height: 24),
            
            // Options de sélection
            _buildMediaOptions(context),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
  
  Widget _buildTitle() {
    return const Text(
      'Envoyer des fichiers',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildMediaOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Galerie - Multiple
          _buildOptionTile(
            icon: Icons.photo_library_rounded,
            iconColor: const Color(0xFF667eea),
            title: 'Galerie',
            subtitle: 'Choisir jusqu\'à 10 photos',
            onTap: () {
              Navigator.pop(context);
              _pickMultipleImages();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Caméra
          _buildOptionTile(
            icon: Icons.camera_alt_rounded,
            iconColor: Colors.pink,
            title: 'Appareil photo',
            subtitle: 'Prendre une photo',
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Document (Désactivé pour l'instant)
          Opacity(
            opacity: 0.5,
            child: _buildOptionTile(
              icon: Icons.insert_drive_file_rounded,
              iconColor: Colors.grey,
              title: 'Document',
              subtitle: 'Bientôt disponible',
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.1),
                      iconColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onTap != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: onTap != null ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ==================== SÉLECTION IMAGES ====================
  
  Future<void> _pickMultipleImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      // Limiter à 10 images
      final imagesToAdd = images.take(10).map((xFile) => File(xFile.path)).toList();
      
      onImagesSelected(imagesToAdd);

      if (images.length > 10) {
        Get.snackbar(
          'Limite atteinte',
          'Seules les 10 premières images ont été sélectionnées',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange[900],
          icon: const Icon(Icons.info_outline, color: Colors.orange),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
      
    } catch (e) {
      print('❌ Erreur sélection images: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner les images',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.red),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
  
  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        onSingleImageSelected(File(image.path));
      }
      
    } catch (e) {
      print('❌ Erreur caméra: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de prendre une photo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.red),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
}

// ==================== FONCTION HELPER ====================

/// Affiche le sélecteur de média
void showMediaPicker(
  BuildContext context, {
  required Function(List<File> images) onImagesSelected,
  required Function(File image) onSingleImageSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MediaPickerWidget(
      onImagesSelected: onImagesSelected,
      onSingleImageSelected: onSingleImageSelected,
    ),
  );
}