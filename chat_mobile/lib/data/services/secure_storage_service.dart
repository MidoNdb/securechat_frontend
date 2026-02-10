// lib/data/services/secure_storage_service.dart
// ✅ VERSION FINALE ANDROID - Cache + PreloadKeys = Pas de biométrie répétée

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_data.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  late final FlutterSecureStorage _storage;

  // ✅ Cache en mémoire pour éviter biométrie répétée
  String? _cachedDhPrivateKey;
  String? _cachedSignPrivateKey;
  String? _cachedUserId;
  String? _cachedDeviceId;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _cacheInitialized = false;

  Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // ✅ PRÉ-CHARGER LES CLÉS (Biométrie UNE SEULE FOIS)
  Future<void> preloadKeys() async {
    if (_cacheInitialized) {
      print('✅ Clés déjà en cache');
      return;
    }
    
    print('🔐 Pré-chargement des clés E2EE (biométrie demandée)...');
    
    try {
      // Charger toutes les clés en une seule fois
      final values = await Future.wait([
        _storage.read(key: 'dh_private_key'),
        _storage.read(key: 'sign_private_key'),
        _storage.read(key: 'user_id'),
        _storage.read(key: 'device_id'),
        _storage.read(key: 'access_token'),
        _storage.read(key: 'refresh_token'),
      ]);
      
      _cachedDhPrivateKey = values[0];
      _cachedSignPrivateKey = values[1];
      _cachedUserId = values[2];
      _cachedDeviceId = values[3];
      _cachedAccessToken = values[4];
      _cachedRefreshToken = values[5];
      _cacheInitialized = true;
      
      print('✅ Clés en cache, plus de biométrie pour cette session !');
      
    } catch (e) {
      print('❌ Erreur preloadKeys: $e');
      _cacheInitialized = false;
    }
  }

  // ==================== SAVE METHODS ====================

  Future<void> saveAuthData(AuthData authData) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: authData.accessToken),
      _storage.write(key: 'refresh_token', value: authData.refreshToken),
      _storage.write(key: 'user_id', value: authData.userId),
      _storage.write(key: 'device_id', value: authData.deviceId),
      _storage.write(key: 'dh_private_key', value: authData.dhPrivateKey),
      _storage.write(key: 'sign_private_key', value: authData.signPrivateKey),
    ]);
    
    // ✅ Mettre en cache immédiatement
    _cachedAccessToken = authData.accessToken;
    _cachedRefreshToken = authData.refreshToken;
    _cachedUserId = authData.userId;
    _cachedDeviceId = authData.deviceId;
    _cachedDhPrivateKey = authData.dhPrivateKey;
    _cachedSignPrivateKey = authData.signPrivateKey;
    _cacheInitialized = true;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
    ]);
    
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
    _cachedUserId = userId;
    print('💾 User ID saved: $userId');
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: 'device_id', value: deviceId);
    _cachedDeviceId = deviceId;
  }

  Future<void> saveDHPrivateKey(String dhPrivateKey) async {
    await _storage.write(key: 'dh_private_key', value: dhPrivateKey);
    _cachedDhPrivateKey = dhPrivateKey;
  }

  Future<void> saveSignPrivateKey(String signPrivateKey) async {
    await _storage.write(key: 'sign_private_key', value: signPrivateKey);
    _cachedSignPrivateKey = signPrivateKey;
  }

  Future<void> saveMessagePlaintext(String messageId, String plaintext) async {
    await _storage.write(key: 'msg_plain_$messageId', value: plaintext);
  }

  Future<void> saveEncryptedKeysBackup(String encryptedBackup) async {
    await _storage.write(key: 'encrypted_keys_backup', value: encryptedBackup);
    print('💾 Backup des clés chiffrées sauvegardé');
  }

  // ==================== GET METHODS AVEC CACHE ====================

  Future<String?> getDHPrivateKey() async {
    // ✅ Retourner depuis cache si disponible
    if (_cacheInitialized && _cachedDhPrivateKey != null) {
      return _cachedDhPrivateKey;
    }
    
    // Sinon lire depuis storage (biométrie)
    final key = await _storage.read(key: 'dh_private_key');
    _cachedDhPrivateKey = key;
    return key;
  }

  Future<String?> getSignPrivateKey() async {
    // ✅ Retourner depuis cache si disponible
    if (_cacheInitialized && _cachedSignPrivateKey != null) {
      return _cachedSignPrivateKey;
    }
    
    // Sinon lire depuis storage (biométrie)
    final key = await _storage.read(key: 'sign_private_key');
    _cachedSignPrivateKey = key;
    return key;
  }

  Future<String?> getUserId() async {
    if (_cacheInitialized && _cachedUserId != null) {
      return _cachedUserId;
    }
    
    final userId = await _storage.read(key: 'user_id');
    _cachedUserId = userId;
    print('📖 User ID retrieved: $userId');
    return userId;
  }

  Future<String?> getAccessToken() async {
    if (_cacheInitialized && _cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    
    final token = await _storage.read(key: 'access_token');
    _cachedAccessToken = token;
    return token;
  }

  Future<String?> getRefreshToken() async {
    if (_cacheInitialized && _cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }
    
    final token = await _storage.read(key: 'refresh_token');
    _cachedRefreshToken = token;
    return token;
  }

  Future<String?> getDeviceId() async {
    if (_cacheInitialized && _cachedDeviceId != null) {
      return _cachedDeviceId;
    }
    
    final deviceId = await _storage.read(key: 'device_id');
    _cachedDeviceId = deviceId;
    return deviceId;
  }

  Future<String?> getEncryptedKeysBackup() async {
    return await _storage.read(key: 'encrypted_keys_backup');
  }

  Future<String?> getMessagePlaintext(String messageId) async {
    return await _storage.read(key: 'msg_plain_$messageId');
  }

  Future<AuthData?> getAuthData() async {
    final values = await Future.wait([
      getAccessToken(),
      getRefreshToken(),
      getUserId(),
      getDeviceId(),
      getDHPrivateKey(),
      getSignPrivateKey(),
    ]);

    if (values.any((v) => v == null)) return null;

    return AuthData(
      accessToken: values[0]!,
      refreshToken: values[1]!,
      userId: values[2]!,
      deviceId: values[3]!,
      dhPrivateKey: values[4]!,
      signPrivateKey: values[5]!,
    );
  }

  // ==================== VERIFICATION ====================

  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final dhKey = await getDHPrivateKey();
    final signKey = await getSignPrivateKey();
    return accessToken != null && dhKey != null && signKey != null;
  }

  Future<bool> hasPrivateKeys() async {
    final dhKey = await getDHPrivateKey();
    final signKey = await getSignPrivateKey();
    return dhKey != null && signKey != null;
  }

  Future<bool> hasDHPrivateKey() async {
    final dhKey = await getDHPrivateKey();
    return dhKey != null;
  }

  Future<bool> hasSignPrivateKey() async {
    final signKey = await getSignPrivateKey();
    return signKey != null;
  }

  // ==================== CLEAR ====================

  Future<void> deleteEncryptedKeysBackup() async {
    await _storage.delete(key: 'encrypted_keys_backup');
  }

  Future<void> clearAuth() async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
      _storage.delete(key: 'user_id'),
      _storage.delete(key: 'device_id'),
      _storage.delete(key: 'dh_private_key'),
      _storage.delete(key: 'sign_private_key'),
    ]);
    
    // ✅ Vider le cache
    _cachedDhPrivateKey = null;
    _cachedSignPrivateKey = null;
    _cachedUserId = null;
    _cachedDeviceId = null;
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cacheInitialized = false;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    
    // ✅ Vider le cache
    _cachedDhPrivateKey = null;
    _cachedSignPrivateKey = null;
    _cachedUserId = null;
    _cachedDeviceId = null;
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cacheInitialized = false;
  }
}





