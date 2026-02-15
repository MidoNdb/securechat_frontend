// lib/data/services/crypto_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' hide Hmac;
import 'package:pointycastle/export.dart' hide Mac, Signature;
import 'crypto_isolate.dart';

class CryptoService {
  // Instances pour opérations légères sur le main thread (quand clé en cache)
  final _aesGcm = AesGcm.with256bits();
  final _sha256 = Sha256();

  
  final Map<String, List<int>> _derivedKeyCache = {};

  Future<List<int>> getOrComputeDerivedKey({
    required String myDhPrivateKeyB64,
    required String theirDhPublicKeyB64,
  }) async {
    final cacheKey = '${myDhPrivateKeyB64.hashCode}_${theirDhPublicKeyB64.hashCode}';

    if (_derivedKeyCache.containsKey(cacheKey)) {
      return _derivedKeyCache[cacheKey]!;
    }

    // DH + HKDF dans un Isolate
    final derivedKey = await compute(
      isolateDeriveKey,
      DeriveKeyParams(
        myDhPrivateKeyB64: myDhPrivateKeyB64,
        theirDhPublicKeyB64: theirDhPublicKeyB64,
      ),
    );

    _derivedKeyCache[cacheKey] = derivedKey;
    return derivedKey;
  }

  void invalidateCache([String? theirPublicKeyB64]) {
    if (theirPublicKeyB64 != null) {
      _derivedKeyCache.removeWhere(
        (key, _) => key.contains('${theirPublicKeyB64.hashCode}'),
      );
    } else {
      _derivedKeyCache.clear();
    }
  }

  Future<Map<String, String>> generateAllKeys() async {
    return await compute(isolateGenerateAllKeys, const GenerateKeysParams());
  }

  
  Future<Map<String, String>> encryptMessage({
    required String plaintext,
    required String myDhPrivateKeyB64,
    required String theirDhPublicKeyB64,
    required String mySignPrivateKeyB64,
  }) async {
    final cacheKey = '${myDhPrivateKeyB64.hashCode}_${theirDhPublicKeyB64.hashCode}';

    if (_derivedKeyCache.containsKey(cacheKey)) {
      return await _encryptWithCachedKey(
        plaintext: plaintext,
        aesKeyBytes: _derivedKeyCache[cacheKey]!,
        mySignPrivateKeyB64: mySignPrivateKeyB64,
      );
    }

    final result = await compute(
      isolateEncryptMessage,
      EncryptParams(
        plaintext: plaintext,
        myDhPrivateKeyB64: myDhPrivateKeyB64,
        theirDhPublicKeyB64: theirDhPublicKeyB64,
        mySignPrivateKeyB64: mySignPrivateKeyB64,
      ),
    );

    _ensureDerivedKeyCached(myDhPrivateKeyB64, theirDhPublicKeyB64);
    return result;
  }

  Future<Map<String, String>> _encryptWithCachedKey({
    required String plaintext,
    required List<int> aesKeyBytes,
    required String mySignPrivateKeyB64,
  }) async {
    final ed25519 = Ed25519();

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(aesKeyBytes),
    );

    final ciphertextHash = await _sha256.hash(secretBox.cipherText);

    final privateBytes = base64Decode(mySignPrivateKeyB64);
    final keyPair = SimpleKeyPairData(
      privateBytes,
      publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
    final signature = await ed25519.sign(ciphertextHash.bytes, keyPair: keyPair);

    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'auth_tag': base64Encode(secretBox.mac.bytes),
      'signature': base64Encode(signature.bytes),
    };
  }

 
  Future<String> decryptMessage({
    required String ciphertextB64,
    required String nonceB64,
    required String authTagB64,
    required String signatureB64,
    required String myDhPrivateKeyB64,
    required String theirDhPublicKeyB64,
    required String theirSignPublicKeyB64,
  }) async {
    final cacheKey = '${myDhPrivateKeyB64.hashCode}_${theirDhPublicKeyB64.hashCode}';

    if (_derivedKeyCache.containsKey(cacheKey)) {
      return await _decryptWithCachedKey(
        ciphertextB64: ciphertextB64,
        nonceB64: nonceB64,
        authTagB64: authTagB64,
        signatureB64: signatureB64,
        aesKeyBytes: _derivedKeyCache[cacheKey]!,
        theirSignPublicKeyB64: theirSignPublicKeyB64,
      );
    }

    final result = await compute(
      isolateDecryptMessage,
      DecryptParams(
        ciphertextB64: ciphertextB64,
        nonceB64: nonceB64,
        authTagB64: authTagB64,
        signatureB64: signatureB64,
        myDhPrivateKeyB64: myDhPrivateKeyB64,
        theirDhPublicKeyB64: theirDhPublicKeyB64,
        theirSignPublicKeyB64: theirSignPublicKeyB64,
      ),
    );

    _ensureDerivedKeyCached(myDhPrivateKeyB64, theirDhPublicKeyB64);
    return result;
  }

  Future<String> _decryptWithCachedKey({
    required String ciphertextB64,
    required String nonceB64,
    required String authTagB64,
    required String signatureB64,
    required List<int> aesKeyBytes,
    required String theirSignPublicKeyB64,
  }) async {
    final ed25519 = Ed25519();
    final ciphertext = base64Decode(ciphertextB64);
    final nonce = base64Decode(nonceB64);
    final authTag = base64Decode(authTagB64);

    // Vérifier signature
    final ciphertextHash = await _sha256.hash(ciphertext);
    final signatureBytes = base64Decode(signatureB64);
    final publicKeyBytes = base64Decode(theirSignPublicKeyB64);

    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
    final sig = Signature(signatureBytes, publicKey: publicKey);
    final isValid = await ed25519.verify(ciphertextHash.bytes, signature: sig);

    if (!isValid) {
      throw Exception('Signature invalide - Message compromis');
    }

    // Déchiffrer
    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(authTag));
    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: SecretKey(aesKeyBytes),
    );

    return utf8.decode(decryptedBytes);
  }

  Future<DecryptBatchResult> decryptBatch({
    required List<DecryptItemParams> items,
    required String myDhPrivateKeyB64,
  }) async {
    if (items.isEmpty) {
      return const DecryptBatchResult(successes: {}, errors: {});
    }

    return await compute(
      isolateDecryptBatch,
      DecryptBatchParams(items: items, myDhPrivateKeyB64: myDhPrivateKeyB64),
    );
  }

  Future<String> encryptWithPassword({
    required String plaintext,
    required String password,
  }) async {
    return await compute(
      isolateEncryptWithPassword,
      PasswordCryptoParams(data: plaintext, password: password),
    );
  }

  Future<String> decryptWithPassword({
    required String ciphertext,
    required String password,
  }) async {
    return await compute(
      isolateDecryptWithPassword,
      PasswordCryptoParams(data: ciphertext, password: password),
    );
  }

  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _ensureDerivedKeyCached(String myPrivateB64, String theirPublicB64) {
    final cacheKey = '${myPrivateB64.hashCode}_${theirPublicB64.hashCode}';
    if (!_derivedKeyCache.containsKey(cacheKey)) {
      getOrComputeDerivedKey(
        myDhPrivateKeyB64: myPrivateB64,
        theirDhPublicKeyB64: theirPublicB64,
      );
    }
  }
}