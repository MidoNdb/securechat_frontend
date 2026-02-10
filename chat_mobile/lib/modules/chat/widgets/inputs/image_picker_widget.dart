// lib/modules/chat/widgets/inputs/image_picker_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

/// Widget pour sélection d'images (galerie ou caméra)
/// 
/// Features:
/// - Sélection depuis galerie
/// - Prise de photo avec caméra
/// - Prévisualisation avant envoi
/// - Gestion des permissions
class ImagePickerWidget extends StatelessWidget {
  final Function(File) onImageSelected;
  final VoidCallback? onCancel;
  
  const ImagePickerWidget({
    Key? key,
    required this.onImageSelected,
    this.onCancel,
  }) : super(key: key);
  
  /// Affiche le bottom sheet de sélection
  static Future<void> show({
    required BuildContext context,
    required Function(File) onImageSelected,
  }) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerWidget(
        onImageSelected: onImageSelected,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Titre
          Text(
            'Envoyer une image',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 20),
          
          // Options
          _buildOption(
            icon: Icons.photo_library,
            title: 'Galerie',
            subtitle: 'Choisir depuis la galerie',
            color: Colors.blue,
            onTap: () => _pickFromGallery(context),
          ),
          
          Divider(height: 1),
          
          _buildOption(
            icon: Icons.camera_alt,
            title: 'Caméra',
            subtitle: 'Prendre une photo',
            color: Colors.green,
            onTap: () => _pickFromCamera(context),
          ),
          
          SizedBox(height: 10),
          
          // Bouton annuler
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Option de sélection
  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }
  
  /// Sélectionne depuis la galerie
  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limite résolution
        maxHeight: 1920,
        imageQuality: 85, // Qualité JPEG
      );
      
      if (image != null) {
        Navigator.of(context).pop();
        _showPreview(context, File(image.path));
      }
      
    } catch (e) {
      print('❌ Erreur sélection galerie: $e');
      _showError(context, 'Impossible d\'accéder à la galerie');
    }
  }
  
  /// Prend une photo avec la caméra
  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        Navigator.of(context).pop();
        _showPreview(context, File(image.path));
      }
      
    } catch (e) {
      print('❌ Erreur caméra: $e');
      _showError(context, 'Impossible d\'accéder à la caméra');
    }
  }
  
  /// Affiche la prévisualisation avant envoi
  void _showPreview(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      builder: (context) => _ImagePreviewDialog(
        imageFile: imageFile,
        onSend: () {
          Navigator.of(context).pop();
          onImageSelected(imageFile);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  /// Affiche une erreur
  void _showError(BuildContext context, String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      duration: Duration(seconds: 3),
    );
  }
}

// ==================== DIALOG PRÉVISUALISATION ====================

/// Dialog de prévisualisation avant envoi
class _ImagePreviewDialog extends StatelessWidget {
  final File imageFile;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  
  const _ImagePreviewDialog({
    required this.imageFile,
    required this.onSend,
    required this.onCancel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Aperçu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            // Image preview
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Boutons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Annuler
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, 50),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // Envoyer
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onSend,
                      icon: Icon(Icons.send),
                      label: Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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
}