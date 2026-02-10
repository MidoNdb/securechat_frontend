// lib/modules/chat/controllers/image_bubble_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import '../../../data/models/message.dart';
import '../../../data/services/image_message_service.dart';

class ImageBubbleController extends GetxController {
  final ImageMessageService _imageService = Get.find<ImageMessageService>();
  
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  
  final Message message;
  
  ImageBubbleController({required this.message});
  
  @override
  void onInit() {
    super.onInit();
    loadImage();
  }
  
  Future<void> loadImage() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      print('🖼️ Chargement image ${message.id}...');
      print('   Encrypted content length: ${message.encryptedContent.length}');
      print('   Nonce: ${message.nonce}');
      print('   Auth tag: ${message.authTag}');
      
      final file = await _imageService.decryptImage(message);
      
      imageFile.value = file;
      isLoading.value = false;
      
      print('✅ Image déchiffrée: ${file.path}');
      
    } catch (e, stackTrace) {
      print('❌ Erreur chargement image: $e');
      print('Stack trace: $stackTrace');
      
      error.value = 'Impossible de charger l\'image';
      isLoading.value = false;
    }
  }
  
  @override
  void onClose() {
    imageFile.value = null;
    super.onClose();
  }
}