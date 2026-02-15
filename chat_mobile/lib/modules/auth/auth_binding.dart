
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

