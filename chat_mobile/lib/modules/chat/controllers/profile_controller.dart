// lib/modules/chat/controllers/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../app/routes/app_routes.dart';

class ProfileController extends GetxController {
  // Services
  final AuthService _authService = Get.find<AuthService>();
  
  // Observables
  final isLoading = false.obs;
  final isLoggingOut = false.obs;
  
  // User info (depuis AuthService)
  get currentUser => _authService.currentUser.value;
  
  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }
  
  // ==================== CHARGER PROFIL ====================
  
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      
      // Charger les infos utilisateur depuis l'API
      await _authService.getCurrentUser();
      
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger le profil',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // ==================== DÉCONNEXION ====================
  
  Future<void> logout() async {
    // 1. Afficher dialog de confirmation
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Déconnexion'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Déconnexion'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    
    // 2. Si confirmé, procéder à la déconnexion
    if (confirmed == true) {
      try {
        isLoggingOut.value = true;
        
        // Afficher loading indicator
        Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Déconnexion en cours...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
        
        // 3. Appeler la déconnexion
        await _authService.logout();
        
        // 4. Fermer le loading dialog
        Get.back();
        
        // 5. Naviguer vers Login et vider la pile de navigation
        Get.offAllNamed(AppRoutes.LOGIN);
        
        // 6. Afficher message de succès
        // Get.snackbar(
        //   'Déconnexion réussie',
        //   'À bientôt !',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        //   icon: Icon(Icons.check_circle, color: Colors.white),
        // );
        
      } catch (e) {
        // Fermer le loading dialog en cas d'erreur
        Get.back();
        
        print('❌ Erreur logout: $e');
        Get.snackbar(
          'Erreur',
          'Impossible de se déconnecter',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoggingOut.value = false;
      }
    }
  }
  
  // ==================== NAVIGATION ====================
  
  void navigateToEditProfile() {
    Get.toNamed(AppRoutes.PROFILE_EDIT);
  }
  
  void navigateToSettings() {
    Get.toNamed(AppRoutes.SETTINGS);
  }
  
  void navigateToSessions() {
    // TODO: Implémenter la page des sessions
    Get.snackbar(
      'Info',
      'Gestion des sessions - En cours de développement',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void navigateToPrivacy() {
    // TODO: Implémenter la page de confidentialité
    Get.snackbar(
      'Info',
      'Confidentialité - En cours de développement',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}