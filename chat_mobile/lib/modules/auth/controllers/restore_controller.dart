// // lib/app/modules/auth/controllers/restore_controller.dart

// import 'package:chat_mobile/data/services/secure_storage_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../data/services/auth_service.dart';
// import 'package:chat_mobile/app/routes/app_routes.dart';

// class RestoreController extends GetxController {
//   final AuthService _authService = Get.find<AuthService>();
//    final SecureStorageService storage= Get.find<SecureStorageService>();
//   // État
//   final RxBool isLoading = false.obs;
//   final RxString errorMessage = ''.obs;
  
//   /// Restaurer depuis backup (utilise le password déjà saisi au login)
//   Future<void> restoreFromBackup(String password) async {
//     try {
//       errorMessage.value = '';
//       isLoading.value = true;
      
//       print('🔄 Début restauration...');
      
//       final success = await _authService.restoreFromBackup(password);
      
//       if (success) {
//         Get.snackbar(
//           '✅ Succès',
//           'Clés restaurées avec succès !',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           duration: const Duration(seconds: 2),
//         );
        
//         // Rediriger vers home
//         Get.offAllNamed(AppRoutes.MAIN_SHELL);
//       } else {
//         throw Exception('Échec de la restauration');
//       }
      
//     } catch (e) {
//       print('❌ Erreur restauration: $e');
//       errorMessage.value = e.toString();
      
//       Get.snackbar(
//         '❌ Erreur',
//         'Échec de la restauration: ${e.toString()}',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: const Duration(seconds: 4),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }
  
//   /// Créer nouveau compte (perte anciens messages)
//   // lib/app/modules/auth/controllers/restore_controller.dart

//   /// Créer nouveau compte (perte anciens messages)
//   Future<void> createNewKeys() async {
//     // Confirmer avec l'utilisateur
//     final confirmed = await Get.dialog<bool>(
//       AlertDialog(
//         title: const Text('⚠️ Attention'),
//         content: const Text(
//           'En créant de nouvelles clés, vous perdrez l\'accès à tous vos anciens messages.\n\n'
//           'Cette action est irréversible.\n\n'
//           'Êtes-vous sûr de vouloir continuer ?'
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(result: false),
//             child: const Text('Annuler'),
//           ),
//           ElevatedButton(
//             onPressed: () => Get.back(result: true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: const Text('Créer nouvelles clés'),
//           ),
//         ],
//       ),
//     );
    
//     if (confirmed == true) {
//       try {
//         isLoading.value = true;
        
//         // Générer nouvelles clés RSA
//         print('🔐 Génération de nouvelles clés...');
//         final keyPair = await _authService.generateRSAKeyPair();
        
//         // ← CORRECTION : Utiliser storage public
//         await storage.savePrivateKey(
//           keyPair['private_key']!
//         );
        
//         print('✅ Nouvelles clés générées et sauvegardées');
        
//         Get.snackbar(
//           '✅ Succès',
//           'Nouvelles clés créées',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//         );
        
//         // Rediriger vers home
//         Get.offAllNamed(AppRoutes.MAIN_SHELL);
        
//       } catch (e) {
//         Get.snackbar(
//           '❌ Erreur',
//           'Impossible de créer les clés: ${e.toString()}',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       } finally {
//         isLoading.value = false;
//       }
//     }
//   }
  
//   /// Retour au login
//   void backToLogin() {
//     Get.offAllNamed(AppRoutes.LOGIN);
//   }
// }