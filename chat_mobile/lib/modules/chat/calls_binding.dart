// lib/modules/chat/calls_binding.dart

import 'package:get/get.dart';
import 'controllers/calls_controller.dart';

class CallsBinding extends Bindings {
  @override
  void dependencies() {
    // Créer CallsController UNIQUEMENT pour l'écran d'appel
    Get.put<CallsController>(
      CallsController(),
      permanent: false, // Sera détruit quand on quitte l'écran
    );
  }
}