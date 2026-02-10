// lib/modules/auth/auth_binding.dart

import 'package:chat_mobile/modules/auth/controllers/otp_controller.dart';
import 'package:get/get.dart';
import 'controllers/login_controller.dart';
import 'controllers/register_controller.dart' ;

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(), 
      fenix: true,
      );
    Get.lazyPut<RegisterController>(() => RegisterController());
    Get.lazyPut<OtpController>(() => OtpController());
  }
}



// // lib/modules/auth/binding.dart
// import 'package:chat_mobile/modules/auth/controllers/restore_controller.dart';
// import 'package:get/get.dart';
// import 'controllers/login_controller.dart';
// import 'controllers/register_controller.dart';
// import 'controllers/verify_sms_controller.dart';

// class AuthBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<LoginController>(
//       () => LoginController(),
//       fenix: false, // Réutilisé si on revient sur Login
//     );
    
//     Get.lazyPut<RegisterController>(
//       () => RegisterController(),
//       fenix: false,
     
//     );
//   }
// }