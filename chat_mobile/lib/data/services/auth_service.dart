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
    _crypto = Get.find<CryptoService>();
  }

  Future<void> register({
    required String phoneNumber,
    required String password,
    required String username,
    String? email,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Device ID
      String deviceId = await _storage.getDeviceId() ?? const Uuid().v4();
      await _storage.saveDeviceId(deviceId);

      // Génération clés (DH + Sign en parallèle dans CryptoService)
      final keys = await _crypto.generateAllKeys();

      // Sauvegarder clés privées localement
      await Future.wait([
        _storage.saveDHPrivateKey(keys['dh_private_key']!),
        _storage.saveSignPrivateKey(keys['sign_private_key']!),
      ]);

      // Créer backup chiffré
      final encryptedBackup = await _createEncryptedKeysBackup(
        dhPrivateKey: keys['dh_private_key']!,
        signPrivateKey: keys['sign_private_key']!,
        password: password,
      );
      await _storage.saveEncryptedKeysBackup(encryptedBackup);

      // Hash password
      final hashedPassword = _crypto.hashString(password);

      // Appel API
      final response = await _dio.postPublic(
        ApiEndpoints.register,
        data: {
          'phone_number': phoneNumber,
          'password': hashedPassword,
          'display_name': username,
          'dh_public_key': keys['dh_public_key']!,
          'sign_public_key': keys['sign_public_key']!,
          'encrypted_private_keys': encryptedBackup,
          'device_id': deviceId,
          'device_name': 'Flutter Device',
          'device_type': _getDeviceType(),
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

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
      } else {
        throw Exception(response.data['error']['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

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

      String deviceId = await _storage.getDeviceId() ?? const Uuid().v4();
      await _storage.saveDeviceId(deviceId);

      final hasLocalKeys = await _storage.hasPrivateKeys();
      final hashedPassword = _crypto.hashString(password);

      final response = await _dio.postPublic(
        ApiEndpoints.login,
        data: {
          'phone_number': phoneNumber,
          'password': hashedPassword,
          'device_id': deviceId,
          'device_name': 'Flutter Device',
          'device_type': _getDeviceType(),
          if (newDhPublicKey != null) 'new_dh_public_key': newDhPublicKey,
          if (newSignPublicKey != null) 'new_sign_public_key': newSignPublicKey,
          'confirmed_key_regeneration': confirmedKeyRegeneration,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']['message'] ?? 'Erreur inconnue');
      }

      final data = response.data['data'];

      await _storage.saveTokens(data['tokens']['access'], data['tokens']['refresh']);
      await _storage.saveDeviceId(deviceId);

      currentUser.value = User.fromJson(data['user']);
      await _storage.saveUserId(currentUser.value!.userId);

      final hasBackup = data['has_backup'] == true;

      // Cas 1: Clés locales présentes
      if (hasLocalKeys) {
        // Pré-charger le cache pour accélérer les opérations suivantes
        await _storage.preloadKeys();
        return {'success': true};
      }

      // Cas 2: Pas de clés locales + Backup disponible
      if (hasBackup) {
        return {
          'success': true,
          'requires_key_recovery': true,
          'has_backup': true,
        };
      }

      // Cas 3: Pas de clés locales + Pas de backup
      return {
        'success': true,
        'requires_key_regeneration': true,
        'has_backup': false,
        'message': 'Aucune clé disponible. Régénération nécessaire.',
      };
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> regenerateKeysAndCreateBackup(String password) async {
    try {
      final keys = await _crypto.generateAllKeys();

      await Future.wait([
        _storage.saveDHPrivateKey(keys['dh_private_key']!),
        _storage.saveSignPrivateKey(keys['sign_private_key']!),
      ]);

      final encryptedBackup = await _createEncryptedKeysBackup(
        dhPrivateKey: keys['dh_private_key']!,
        signPrivateKey: keys['sign_private_key']!,
        password: password,
      );

      await _storage.saveEncryptedKeysBackup(encryptedBackup);

      // Upload backup + mise à jour clés publiques en parallèle
      final results = await Future.wait([
        _uploadBackupToServer(encryptedBackup),
        _updatePublicKeysOnServer(keys['dh_public_key']!, keys['sign_public_key']!),
      ]);

      // Invalider les caches crypto puisque les clés ont changé
      _crypto.invalidateCache();

      return results[1]; // La mise à jour des clés publiques est critique
    } catch (e) {
      return false;
    }
  }

  Future<bool> _uploadBackupToServer(String encryptedBackup) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.uploadEncryptedKeys,
        data: {'encrypted_private_keys': encryptedBackup},
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

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
      return false;
    }
  }

  Future<String> _createEncryptedKeysBackup({
    required String dhPrivateKey,
    required String signPrivateKey,
    required String password,
  }) async {
    final keysJson = jsonEncode({
      'dh_private_key': dhPrivateKey,
      'sign_private_key': signPrivateKey,
      'created_at': DateTime.now().toIso8601String(),
    });

    return await _crypto.encryptWithPassword(
      plaintext: keysJson,
      password: password,
    );
  }

  Future<Map<String, String>> _decryptKeysBackup({
    required String encryptedBackup,
    required String password,
  }) async {
    final decrypted = await _crypto.decryptWithPassword(
      ciphertext: encryptedBackup,
      password: password,
    );

    final keysData = jsonDecode(decrypted) as Map<String, dynamic>;
    return {
      'dh_private_key': keysData['dh_private_key'] as String,
      'sign_private_key': keysData['sign_private_key'] as String,
    };
  }

  Future<bool> recoverKeysFromBackup(String password) async {
    try {
      final response = await _dio.get(ApiEndpoints.downloadEncryptedKeys);

      if (response.data['success'] == true) {
        final encryptedBackup =
            response.data['data']['encrypted_private_keys'] as String;

        final keys = await _decryptKeysBackup(
          encryptedBackup: encryptedBackup,
          password: password,
        );

        await Future.wait([
          _storage.saveDHPrivateKey(keys['dh_private_key']!),
          _storage.saveSignPrivateKey(keys['sign_private_key']!),
          _storage.saveEncryptedKeysBackup(encryptedBackup),
        ]);

        // Pré-charger le cache maintenant que les clés sont disponibles
        await _storage.preloadKeys();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadKeysBackup(String password) async {
    try {
      final dhKey = await _storage.getDHPrivateKey();
      final signKey = await _storage.getSignPrivateKey();

      if (dhKey == null || signKey == null) return false;

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
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>> regenerateKeys() async {
    final keys = await _crypto.generateAllKeys();

    await Future.wait([
      _storage.saveDHPrivateKey(keys['dh_private_key']!),
      _storage.saveSignPrivateKey(keys['sign_private_key']!),
    ]);

    _crypto.invalidateCache();

    return {
      'dh_public_key': keys['dh_public_key']!,
      'sign_public_key': keys['sign_public_key']!,
    };
  }


  Future<void> logout() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null) {
        try {
          await _dio.post(ApiEndpoints.logout);
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      _crypto.invalidateCache();
      await _storage.clearAuth();
      currentUser.value = null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      if (response.data['success'] == true) {
        currentUser.value = User.fromJson(response.data['data']);
        return currentUser.value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async => await _storage.isAuthenticated();

  Future<bool> hasPrivateKeys() async => await _storage.hasPrivateKeys();

  Future<String?> getAccessToken() async => await _storage.getAccessToken();

  Future<String?> getUserId() async => await _storage.getUserId();

  String _getDeviceType() => 'android';
}