// lib/modules/auth/controllers/register_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../app/routes/app_routes.dart';
import '../views/otp_verification_view.dart';
import 'otp_controller.dart';

class RegisterController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController usernameController;
  
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = ''.obs;
  final phoneE164 = ''.obs;
  final phoneIsValid = false.obs;
  final isPhoneVerified = false.obs;  // ← NOUVEAU
  
  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    usernameController = TextEditingController();
  }
  
  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.onClose();
  }
  
  void onPhoneChanged(String e164Number) {
    phoneE164.value = e164Number;
    phoneIsValid.value = PhoneFormatter.isValidPhoneNumber(e164Number);
    // Réinitialiser la vérification si le numéro change
    if (isPhoneVerified.value) {
      isPhoneVerified.value = false;
    }
  }
  
Future<void> sendOtpAndVerify() async {
  if (phoneE164.value.isEmpty || !phoneIsValid.value) {
    _showError('Numéro de téléphone invalide');
    return;
  }
  
  try {
    final otpController = Get.put(OtpController());
    await otpController.sendOtp(phoneE164.value);
    Get.to(() => const OtpVerificationView());
  } catch (e) {
    _showError('Erreur: ${_extractErrorMessage(e.toString())}');
  }
}
  
  /// Inscription (appelé après vérification OTP)
  Future<void> register() async {
    // Vérifier que le téléphone a été vérifié
    if (!isPhoneVerified.value) {
      _showError('Veuillez d\'abord vérifier votre numéro de téléphone');
      return;
    }
    
    if (usernameController.text.trim().isEmpty) {
      _showError('Le nom d\'utilisateur est requis');
      return;
    }
    
    if (usernameController.text.trim().length < 3) {
      _showError('Le nom doit contenir au moins 3 caractères');
      return;
    }
    
    if (passwordController.text.isEmpty) {
      _showError('Le mot de passe est requis');
      return;
    }
    
    if (passwordController.text.length < 8) {
      _showError('Le mot de passe doit contenir au moins 8 caractères');
      return;
    }
    
    try {
      errorMessage.value = '';
      isLoading.value = true;
      
      await _authService.register(
        phoneNumber: phoneE164.value,
        password: passwordController.text,
        username: usernameController.text.trim(),
        email: null,  // ← Toujours null maintenant
      );
      
      Get.offAllNamed(AppRoutes.MAIN_SHELL);
      
      // Get.snackbar(
      //   'Inscription réussie',
      //   'Bienvenue ${_authService.currentUser.value?.displayName ?? ""}',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green.withOpacity(0.1),
      //   colorText: Colors.green,
      //   icon: const Icon(Icons.check_circle, color: Colors.green),
      //   duration: const Duration(seconds: 3),
      // );
      
    } catch (e) {
      _showError(_extractErrorMessage(e.toString()));
    } finally {
      isLoading.value = false;
    }
  }
  
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  void _showError(String message) {
    errorMessage.value = message;
    Get.snackbar(
      '',
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
    
    if (error.contains('400')) {
      return 'Données invalides. Vérifiez vos informations';
    }
    
    if (error.contains('403')) {
      return 'Numéro de téléphone non vérifié';
    }
    
    if (error.contains('409') || error.toLowerCase().contains('already exists')) {
      return 'Ce numéro de téléphone est déjà utilisé';
    }
    
    if (error.contains('500')) {
      return 'Erreur serveur. Réessayez plus tard';
    }
    
    return error.length > 100 
        ? 'Une erreur est survenue lors de l\'inscription'
        : error;
  }
  
  void goToLogin() {
    Get.back();
  }
}


