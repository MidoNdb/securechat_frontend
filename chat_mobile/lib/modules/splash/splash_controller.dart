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
      print('🔍 Vérification authentification...');
      
      await Future.delayed(const Duration(seconds: 1));
      
      // ✅ CORRECTION: Utiliser hasPrivateKeys() au lieu de getPrivateKey()
      final accessToken = await _secureStorage.getAccessToken();
      final hasKeys = await _secureStorage.hasPrivateKeys();
      
      print('📱 Access Token: ${accessToken != null ? "EXISTS" : "NULL"}');
      print('🔑 Private Keys: ${hasKeys ? "EXISTS" : "NULL"}');
      
      String destination;
      
      if (accessToken == null || !hasKeys) {
        destination = AppRoutes.LOGIN;
        print('❌ Credentials manquants → LOGIN');
      } else {
        destination = AppRoutes.INITIAL;
        print('✅ Credentials OK → INITIAL');
      }
      
      await Get.offAllNamed(destination);
      print('✅ Navigation vers $destination');
      
    } catch (e) {
      print('❌ Erreur SplashController: $e');
      await Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}



// // lib/modules/splash/controllers/splash_controller.dart

// import 'package:get/get.dart';
// import '../../../data/services/secure_storage_service.dart';
// import '../../../app/routes/app_routes.dart';

// class SplashController extends GetxController {
//   final SecureStorageService _secureStorage = Get.find<SecureStorageService>();
  
//   @override
//   void onInit() {
//     super.onInit();
//     print('🎯 SplashController: onInit() appelé');
    
//     // ✅ Appeler immédiatement dans onInit au lieu de onReady
//     _checkAuthentication();
//   }
  
//   @override
//   void onReady() {
//     super.onReady();
//     print('🎯 SplashController: onReady() appelé');
//   }
  
//   Future<void> _checkAuthentication() async {
//     try {
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//       print('🔍 SPLASH: Début vérification authentification');
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
//       // Attendre 1 seconde
//       await Future.delayed(Duration(seconds: 1));
//       print('⏱️ SPLASH: Délai 1s terminé');
      
//       // Vérifier tokens
//       final accessToken = await _secureStorage.getAccessToken();
//       final privateKey = await _secureStorage.getPrivateKey();
      
//       print('📱 SPLASH: Access Token = ${accessToken != null ? "EXISTS (${accessToken.substring(0, 20)}...)" : "NULL"}');
//       print('🔑 SPLASH: Private Key = ${privateKey != null ? "EXISTS" : "NULL"}');
      
//       String destination;
      
//       if (accessToken == null || privateKey == null) {
//         destination = AppRoutes.LOGIN;
//         print('❌ SPLASH: Pas de credentials → LOGIN');
//       } else {
//         destination = AppRoutes.INITIAL;
//         print('✅ SPLASH: Credentials présents → INITIAL');
//       }
      
//       print('➡️ SPLASH: Navigation vers: $destination');
      
//       // Navigation
//       await Get.offAllNamed(destination);
      
//       print('✅ SPLASH: Navigation terminée vers $destination');
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
//     } catch (e, stack) {
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//       print('❌ SPLASH: ERREUR CRITIQUE');
//       print('Erreur: $e');
//       print('Stack: $stack');
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
//       // Par sécurité, aller vers LOGIN
//       await Get.offAllNamed(AppRoutes.LOGIN);
//       print('✅ SPLASH: Navigation de secours vers LOGIN');
//     }
//   }
// }