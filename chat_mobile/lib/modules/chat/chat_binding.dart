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






// import 'package:chat_mobile/modules/chat/controllers/messages_controller.dart';
// import 'package:chat_mobile/modules/chat/controllers/main_shell_controller.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_instance/src/bindings_interface.dart';

// class ChatBinding extends Bindings {
//   @override
//   void dependencies() {
//     // ... tes autres contrôleurs
    
//     // ✅ Ajoute ou décommente cette ligne exactement comme ceci :
//     Get.lazyPut<MessagesController>(() => MessagesController());
    
//     // Si tu utilises MainShellController pour gérer tes onglets, 
//     // assure-toi qu'il est aussi là
//     Get.lazyPut<MainShellController>(() => MainShellController());
//   }
// }