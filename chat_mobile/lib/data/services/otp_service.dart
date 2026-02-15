// lib/data/services/otp_service.dart

import 'package:get/get.dart';

import '../api/api_endpoints.dart';
import '../api/dio_client.dart';



class OtpService extends GetxService {
  final DioClient _dioClient = Get.find<DioClient>();
  
  /// Envoie un code OTP par SMS
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await _dioClient.post(
      ApiEndpoints.sendOtp(),
      data: {'phone_number': phoneNumber},
    );
    return response.data;
  }
  
  /// Vérifie le code OTP
  ///  CORRECTION: Retourner la réponse complète
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String code) async {
    final response = await _dioClient.post(
      ApiEndpoints.verifyOtp(),
      data: {
        'phone_number': phoneNumber,
        'code': code,
      },
    );
    
    // Retourner la réponse complète
    return response.data;
  }
}