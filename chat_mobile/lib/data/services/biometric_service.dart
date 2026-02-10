// lib/data/services/biometric_service.dart

import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';

class BiometricService extends GetxService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> isBiometricAvailable() async {
    try {
      final deviceSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();
      final types = await getAvailableBiometrics();
      
      print('📱 Device supporté: $deviceSupported');
      print('🔍 Peut vérifier: $canCheck');
      print('🔐 Types dispo: $types');
      
      return deviceSupported && canCheck && types.isNotEmpty;
    } catch (e) {
      print('❌ Erreur biométrie: $e');
      return false;
    }
  }
  
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  Future<BiometricResult> authenticateWithFallback() async {
    try {
      final isAvailable = await isBiometricAvailable();
      
      if (!isAvailable) {
        final deviceSupported = await isDeviceSupported();
        
        if (!deviceSupported) {
          print('⚠️ Appareil sans biométrie - Accès autorisé');
          return BiometricResult.notAvailable;
        } else {
          print('⚠️ Biométrie non configurée');
          return BiometricResult.notConfigured;
        }
      }
      
      print('🔐 Demande authentification biométrique...');
      
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à SecureChat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (authenticated) {
        print('✅ Authentification réussie');
        return BiometricResult.success;
      } else {
        print('❌ Authentification échouée');
        return BiometricResult.failed;
      }
      
    } catch (e) {
      print('❌ Erreur authentification: $e');
      return BiometricResult.error;
    }
  }
  
  // Ancienne méthode (garder pour compatibilité)
  Future<bool> authenticate() async {
    final result = await authenticateWithFallback();
    return result == BiometricResult.success || 
           result == BiometricResult.notAvailable ||
           result == BiometricResult.error;
  }
}

enum BiometricResult {
  success,
  failed,
  notAvailable,
  notConfigured,
  error,
}