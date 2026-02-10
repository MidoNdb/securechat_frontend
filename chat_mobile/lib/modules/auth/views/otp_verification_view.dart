// lib/modules/auth/views/otp_verification_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/otp_controller.dart';
import '../controllers/register_controller.dart';

class OtpVerificationView extends StatelessWidget {
  const OtpVerificationView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OtpController>();
    final registerController = Get.find<RegisterController>();
    
    return WillPopScope(
      onWillPop: () async {
        // ✅ Supprimer seulement lors du retour arrière
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isRegistered<OtpController>()) {
            Get.delete<OtpController>();
          }
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vérification'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                
                Icon(
                  Icons.sms_outlined,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Vérifiez votre numéro',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 6),
                
                Obx(() => Text(
                  'Code envoyé à ${controller.phoneNumber.value}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                )),
                
                const SizedBox(height: 28),
                
                TextField(
                  controller: controller.codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 8,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[300],
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                  onSubmitted: (_) async {
                    final success = await controller.verifyOtpSimple();
                    if (success) {
                      registerController.isPhoneVerified.value = true;
                      Navigator.of(context).pop();
                      // ✅ Supprimer après fermeture
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (Get.isRegistered<OtpController>()) {
                          Get.delete<OtpController>();
                        }
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 20),
                
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          final success = await controller.verifyOtpSimple();
                          if (success) {
                            registerController.isPhoneVerified.value = true;
                            Navigator.of(context).pop();
                            // ✅ Supprimer APRÈS fermeture
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (Get.isRegistered<OtpController>()) {
                                Get.delete<OtpController>();
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )),
                
                const SizedBox(height: 16),
                
                Obx(() {
                  if (controller.canResend.value) {
                    return TextButton.icon(
                      onPressed: () => controller.sendOtp(controller.phoneNumber.value),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Renvoyer le code'),
                    );
                  } else {
                    return Text(
                      'Renvoyer dans ${controller.countdown.value}s',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    );
                  }
                }),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}