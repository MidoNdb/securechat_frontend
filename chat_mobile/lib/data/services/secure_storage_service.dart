// lib/data/services/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_data.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  late final FlutterSecureStorage _storage;

  // Cache mémoire pour éviter les lectures répétées du KeyStore Android
  String? _cachedDhPrivateKey;
  String? _cachedSignPrivateKey;
  String? _cachedUserId;
  String? _cachedDeviceId;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _cacheLoaded = false;

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

  /// Pré-charge toutes les clés en une seule opération batch.
  /// Appeler après le login ou au démarrage si authentifié.
  Future<void> preloadKeys() async {
    if (_cacheLoaded) return;

    try {
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
      _cacheLoaded = true;
    } catch (e) {
      _cacheLoaded = false;
    }
  }

  Future<void> saveAuthData(AuthData authData) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: authData.accessToken),
      _storage.write(key: 'refresh_token', value: authData.refreshToken),
      _storage.write(key: 'user_id', value: authData.userId),
      _storage.write(key: 'device_id', value: authData.deviceId),
      _storage.write(key: 'dh_private_key', value: authData.dhPrivateKey),
      _storage.write(key: 'sign_private_key', value: authData.signPrivateKey),
    ]);

    _cachedAccessToken = authData.accessToken;
    _cachedRefreshToken = authData.refreshToken;
    _cachedUserId = authData.userId;
    _cachedDeviceId = authData.deviceId;
    _cachedDhPrivateKey = authData.dhPrivateKey;
    _cachedSignPrivateKey = authData.signPrivateKey;
    _cacheLoaded = true;
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
  }

  Future<String?> getDHPrivateKey() async {
    if (_cacheLoaded && _cachedDhPrivateKey != null) return _cachedDhPrivateKey;
    final key = await _storage.read(key: 'dh_private_key');
    _cachedDhPrivateKey = key;
    return key;
  }

  Future<String?> getSignPrivateKey() async {
    if (_cacheLoaded && _cachedSignPrivateKey != null) return _cachedSignPrivateKey;
    final key = await _storage.read(key: 'sign_private_key');
    _cachedSignPrivateKey = key;
    return key;
  }

  Future<String?> getUserId() async {
    if (_cacheLoaded && _cachedUserId != null) return _cachedUserId;
    final userId = await _storage.read(key: 'user_id');
    _cachedUserId = userId;
    return userId;
  }

  Future<String?> getAccessToken() async {
    if (_cacheLoaded && _cachedAccessToken != null) return _cachedAccessToken;
    final token = await _storage.read(key: 'access_token');
    _cachedAccessToken = token;
    return token;
  }

  Future<String?> getRefreshToken() async {
    if (_cacheLoaded && _cachedRefreshToken != null) return _cachedRefreshToken;
    final token = await _storage.read(key: 'refresh_token');
    _cachedRefreshToken = token;
    return token;
  }

  Future<String?> getDeviceId() async {
    if (_cacheLoaded && _cachedDeviceId != null) return _cachedDeviceId;
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

  Future<bool> isAuthenticated() async {
    final results = await Future.wait([
      getAccessToken(),
      getDHPrivateKey(),
      getSignPrivateKey(),
    ]);
    return results.every((v) => v != null);
  }

  Future<bool> hasPrivateKeys() async {
    final results = await Future.wait([
      getDHPrivateKey(),
      getSignPrivateKey(),
    ]);
    return results.every((v) => v != null);
  }

  Future<bool> hasDHPrivateKey() async {
    return (await getDHPrivateKey()) != null;
  }

  Future<bool> hasSignPrivateKey() async {
    return (await getSignPrivateKey()) != null;
  }

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
    _resetCache();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    _resetCache();
  }

  void _resetCache() {
    _cachedDhPrivateKey = null;
    _cachedSignPrivateKey = null;
    _cachedUserId = null;
    _cachedDeviceId = null;
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cacheLoaded = false;
  }
}