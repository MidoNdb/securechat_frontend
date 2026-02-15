
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/otp_service.dart';

class OtpController extends GetxController {
  final OtpService _otpService = Get.find<OtpService>();
  
  late final TextEditingController codeController;
  
  final isLoading = false.obs;
  final isSendingOtp = false.obs;
  final phoneNumber = ''.obs;
  final phoneNumberClean = ''.obs;
  final canResend = false.obs;
  final countdown = 60.obs;
  
  Function()? onVerificationSuccess;
  
  @override
  void onInit() {
    super.onInit();
    codeController = TextEditingController();
  }
  
  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
  
  String extractLocalNumber(String e164Phone) {
    final digitsOnly = e164Phone.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.startsWith('222') && digitsOnly.length == 11) {
      return digitsOnly.substring(3);
    }
    
    if (digitsOnly.length == 8) {
      return digitsOnly;
    }
    
    if (digitsOnly.length > 8) {
      return digitsOnly.substring(digitsOnly.length - 8);
    }
    
    return digitsOnly;
  }
  
  void startCountdown() {
    canResend.value = false;
    countdown.value = 60;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      countdown.value--;
      
      if (countdown.value <= 0) {
        canResend.value = true;
        return false;
      }
      return true;
    });
  }
  
  Future<void> sendOtp(String phone) async {
    try {
      isSendingOtp.value = true;
      phoneNumber.value = phone;
      phoneNumberClean.value = extractLocalNumber(phone);
      
      await _otpService.sendOtp(phoneNumberClean.value);
      
      startCountdown();
      
    } catch (e) {
      Get.snackbar(
        '',
        'Impossible d\'envoyer le code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.red),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSendingOtp.value = false;
    }
  }
  
// lib/modules/auth/controllers/otp_controller.dart

Future<bool> verifyOtpSimple() async {
  final code = codeController.text.trim();
  
  if (code.length != 6) {
    Get.snackbar('', 'Le code doit contenir 6 chiffres');
    return false;
  }
  
  try {
    isLoading.value = true;
    
    final response = await _otpService.verifyOtp(phoneNumberClean.value, code);
    
    if (response['success'] == true) {
      
      
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } else {
      Get.snackbar('', 'Code incorrect');
      return false;
    }
    
  } catch (e) {
   
    return false;
  } finally {
    isLoading.value = false;
  }
}
}