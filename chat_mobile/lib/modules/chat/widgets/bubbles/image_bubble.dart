// lib/modules/chat/widgets/bubbles/image_bubble.dart
// ✅ CORRECTION MINIMALE - Juste ajout de mounted check

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../data/models/message.dart';
import '../../../../data/services/image_message_service.dart';

class ImageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? senderName;
  
  const ImageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.senderName,
  }) : super(key: key);
  
  @override
  State<ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<ImageBubble> {
  final ImageMessageService _imageService = Get.find<ImageMessageService>();
  
  File? _imageFile;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      // ✅ Vérifier mounted AVANT setState
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final file = await _imageService.decryptImage(widget.message);
      
      // ✅ Vérifier mounted AVANT setState
      if (!mounted) return;
      
      setState(() {
        _imageFile = file;
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Erreur chargement image: $e');
      
      // ✅ Vérifier mounted AVANT setState
      if (!mounted) return;
      
      setState(() {
        _error = 'Impossible de charger l\'image';
        _isLoading = false;
      });
    }
  }
  
  void _openFullscreen() {
    if (_imageFile == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenImageView(
          imageFile: _imageFile!,
          message: widget.message,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 200,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: widget.isMe 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            // Nom expéditeur (si groupe)
            if (!widget.isMe && widget.senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  widget.senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Container de l'image
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  GestureDetector(
                    onTap: _openFullscreen,
                    child: _buildImageContent(),
                  ),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_imageFile != null) {
      return _buildImageDisplay();
    }
    
    return _buildLoadingState();
  }
  
  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Déchiffrement...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.red[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[700],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadImage,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageDisplay() {
    return Image.file(
      _imageFile!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorState();
      },
    );
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spacer(),
          Text(
            _formatTime(widget.message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== VUE PLEIN ÉCRAN ====================

class _FullscreenImageView extends StatelessWidget {
  final File imageFile;
  final Message message;
  
  const _FullscreenImageView({
    required this.imageFile,
    required this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _formatDateTime(message.timestamp),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implémenter partage
            },
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: FileImage(imageFile),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        initialScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(
          tag: 'image_${message.id}',
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return 'Aujourd\'hui ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}


