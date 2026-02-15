// lib/modules/chat/chat_binding.dart

import 'package:chat_mobile/modules/chat/controllers/chat_controller.dart';
import 'package:get/get.dart';
import 'controllers/main_shell_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    
    Get.lazyPut<ChatController>(
      () => ChatController(),
      fenix: true,           // ← très utile si on revient souvent sur la page
    );
    Get.lazyPut<MainShellController>(() => MainShellController());
  }
  // Get.lazyPut<ImageBubbleController>(() => ImageBubbleController());
  
}