// // lib/data/services/secure_storage_service.dart

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../models/auth_data.dart';

// class SecureStorageService {
//   static final SecureStorageService _instance = SecureStorageService._internal();
//   factory SecureStorageService() => _instance;
//   SecureStorageService._internal();

//   late final FlutterSecureStorage _storage;

//   Future<void> init() async {
//     _storage = const FlutterSecureStorage(
//       aOptions: AndroidOptions(
//         encryptedSharedPreferences: true,
//         resetOnError: true,
//       ),
//       iOptions: IOSOptions(
//         accessibility: KeychainAccessibility.first_unlock_this_device,
//       ),
//     );
//   }

//   Future<void> saveAuthData(AuthData authData) async {
//     await Future.wait([
//       _storage.write(key: 'access_token', value: authData.accessToken),
//       _storage.write(key: 'refresh_token', value: authData.refreshToken),
//       _storage.write(key: 'user_id', value: authData.userId),
//       _storage.write(key: 'device_id', value: authData.deviceId),
//       _storage.write(key: 'dh_private_key', value: authData.dhPrivateKey),
//       _storage.write(key: 'sign_private_key', value: authData.signPrivateKey),
//     ]);
//   }

//   Future<void> saveTokens(String accessToken, String refreshToken) async {
//     await Future.wait([
//       _storage.write(key: 'access_token', value: accessToken),
//       _storage.write(key: 'refresh_token', value: refreshToken),
//     ]);
//   }

