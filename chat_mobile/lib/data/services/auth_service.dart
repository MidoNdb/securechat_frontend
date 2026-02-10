// lib/data/services/auth_service.dart

import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'secure_storage_service.dart';
import 'crypto_service.dart';
import '../models/auth_data.dart';
import '../models/user.dart';
import '../api/dio_client.dart';
import '../api/api_endpoints.dart';

class AuthService extends GetxService {
  late final SecureStorageService _storage;
  late final DioClient _dio;
  late final CryptoService _crypto;

  final RxBool isLoading = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<SecureStorageService>();
    _dio = Get.find<DioClient>();
    _crypto = CryptoService();
  }

  // ==================== REGISTER ====================
  Future<void> register({
    required String phoneNumber,
    required String password,
    required String username,
    String? email,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      print('🚀 Inscription...');
      
      // 1. Device ID
      String? deviceId = await _storage.getDeviceId();
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await _storage.saveDeviceId(deviceId);
      }

      // 2. Génération clés via CryptoService
      print('🔐 Génération clés...');
      final keys = await _crypto.generateAllKeys();

      // 3. Sauvegarder les clés privées localement
      await _storage.saveDHPrivateKey(keys['dh_private_key']!);
      await _storage.saveSignPrivateKey(keys['sign_private_key']!);
      print('✅ Clés privées sauvegardées localement');

      // 4. Créer backup chiffré des clés privées
      print('🔐 Création backup chiffré...');
      final encryptedBackup = await _createEncryptedKeysBackup(
        dhPrivateKey: keys['dh_private_key']!,
        signPrivateKey: keys['sign_private_key']!,
        password: password,
      );
      
      // Sauvegarder le backup localement aussi
      await _storage.saveEncryptedKeysBackup(encryptedBackup);

      // 5. Hash password
      final hashedPassword = _crypto.hashString(password);

      // 6. Appel API
      print('📡 Envoi au serveur...');
      final response = await _dio.postPublic(
        ApiEndpoints.register,
        data: {
          'phone_number': phoneNumber,
          'password': hashedPassword,
          'display_name': username,
          'dh_public_key': keys['dh_public_key']!,
          'sign_public_key': keys['sign_public_key']!,
          'encrypted_private_keys': encryptedBackup, // Backup envoyé au serveur
          'device_id': deviceId,
          'device_name': await _getDeviceName(),
          'device_type': _getDeviceType(),
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      // 7. Traitement réponse
      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        final authData = AuthData(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
          userId: data['user']['user_id'],
          deviceId: deviceId,
          dhPrivateKey: keys['dh_private_key']!,
          signPrivateKey: keys['sign_private_key']!,
        );

        currentUser.value = User.fromJson(data['user']);
        await _storage.saveAuthData(authData);
        
        print('✅ Inscription réussie avec backup');
      } else {
        throw Exception(response.data['error']['message'] ?? 'Erreur inconnue');
      }

    } catch (e) {
      print('❌ Erreur: $e');
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOGIN ====================
Future<Map<String, dynamic>> login({
  required String phoneNumber,
  required String password,
  String? newDhPublicKey,
  String? newSignPublicKey,
  bool confirmedKeyRegeneration = false,
}) async {
  try {
    isLoading.value = true;
    errorMessage.value = '';
    
    print('🔑 Connexion...');
    
    String? deviceId = await _storage.getDeviceId();
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.saveDeviceId(deviceId);
    }

    // Vérifier si on a déjà les clés localement
    final hasLocalKeys = await _storage.hasPrivateKeys();
    print('📱 Clés locales: ${hasLocalKeys ? "✅ présentes" : "❌ absentes"}');

    final hashedPassword = _crypto.hashString(password);

    final response = await _dio.postPublic(
      ApiEndpoints.login,
      data: {
        'phone_number': phoneNumber,
        'password': hashedPassword,
        'device_id': deviceId,
        'device_name': await _getDeviceName(),
        'device_type': _getDeviceType(),
        if (newDhPublicKey != null) 'new_dh_public_key': newDhPublicKey,
        if (newSignPublicKey != null) 'new_sign_public_key': newSignPublicKey,
        'confirmed_key_regeneration': confirmedKeyRegeneration,
      },
    );

    if (response.data['success'] == true) {
      final data = response.data['data'];
      
      await _storage.saveTokens(
        data['tokens']['access'],
        data['tokens']['refresh'],
      );
      await _storage.saveDeviceId(deviceId);
      
      currentUser.value = User.fromJson(data['user']);
      await _storage.saveUserId(currentUser.value!.userId);
      
      final hasBackup = data['has_backup'] == true;
      print('📦 Backup serveur: ${hasBackup ? "✅ disponible" : "❌ absent"}');
      
      // Cas 1: Clés locales présentes → Tout va bien
      if (hasLocalKeys) {
        print('✅ Connexion réussie avec clés locales');
        return {
          'success': true,
        };
      }
      
      // Cas 2: Pas de clés locales + Backup disponible → Récupération
      if (hasBackup) {
        print('⚠️ Clés locales manquantes - Récupération backup...');
        return {
          'success': true,
          'requires_key_recovery': true,
          'has_backup': true,
        };
      }
      
      // Cas 3: Pas de clés locales + Pas de backup → Régénération obligatoire
      print('⚠️ Clés locales ET backup manquants - Régénération nécessaire');
      return {
        'success': true,
        'requires_key_regeneration': true,
        'has_backup': false,
        'message': 'Aucune clé disponible. Régénération nécessaire.',
      };
      
    } else {
      throw Exception(response.data['error']['message'] ?? 'Erreur inconnue');
    }

  } catch (e) {
    print('❌ Erreur: $e');
    errorMessage.value = e.toString();
    rethrow;
  } finally {
    isLoading.value = false;
  }
}

// ==================== RÉGÉNÉRER CLÉS ET CRÉER BACKUP ====================
Future<bool> regenerateKeysAndCreateBackup(String password) async {
  try {
    print('🔄 Régénération clés + création backup...');
    
    // 1. Générer nouvelles clés
    final keys = await _crypto.generateAllKeys();
    
    // 2. Sauvegarder localement
    await _storage.saveDHPrivateKey(keys['dh_private_key']!);
    await _storage.saveSignPrivateKey(keys['sign_private_key']!);
    
    // 3. Créer backup chiffré
    final encryptedBackup = await _createEncryptedKeysBackup(
      dhPrivateKey: keys['dh_private_key']!,
      signPrivateKey: keys['sign_private_key']!,
      password: password,
    );
    
    // 4. Sauvegarder backup localement
    await _storage.saveEncryptedKeysBackup(encryptedBackup);
    
    // 5. Uploader backup sur serveur
    final uploadSuccess = await _uploadBackupToServer(encryptedBackup);
    
    if (!uploadSuccess) {
      print('⚠️ Échec upload backup, mais clés locales OK');
    }
    
    // 6. Mettre à jour les clés publiques sur le serveur
    final updateSuccess = await _updatePublicKeysOnServer(
      keys['dh_public_key']!,
      keys['sign_public_key']!,
    );
    
    if (!updateSuccess) {
      print('⚠️ Échec mise à jour clés publiques');
      return false;
    }
    
    print('✅ Régénération + backup créés avec succès');
    return true;
    
  } catch (e) {
    print('❌ Erreur regenerateKeysAndCreateBackup: $e');
    return false;
  }
}

/// Upload backup sur serveur
Future<bool> _uploadBackupToServer(String encryptedBackup) async {
  try {
    final response = await _dio.post(
      ApiEndpoints.uploadEncryptedKeys,
      data: {'encrypted_private_keys': encryptedBackup},
    );
    
    return response.data['success'] == true;
  } catch (e) {
    print('❌ Erreur upload backup: $e');
    return false;
  }
}

/// Mettre à jour les clés publiques sur le serveur
Future<bool> _updatePublicKeysOnServer(String dhPublicKey, String signPublicKey) async {
  try {
    final response = await _dio.post(
      ApiEndpoints.uploadPublicKeys,
      data: {
        'dh_public_key': dhPublicKey,
        'sign_public_key': signPublicKey,
      },
    );
    
    return response.data['success'] == true;
  } catch (e) {
    print('❌ Erreur mise à jour clés publiques: $e');
    return false;
  }
}

  // ==================== BACKUP DES CLÉS ====================
  
  /// Créer un backup chiffré des clés privées avec le mot de passe
  Future<String> _createEncryptedKeysBackup({
    required String dhPrivateKey,
    required String signPrivateKey,
    required String password,
  }) async {
    try {
      // Combiner les deux clés privées
      final keysJson = jsonEncode({
        'dh_private_key': dhPrivateKey,
        'sign_private_key': signPrivateKey,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Chiffrer avec le mot de passe (utilise PBKDF2 en interne)
      final encrypted = await _crypto.encryptWithPassword(
        plaintext: keysJson,
        password: password,
      );
      
      return encrypted;
    } catch (e) {
      print('❌ Erreur création backup: $e');
      rethrow;
    }
  }

  /// Récupérer les clés depuis le backup chiffré
  Future<Map<String, String>> _decryptKeysBackup({
    required String encryptedBackup,
    required String password,
  }) async {
    try {
      // Déchiffrer avec le mot de passe
      final decrypted = await _crypto.decryptWithPassword(
        ciphertext: encryptedBackup,
        password: password,
      );
      
      final keysData = jsonDecode(decrypted) as Map<String, dynamic>;
      
      return {
        'dh_private_key': keysData['dh_private_key'] as String,
        'sign_private_key': keysData['sign_private_key'] as String,
      };
    } catch (e) {
      print('❌ Erreur déchiffrement backup: $e');
      rethrow;
    }
  }

  /// Vérifier si un backup existe sur le serveur
  Future<bool> _checkBackupExists() async {
    try {
      final response = await _dio.get(ApiEndpoints.downloadEncryptedKeys);
      return response.data['success'] == true && 
             response.data['data']?['encrypted_private_keys'] != null;
    } catch (e) {
      print('⚠️ Pas de backup disponible: $e');
      return false;
    }
  }

  /// Récupérer le backup depuis le serveur et restaurer les clés
  Future<bool> recoverKeysFromBackup(String password) async {
    try {
      print('🔄 Récupération backup serveur...');
      
      final response = await _dio.get(ApiEndpoints.downloadEncryptedKeys);
      
      if (response.data['success'] == true) {
        final encryptedBackup = response.data['data']['encrypted_private_keys'] as String;
        
        print('🔓 Déchiffrement backup...');
        final keys = await _decryptKeysBackup(
          encryptedBackup: encryptedBackup,
          password: password,
        );
        
        // Sauvegarder les clés localement
        await _storage.saveDHPrivateKey(keys['dh_private_key']!);
        await _storage.saveSignPrivateKey(keys['sign_private_key']!);
        await _storage.saveEncryptedKeysBackup(encryptedBackup);
        
        print('✅ Clés récupérées et sauvegardées');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur récupération backup: $e');
      return false;
    }
  }

  /// Envoyer/Mettre à jour le backup sur le serveur
  Future<bool> uploadKeysBackup(String password) async {
    try {
      final dhKey = await _storage.getDHPrivateKey();
      final signKey = await _storage.getSignPrivateKey();
      
      if (dhKey == null || signKey == null) {
        print('❌ Clés privées manquantes');
        return false;
      }
      
      final encryptedBackup = await _createEncryptedKeysBackup(
        dhPrivateKey: dhKey,
        signPrivateKey: signKey,
        password: password,
      );
      
      final response = await _dio.post(
        ApiEndpoints.uploadEncryptedKeys,
        data: {'encrypted_private_keys': encryptedBackup},
      );
      
      if (response.data['success'] == true) {
        await _storage.saveEncryptedKeysBackup(encryptedBackup);
        print('✅ Backup uploadé');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur upload backup: $e');
      return false;
    }
  }

  // ==================== RÉGÉNÉRER CLÉS (dernier recours) ====================
  Future<Map<String, String>> regenerateKeys() async {
    print('🔄 Régénération clés (DERNIER RECOURS)...');
    final keys = await _crypto.generateAllKeys();
    
    await _storage.saveDHPrivateKey(keys['dh_private_key']!);
    await _storage.saveSignPrivateKey(keys['sign_private_key']!);
    
    return {
      'dh_public_key': keys['dh_public_key']!,
      'sign_public_key': keys['sign_public_key']!,
    };
  }

  // ==================== LOGOUT ====================
  Future<void> logout() async {
    try {
      final accessToken = await _storage.getAccessToken();
      
      if (accessToken != null) {
        try {
          await _dio.post(ApiEndpoints.logout);
        } catch (e) {
          print('⚠️ Erreur logout API: $e');
        }
      }
    } catch (e) {
      print('⚠️ Erreur logout: $e');
    } finally {
      await _storage.clearAuth();
      currentUser.value = null;
      print('✅ Déconnecté');
    }
  }

  // ==================== GET CURRENT USER ====================
  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      
      if (response.data['success'] == true) {
        currentUser.value = User.fromJson(response.data['data']);
        return currentUser.value;
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  // ==================== HELPERS ====================

  Future<bool> isAuthenticated() async {
    return await _storage.isAuthenticated();
  }

  Future<bool> hasPrivateKeys() async {
    return await _storage.hasPrivateKeys();
  }

  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<String?> getUserId() async {
    return await _storage.getUserId();
  }

  Future<String> _getDeviceName() async {
    return 'Flutter Device';
  }

  String _getDeviceType() {
    return 'android';
  }
}







