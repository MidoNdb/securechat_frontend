// lib/modules/auth/controllers/login_controller.dart
// ✅ PROTECTION MAXIMALE - Empêche toute erreur de dispose

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/secure_storage_service.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../app/routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();
  
  // ✅ CHANGEMENT : Utiliser nullable pour les controllers
  TextEditingController? _phoneController;
  TextEditingController? _passwordController;
  
  // ✅ Getters avec vérification
  TextEditingController get phoneController {
    _phoneController ??= TextEditingController();
    return _phoneController!;
  }
  
  TextEditingController get passwordController {
    _passwordController ??= TextEditingController();
    return _passwordController!;
  }
  
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = ''.obs;
  final phoneE164 = ''.obs;
  final phoneIsValid = false.obs;
  
  bool _isDisposed = false;
  
  @override
  void onInit() {
    super.onInit();
    // ✅ Initialiser les controllers ici
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
  }
  
  @override
  void onClose() {
    _isDisposed = true;
    
    // ✅ Dispose sécurisé
    _phoneController?.dispose();
    _passwordController?.dispose();
    _phoneController = null;
    _passwordController = null;
    
    super.onClose();
  }
  
  void onPhoneChanged(String e164Number) {
    if (_isDisposed) return;
    phoneE164.value = e164Number;
    phoneIsValid.value = PhoneFormatter.isValidPhoneNumber(e164Number);
  }
  
  Future<void> login() async {
    if (_isDisposed) return;
    
    if (phoneE164.value.isEmpty || !phoneIsValid.value) {
      _showError('Numéro de téléphone invalide');
      return;
    }
    
    if (_passwordController?.text.isEmpty ?? true) {
      _showError('Le mot de passe est requis');
      return;
    }
    
    try {
      errorMessage.value = '';
      isLoading.value = true;
      
      final result = await _authService.login(
        phoneNumber: phoneE164.value,
        password: _passwordController!.text,
      );
      
      if (_isDisposed) return;
      
      if (result['requires_key_regeneration'] == true) {
        await _handleMandatoryRegeneration();
        return;
      }
      
      if (result['requires_key_recovery'] == true) {
        await _handleKeyRecovery();
        return;
      }
      
      // ✅ Pré-charger les clés E2EE
      print('🔐 Pré-chargement des clés E2EE...');
      await _secureStorage.preloadKeys();
      print('✅ Clés en cache');
      
      // ✅ IMPORTANT : Attendre un frame avant navigation
      await Future.delayed(Duration(milliseconds: 100));
      
      if (_isDisposed) return;
      
      Get.offAllNamed(AppRoutes.MAIN_SHELL);
      
      // ✅ Snackbar après navigation
      Future.delayed(Duration(milliseconds: 300), () {
        if (!_isDisposed) {
          // Get.snackbar(
          //   'Connexion réussie',
          //   'Bienvenue ${_authService.currentUser.value?.displayName ?? ""}',
          //   snackPosition: SnackPosition.TOP,
          //   backgroundColor: Colors.green.withOpacity(0.1),
          //   colorText: Colors.green,
          //   icon: const Icon(Icons.check_circle, color: Colors.green),
          //   duration: const Duration(seconds: 2),
          // );
        }
      });
      
    } catch (e) {
      if (_isDisposed) return;
      _showError(_extractErrorMessage(e.toString()));
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _handleMandatoryRegeneration() async {
    if (_isDisposed) return;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Régénération Requise'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucune clé de chiffrement disponible.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('Ceci peut arriver si:'),
            Text('• Première connexion sur ce téléphone'),
            Text('• Données locales effacées'),
            Text('• Compte créé avant la fonctionnalité backup'),
            SizedBox(height: 16),
            Text(
              'De nouvelles clés seront générées.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuer'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    
    if (_isDisposed) return;
    
    if (confirmed == true) {
      await _regenerateKeysAndContinue();
    }
  }

  Future<void> _regenerateKeysAndContinue() async {
    if (_isDisposed || _passwordController == null) return;
    
    try {
      isLoading.value = true;
      
      final success = await _authService.regenerateKeysAndCreateBackup(
        _passwordController!.text,
      );
      
      if (_isDisposed) return;
      
      if (success) {
        await _secureStorage.preloadKeys();
        await Future.delayed(Duration(milliseconds: 100));
        
        if (_isDisposed) return;
        
        Get.offAllNamed(AppRoutes.MAIN_SHELL);
        
        Future.delayed(Duration(milliseconds: 300), () {
          if (!_isDisposed) {
            // Get.snackbar(
            //   'Clés générées',
            //   'Nouvelles clés créées avec succès',
            //   snackPosition: SnackPosition.TOP,
            //   backgroundColor: Colors.green.withOpacity(0.1),
            //   colorText: Colors.green,
            //   icon: const Icon(Icons.check_circle, color: Colors.green),
            //   duration: const Duration(seconds: 3),
            // );
          }
        });
      } else {
        _showError('Erreur lors de la génération des clés');
      }
      
    } catch (e) {
      if (_isDisposed) return;
      _showError('Erreur: ${e.toString()}');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _handleKeyRecovery() async {
    if (_isDisposed || _passwordController == null) return;
    
    try {
      isLoading.value = true;
      
      final success = await _authService.recoverKeysFromBackup(_passwordController!.text);
      
      if (_isDisposed) return;
      
      if (success) {
        await _secureStorage.preloadKeys();
        await Future.delayed(Duration(milliseconds: 100));
        
        if (_isDisposed) return;
        
        Get.offAllNamed(AppRoutes.MAIN_SHELL);
        
        Future.delayed(Duration(milliseconds: 300), () {
          if (!_isDisposed) {
            // Get.snackbar(
            //   'Clés restaurées',
            //   'Vos clés privées ont été récupérées',
            //   snackPosition: SnackPosition.TOP,
            //   backgroundColor: Colors.green.withOpacity(0.1),
            //   colorText: Colors.green,
            // );
          }
        });
      } else {
        _showError('Impossible de récupérer les clés');
      }
      
    } catch (e) {
      if (_isDisposed) return;
      _showError('Erreur récupération: ${e.toString()}');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }
  
  void togglePasswordVisibility() {
    if (_isDisposed) return;
    obscurePassword.value = !obscurePassword.value;
  }
  
  void _showError(String message) {
    if (_isDisposed) return;
    
    errorMessage.value = message;
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      icon: const Icon(Icons.error_outline, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }
  
  String _extractErrorMessage(String error) {
    if (error.contains('Exception:')) {
      error = error.split('Exception:').last.trim();
    }
    
    if (error.contains('DioException')) {
      return 'Erreur de connexion au serveur';
    }
    
    if (error.contains('connection')) {
      return 'Vérifiez votre connexion Internet';
    }
    
    if (error.contains('401') || error.toLowerCase().contains('unauthorized')) {
      return 'Numéro de téléphone ou mot de passe incorrect';
    }
    
    if (error.contains('500')) {
      return 'Erreur serveur. Réessayez plus tard';
    }
    
    return error.length > 100 
        ? 'Une erreur est survenue lors de la connexion'
        : error;
  }
  
  void goToRegister() {
    if (_isDisposed) return;
    Get.toNamed(AppRoutes.REGISTER);
  }
}



// // lib/modules/auth/controllers/login_controller.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../data/services/auth_service.dart';
// import '../../../core/utils/phone_formatter.dart';
// import '../../../app/routes/app_routes.dart';

// class LoginController extends GetxController {
//   final AuthService _authService = Get.find<AuthService>();
  
//   late final TextEditingController phoneController;
//   late final TextEditingController passwordController;
  
//   final isLoading = false.obs;
//   final obscurePassword = true.obs;
//   final errorMessage = ''.obs;
//   final phoneE164 = ''.obs;
//   final phoneIsValid = false.obs;
  
//   @override
//   void onInit() {
//     super.onInit();
//     phoneController = TextEditingController();
//     passwordController = TextEditingController();
//   }
  
//   @override
//   void onClose() {
//     phoneController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }
  
//   void onPhoneChanged(String e164Number) {
//     phoneE164.value = e164Number;
//     phoneIsValid.value = PhoneFormatter.isValidPhoneNumber(e164Number);
//   }
  
//   Future<void> login() async {
//   if (phoneE164.value.isEmpty || !phoneIsValid.value) {
//     _showError('Numéro de téléphone invalide');
//     return;
//   }
  
//   if (passwordController.text.isEmpty) {
//     _showError('Le mot de passe est requis');
//     return;
//   }
  
//   try {
//     errorMessage.value = '';
//     isLoading.value = true;
    
//     final result = await _authService.login(
//       phoneNumber: phoneE164.value,
//       password: passwordController.text,
//     );
    
    
//     if (result['requires_key_regeneration'] == true) {
//       await _handleMandatoryRegeneration();
//       return;
//     }
    
    
//     if (result['requires_key_recovery'] == true) {
//       await _handleKeyRecovery();
//       return;
//     }
    
//     Get.offAllNamed(AppRoutes.MAIN_SHELL);
    
//     Get.snackbar(
//       'Connexion réussie',
//       'Bienvenue ${_authService.currentUser.value?.displayName ?? ""}',
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.green.withOpacity(0.1),
//       colorText: Colors.green,
//       icon: const Icon(Icons.check_circle, color: Colors.green),
//       duration: const Duration(seconds: 2),
//     );
    
//   } catch (e) {
//     _showError(_extractErrorMessage(e.toString()));
//   } finally {
//     isLoading.value = false;
//   }
// }

// /// Gérer la régénération obligatoire (aucun backup disponible)
// Future<void> _handleMandatoryRegeneration() async {
//   final confirmed = await Get.dialog<bool>(
//     AlertDialog(
//       title: const Row(
//         children: [
//           Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
//           SizedBox(width: 12),
//           Text('Régénération Requise'),
//         ],
//       ),
//       content: const Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Aucune clé de chiffrement disponible.',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//           ),
//           SizedBox(height: 16),
//           Text('Ceci peut arriver si:'),
//           Text('• Première connexion sur ce téléphone'),
//           Text('• Données locales effacées'),
//           Text('• Compte créé avant la fonctionnalité backup'),
//           SizedBox(height: 16),
//           Text(
//             'De nouvelles clés seront générées.',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Get.back(result: false),
//           child: const Text('Annuler'),
//         ),
//         ElevatedButton(
//           onPressed: () => Get.back(result: true),
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//           child: const Text('Continuer'),
//         ),
//       ],
//     ),
//     barrierDismissible: false,
//   );
  
//   if (confirmed == true) {
//     await _regenerateKeysAndContinue();
//   }
// }

// /// Régénérer les clés et continuer
// Future<void> _regenerateKeysAndContinue() async {
//   try {
//     isLoading.value = true;
    
//     final success = await _authService.regenerateKeysAndCreateBackup(
//       passwordController.text,
//     );
    
//     if (success) {
//       Get.offAllNamed(AppRoutes.MAIN_SHELL);
      
//       Get.snackbar(
//         'Clés générées',
//         'Nouvelles clés créées avec succès',
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.green.withOpacity(0.1),
//         colorText: Colors.green,
//         icon: const Icon(Icons.check_circle, color: Colors.green),
//         duration: const Duration(seconds: 3),
//       );
//     } else {
//       _showError('Erreur lors de la génération des clés');
//     }
    
//   } catch (e) {
//     _showError('Erreur: ${e.toString()}');
//   } finally {
//     isLoading.value = false;
//   }
// }

// /// Gérer la récupération des clés locales manquantes
// Future<void> _handleKeyRecovery() async {
//   try {
//     isLoading.value = true;
    
//     final success = await _authService.recoverKeysFromBackup(passwordController.text);
    
//     if (success) {
//       Get.offAllNamed(AppRoutes.MAIN_SHELL);
      
//       Get.snackbar(
//         'Clés restaurées',
//         'Vos clés privées ont été récupérées',
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.green.withOpacity(0.1),
//         colorText: Colors.green,
//       );
//     } else {
//       _showError('Impossible de récupérer les clés');
//     }
    
//   } catch (e) {
//     _showError('Erreur récupération: ${e.toString()}');
//   } finally {
//     isLoading.value = false;
//   }
// }
  
//   /// Gérer les options de récupération pour nouveau device
//   Future<void> _handleKeyRecoveryOptions(Map<String, dynamic> result) async {
//     final hasBackup = result['has_backup'] == true;
    
//     final choice = await Get.dialog<String>(
//       AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
//             SizedBox(width: 12),
//             Text('Nouveau Appareil'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               result['warning'] ?? 'Connexion depuis un nouveau appareil détectée.',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 16),
//             if (hasBackup) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green.withOpacity(0.3)),
//                 ),
//                 child: const Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.cloud_download, color: Colors.green, size: 20),
//                         SizedBox(width: 8),
//                         Text(
//                           'Option recommandée',
//                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 8),
//                     Text('✓ Récupérer vos clés depuis le backup'),
//                     Text('✓ Accès à tous vos anciens messages'),
//                     Text('✓ Aucune perte de données'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red.withOpacity(0.3)),
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Régénérer les clés:',
//                     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
//                   ),
//                   SizedBox(height: 8),
//                   Text('✗ Anciens messages illisibles'),
//                   Text('✗ Nouvelles clés générées'),
//                   Text('✗ Action irréversible'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(result: 'cancel'),
//             child: const Text('Annuler'),
//           ),
//           if (hasBackup)
//             ElevatedButton.icon(
//               onPressed: () => Get.back(result: 'recover'),
//               icon: const Icon(Icons.cloud_download),
//               label: const Text('Récupérer'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             ),
//           ElevatedButton.icon(
//             onPressed: () => Get.back(result: 'regenerate'),
//             icon: const Icon(Icons.warning_amber),
//             label: const Text('Régénérer'),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//           ),
//         ],
//       ),
//       barrierDismissible: false,
//     );
    
//     if (choice == 'recover') {
//       await _recoverFromBackup();
//     } else if (choice == 'regenerate') {
//       await _regenerateKeys();
//     }
//   }
  
//   /// Récupérer les clés depuis le backup
//   Future<void> _recoverFromBackup() async {
//     try {
//       isLoading.value = true;
      
//       print('🔄 Tentative récupération backup...');
//       final success = await _authService.recoverKeysFromBackup(passwordController.text);
      
//       if (success) {
//         Get.offAllNamed(AppRoutes.MAIN_SHELL);
        
//         Get.snackbar(
//           'Clés récupérées',
//           'Vos clés ont été restaurées avec succès',
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.green.withOpacity(0.1),
//           colorText: Colors.green,
//           icon: const Icon(Icons.check_circle, color: Colors.green),
//           duration: const Duration(seconds: 3),
//         );
//       } else {
//         throw Exception('Échec de la récupération');
//       }
      
//     } catch (e) {
//       print('❌ Erreur récupération: $e');
      
//       final retry = await Get.dialog<bool>(
//         AlertDialog(
//           title: const Text('Erreur de récupération'),
//           content: const Text(
//             'Impossible de récupérer vos clés depuis le backup.\n\n'
//             'Cela peut être dû à:\n'
//             '• Mot de passe incorrect\n'
//             '• Backup corrompu\n\n'
//             'Voulez-vous régénérer de nouvelles clés?'
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Get.back(result: false),
//               child: const Text('Annuler'),
//             ),
//             ElevatedButton(
//               onPressed: () => Get.back(result: true),
//               child: const Text('Régénérer'),
//             ),
//           ],
//         ),
//       );
      
//       if (retry == true) {
//         await _regenerateKeys();
//       }
//     } finally {
//       isLoading.value = false;
//     }
//   }
  
//   /// Régénérer les clés (dernier recours)
//   Future<void> _regenerateKeys() async {
//     try {
//       isLoading.value = true;
      
//       final newKeys = await _authService.regenerateKeys();
      
//       await _authService.login(
//         phoneNumber: phoneE164.value,
//         password: passwordController.text,
//         newDhPublicKey: newKeys['dh_public_key'],
//         newSignPublicKey: newKeys['sign_public_key'],
//         confirmedKeyRegeneration: true,
//       );
      
//       // Créer un nouveau backup
//       await _authService.uploadKeysBackup(passwordController.text);
      
//       Get.offAllNamed(AppRoutes.MAIN_SHELL);
      
//       Get.snackbar(
//         'Nouvelles clés créées',
//         'Vos anciennes conversations ne seront plus accessibles',
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.orange.withOpacity(0.1),
//         colorText: Colors.orange,
//         icon: const Icon(Icons.warning, color: Colors.orange),
//         duration: const Duration(seconds: 4),
//       );
      
//     } catch (e) {
//       _showError('Erreur lors de la régénération: ${e.toString()}');
//     } finally {
//       isLoading.value = false;
//     }
//   }
  
  
//   void togglePasswordVisibility() {
//     obscurePassword.value = !obscurePassword.value;
//   }
  
//   void _showError(String message) {
//     errorMessage.value = message;
//     Get.snackbar(
//       'Erreur',
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red.withOpacity(0.1),
//       colorText: Colors.red,
//       icon: const Icon(Icons.error_outline, color: Colors.red),
//       duration: const Duration(seconds: 4),
//     );
//   }
  
//   String _extractErrorMessage(String error) {
//     if (error.contains('Exception:')) {
//       error = error.split('Exception:').last.trim();
//     }
    
//     if (error.contains('DioException')) {
//       return 'Erreur de connexion au serveur';
//     }
    
//     if (error.contains('connection')) {
//       return 'Vérifiez votre connexion Internet';
//     }
    
//     if (error.contains('401') || error.toLowerCase().contains('unauthorized')) {
//       return 'Numéro de téléphone ou mot de passe incorrect';
//     }
    
//     if (error.contains('500')) {
//       return 'Erreur serveur. Réessayez plus tard';
//     }
    
//     return error.length > 100 
//         ? 'Une erreur est survenue lors de la connexion'
//         : error;
//   }
  
//   void goToRegister() {
//     Get.toNamed(AppRoutes.REGISTER);
//   }
// }


