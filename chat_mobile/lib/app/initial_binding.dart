// lib/app/initial_binding.dart

import 'package:chat_mobile/data/services/otp_service.dart';
import 'package:chat_mobile/modules/chat/controllers/main_shell_controller.dart';
import 'package:get/get.dart';
import '../modules/chat/controllers/messages_controller.dart';
import '../modules/chat/controllers/profile_controller.dart';
import '../modules/chat/controllers/contacts_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut(() => OtpService(),fenix: true);

    Get.lazyPut<MessagesController>(
      () => MessagesController(), 
      fenix: true,
    );
    
    Get.lazyPut<ProfileController>(
      () => ProfileController(), 
      fenix: true,
    );
    
    Get.lazyPut<ContactsController>(
      () => ContactsController(), 
      fenix: true,
    );
    Get.lazyPut<MainShellController>(
      () => MainShellController(),
      fenix: true);
  }
  
}

