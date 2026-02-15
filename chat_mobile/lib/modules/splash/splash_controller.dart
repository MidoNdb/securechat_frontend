// lib/modules/splash/controllers/splash_controller.dart

import 'package:get/get.dart';
import '../../../data/services/secure_storage_service.dart';
import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();
  
  @override
  void onInit() {
    super.onInit();
    _checkAuthentication();
  }
  
  Future<void> _checkAuthentication() async {
    try {
      print('Vérification authentification...');
      
      await Future.delayed(const Duration(seconds: 1));
      
      //  CORRECTION: Utiliser hasPrivateKeys() au lieu de getPrivateKey()
      final accessToken = await _secureStorage.getAccessToken();
      final hasKeys = await _secureStorage.hasPrivateKeys();
      
      print(' Access Token: ${accessToken != null ? "EXISTS" : "NULL"}');
      print(' Private Keys: ${hasKeys ? "EXISTS" : "NULL"}');
      
      String destination;
      
      if (accessToken == null || !hasKeys) {
        destination = AppRoutes.LOGIN;
        print(' Credentials manquants → LOGIN');
      } else {
        destination = AppRoutes.INITIAL;
        print(' Credentials OK → INITIAL');
      }
      
      await Get.offAllNamed(destination);
      print('Navigation vers $destination');
      
    } catch (e) {
      print(' Erreur SplashController: $e');
      await Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}