//   Future<void> saveUserId(String userId) async {
//     await _storage.write(key: 'user_id', value: userId);
//     print('💾 User ID saved: $userId');
//   }

//   Future<void> saveDeviceId(String deviceId) async {
//     await _storage.write(key: 'device_id', value: deviceId);
//   }

//   Future<void> saveDHPrivateKey(String dhPrivateKey) async {
//     await _storage.write(key: 'dh_private_key', value: dhPrivateKey);
//   }

//   Future<void> saveSignPrivateKey(String signPrivateKey) async {
//     await _storage.write(key: 'sign_private_key', value: signPrivateKey);
//   }

//   Future<void> saveMessagePlaintext(String messageId, String plaintext) async {
//     await _storage.write(key: 'msg_plain_$messageId', value: plaintext);
//   }

//   // ========== NOUVEAU: Backup des clés privées ==========
  
//   /// Sauvegarde le backup chiffré des clés privées
//   Future<void> saveEncryptedKeysBackup(String encryptedBackup) async {
//     await _storage.write(key: 'encrypted_keys_backup', value: encryptedBackup);
//     print('💾 Backup des clés chiffrées sauvegardé');
//   }

//   /// Récupère le backup chiffré des clés privées
//   Future<String?> getEncryptedKeysBackup() async {
//     return await _storage.read(key: 'encrypted_keys_backup');
//   }

//   /// Supprime le backup chiffré
//   Future<void> deleteEncryptedKeysBackup() async {
//     await _storage.delete(key: 'encrypted_keys_backup');
//   }

//   // ========== FIN NOUVEAU ==========

//   Future<AuthData?> getAuthData() async {
//     final values = await Future.wait([
//       _storage.read(key: 'access_token'),
//       _storage.read(key: 'refresh_token'),
//       _storage.read(key: 'user_id'),
//       _storage.read(key: 'device_id'),
//       _storage.read(key: 'dh_private_key'),
//       _storage.read(key: 'sign_private_key'),
//     ]);

//     if (values.any((v) => v == null)) return null;

//     return AuthData(
//       accessToken: values[0]!,
//       refreshToken: values[1]!,
//       userId: values[2]!,
//       deviceId: values[3]!,
//       dhPrivateKey: values[4]!,
//       signPrivateKey: values[5]!,
//     );
//   }

//   Future<String?> getAccessToken() async {
//     return await _storage.read(key: 'access_token');
//   }

//   Future<String?> getRefreshToken() async {
//     return await _storage.read(key: 'refresh_token');
//   }

//   Future<String?> getUserId() async {
//     final userId = await _storage.read(key: 'user_id');
//     print('📖 User ID retrieved: $userId');
//     return userId;
//   }

//   Future<String?> getDeviceId() async {
//     return await _storage.read(key: 'device_id');
//   }

//   Future<String?> getDHPrivateKey() async {
//     return await _storage.read(key: 'dh_private_key');
//   }

//   Future<String?> getSignPrivateKey() async {
//     return await _storage.read(key: 'sign_private_key');
//   }

//   Future<String?> getMessagePlaintext(String messageId) async {
//     return await _storage.read(key: 'msg_plain_$messageId');
//   }

//   Future<bool> isAuthenticated() async {
//     final accessToken = await getAccessToken();
//     final dhKey = await getDHPrivateKey();
//     final signKey = await getSignPrivateKey();
//     return accessToken != null && dhKey != null && signKey != null;
//   }

//   Future<bool> hasPrivateKeys() async {
//     final dhKey = await getDHPrivateKey();
//     final signKey = await getSignPrivateKey();
//     return dhKey != null && signKey != null;
//   }

//   // ========== NOUVEAU: Méthodes individuelles ==========
  
//   /// Vérifie si la clé privée DH existe
//   Future<bool> hasDHPrivateKey() async {
//     final dhKey = await getDHPrivateKey();
//     return dhKey != null;
//   }

//   /// Vérifie si la clé privée de signature existe
//   Future<bool> hasSignPrivateKey() async {
//     final signKey = await getSignPrivateKey();
//     return signKey != null;
//   }

//   // ========== FIN NOUVEAU ==========

//   Future<void> clearAuth() async {
//     await Future.wait([
//       _storage.delete(key: 'access_token'),
//       _storage.delete(key: 'refresh_token'),
//       _storage.delete(key: 'user_id'),
//       _storage.delete(key: 'device_id'),
//       _storage.delete(key: 'dh_private_key'),
//       _storage.delete(key: 'sign_private_key'),
//     ]);
//   }

//   Future<void> clearAll() async {
//     await _storage.deleteAll();
//   }
// }
