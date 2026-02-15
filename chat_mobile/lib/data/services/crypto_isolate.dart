

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' hide Hmac;
import 'package:pointycastle/export.dart' hide Mac, Signature;

// ══════════════════════════════════════════════════════════════
// CLASSES DE PARAMÈTRES (sérialisables pour compute())
// ══════════════════════════════════════════════════════════════

class GenerateKeysParams {
  const GenerateKeysParams();
}

class EncryptParams {
  final String plaintext;
  final String myDhPrivateKeyB64;
  final String theirDhPublicKeyB64;
  final String mySignPrivateKeyB64;

  const EncryptParams({
    required this.plaintext,
    required this.myDhPrivateKeyB64,
    required this.theirDhPublicKeyB64,
    required this.mySignPrivateKeyB64,
  });
}

class DecryptParams {
  final String ciphertextB64;
  final String nonceB64;
  final String authTagB64;
  final String signatureB64;
  final String myDhPrivateKeyB64;
  final String theirDhPublicKeyB64;
  final String theirSignPublicKeyB64;

  const DecryptParams({
    required this.ciphertextB64,
    required this.nonceB64,
    required this.authTagB64,
    required this.signatureB64,
    required this.myDhPrivateKeyB64,
    required this.theirDhPublicKeyB64,
    required this.theirSignPublicKeyB64,
  });
}

class DecryptBatchParams {
  final List<DecryptItemParams> items;
  final String myDhPrivateKeyB64;

  const DecryptBatchParams({
    required this.items,
    required this.myDhPrivateKeyB64,
  });
}

class DecryptItemParams {
  final String messageId;
  final String ciphertextB64;
  final String nonceB64;
  final String authTagB64;
  final String signatureB64;
  final String theirDhPublicKeyB64;
  final String theirSignPublicKeyB64;

  const DecryptItemParams({
    required this.messageId,
    required this.ciphertextB64,
    required this.nonceB64,
    required this.authTagB64,
    required this.signatureB64,
    required this.theirDhPublicKeyB64,
    required this.theirSignPublicKeyB64,
  });
}

class DecryptBatchResult {
  final Map<String, String> successes;
  final Map<String, String> errors;

  const DecryptBatchResult({
    required this.successes,
    required this.errors,
  });
}

class PasswordCryptoParams {
  final String data;
  final String password;

  const PasswordCryptoParams({
    required this.data,
    required this.password,
  });
}

class DeriveKeyParams {
  final String myDhPrivateKeyB64;
  final String theirDhPublicKeyB64;

  const DeriveKeyParams({
    required this.myDhPrivateKeyB64,
    required this.theirDhPublicKeyB64,
  });
}

// ══════════════════════════════════════════════════════════════
// FONCTIONS TOP-LEVEL (exécutées dans l'Isolate)
// ══════════════════════════════════════════════════════════════

/// Génère les 4 clés (DH private/public + Sign private/public)
/// C'est l'opération qui freeze le plus au register/login
Future<Map<String, String>> isolateGenerateAllKeys(GenerateKeysParams _) async {
  final x25519 = X25519();
  final ed25519 = Ed25519();

  // DH + Sign en parallèle dans l'Isolate
  final results = await Future.wait([
    x25519.newKeyPair(),
    ed25519.newKeyPair(),
  ]);

  final dhKeyPair = results[0];
  final signKeyPair = results[1];

  final dhPrivateBytes = await dhKeyPair.extractPrivateKeyBytes();
  final dhPublicKey = await dhKeyPair.extractPublicKey();
  final signPrivateBytes = await signKeyPair.extractPrivateKeyBytes();
  final signPublicKey = await signKeyPair.extractPublicKey();

  return {
    'dh_private_key': base64Encode(dhPrivateBytes),
    'dh_public_key': base64Encode(dhPublicKey.bytes),
    'sign_private_key': base64Encode(signPrivateBytes),
    'sign_public_key': base64Encode(signPublicKey.bytes),
  };
}

/// Chiffre un message complet (DH + HKDF + AES-GCM + Ed25519 sign)
Future<Map<String, String>> isolateEncryptMessage(EncryptParams params) async {
  final x25519 = X25519();
  final ed25519 = Ed25519();
  final aesGcm = AesGcm.with256bits();
  final sha256Algo = Sha256();

  //  DH shared secret
  final sharedSecretBytes = await _computeSharedSecretInternal(
    x25519,
    params.myDhPrivateKeyB64,
    params.theirDhPublicKeyB64,
  );

  //  HKDF derive AES key
  final aesKeyBytes = await _deriveAESKeyInternal(sha256Algo, sharedSecretBytes);

  //  AES-GCM encrypt
  final secretBox = await aesGcm.encrypt(
    utf8.encode(params.plaintext),
    secretKey: SecretKey(aesKeyBytes),
  );

  //  SHA-256 hash of ciphertext
  final ciphertextHash = await sha256Algo.hash(secretBox.cipherText);

  //  Ed25519 sign
  final signatureB64 = await _signDataInternal(
    ed25519,
    ciphertextHash.bytes,
    params.mySignPrivateKeyB64,
  );

  return {
    'ciphertext': base64Encode(secretBox.cipherText),
    'nonce': base64Encode(secretBox.nonce),
    'auth_tag': base64Encode(secretBox.mac.bytes),
    'signature': signatureB64,
  };
}

/// Déchiffre un message (verify signature + DH + HKDF + AES-GCM)
Future<String> isolateDecryptMessage(DecryptParams params) async {
  final x25519 = X25519();
  final ed25519 = Ed25519();
  final aesGcm = AesGcm.with256bits();
  final sha256Algo = Sha256();

  final ciphertext = base64Decode(params.ciphertextB64);
  final nonce = base64Decode(params.nonceB64);
  final authTag = base64Decode(params.authTagB64);

  //  Verify signature
  final ciphertextHash = await sha256Algo.hash(ciphertext);
  final isValid = await _verifySignatureInternal(
    ed25519,
    ciphertextHash.bytes,
    params.signatureB64,
    params.theirSignPublicKeyB64,
  );

  if (!isValid) {
    throw Exception('Signature invalide - Message compromis');
  }

  // DH shared secret
  final sharedSecretBytes = await _computeSharedSecretInternal(
    x25519,
    params.myDhPrivateKeyB64,
    params.theirDhPublicKeyB64,
  );

  //  HKDF derive AES key
  final aesKeyBytes = await _deriveAESKeyInternal(sha256Algo, sharedSecretBytes);

  //  AES-GCM decrypt
  final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(authTag));
  final decryptedBytes = await aesGcm.decrypt(
    secretBox,
    secretKey: SecretKey(aesKeyBytes),
  );

  return utf8.decode(decryptedBytes);
}

/// Déchiffre un batch de messages dans un seul Isolate.
/// Réutilise les instances crypto + cache le shared secret DH par clé publique.
Future<DecryptBatchResult> isolateDecryptBatch(DecryptBatchParams params) async {
  final x25519 = X25519();
  final ed25519 = Ed25519();
  final aesGcm = AesGcm.with256bits();
  final sha256Algo = Sha256();

  // Cache DH dans l'Isolate pour ce batch
  final dhCache = <String, List<int>>{};

  final successes = <String, String>{};
  final errors = <String, String>{};

  for (final item in params.items) {
    try {
      final ciphertext = base64Decode(item.ciphertextB64);
      final nonce = base64Decode(item.nonceB64);
      final authTag = base64Decode(item.authTagB64);

      // Verify signature
      final ciphertextHash = await sha256Algo.hash(ciphertext);
      final isValid = await _verifySignatureInternal(
        ed25519,
        ciphertextHash.bytes,
        item.signatureB64,
        item.theirSignPublicKeyB64,
      );

      if (!isValid) {
        errors[item.messageId] = 'Signature invalide';
        continue;
      }

      // DH avec cache intra-batch
      final dhCacheKey = item.theirDhPublicKeyB64;
      List<int> aesKeyBytes;

      if (dhCache.containsKey(dhCacheKey)) {
        aesKeyBytes = dhCache[dhCacheKey]!;
      } else {
        final sharedSecret = await _computeSharedSecretInternal(
          x25519,
          params.myDhPrivateKeyB64,
          item.theirDhPublicKeyB64,
        );
        aesKeyBytes = await _deriveAESKeyInternal(sha256Algo, sharedSecret);
        dhCache[dhCacheKey] = aesKeyBytes;
      }

      // AES-GCM decrypt
      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(authTag));
      final decryptedBytes = await aesGcm.decrypt(
        secretBox,
        secretKey: SecretKey(aesKeyBytes),
      );

      successes[item.messageId] = utf8.decode(decryptedBytes);
    } catch (e) {
      errors[item.messageId] = e.toString();
    }
  }

  return DecryptBatchResult(successes: successes, errors: errors);
}

/// PBKDF2 encrypt (100k itérations — très lourd, bloque le main thread)
Future<String> isolateEncryptWithPassword(PasswordCryptoParams params) async {
  final random = Random.secure();
  final salt = Uint8List.fromList(
    List<int>.generate(32, (i) => random.nextInt(256)),
  );
  final nonce = Uint8List.fromList(
    List<int>.generate(12, (i) => random.nextInt(256)),
  );

  final key = _pbkdf2Derive(params.password, salt);

  final cipher = GCMBlockCipher(AESEngine());
  cipher.init(
    true,
    AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
  );

  final ciphertext = cipher.process(Uint8List.fromList(utf8.encode(params.data)));
  final combined = Uint8List.fromList([...salt, ...nonce, ...ciphertext]);
  return base64.encode(combined);
}

/// PBKDF2 decrypt
Future<String> isolateDecryptWithPassword(PasswordCryptoParams params) async {
  final combined = base64.decode(params.data);

  if (combined.length < 44) {
    throw Exception('Données corrompues');
  }

  final salt = Uint8List.fromList(combined.sublist(0, 32));
  final nonce = Uint8List.fromList(combined.sublist(32, 44));
  final encrypted = Uint8List.fromList(combined.sublist(44));

  final key = _pbkdf2Derive(params.password, salt);

  final cipher = GCMBlockCipher(AESEngine());
  cipher.init(
    false,
    AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
  );

  try {
    final plaintext = cipher.process(encrypted);
    return utf8.decode(plaintext);
  } catch (e) {
    throw Exception('Mot de passe incorrect ou données corrompues');
  }
}

/// Calcule DH + HKDF et retourne la clé AES dérivée
Future<List<int>> isolateDeriveKey(DeriveKeyParams params) async {
  final x25519 = X25519();
  final sha256Algo = Sha256();

  final sharedSecret = await _computeSharedSecretInternal(
    x25519,
    params.myDhPrivateKeyB64,
    params.theirDhPublicKeyB64,
  );

  return await _deriveAESKeyInternal(sha256Algo, sharedSecret);
}

// ══════════════════════════════════════════════════════════════
// FONCTIONS INTERNES (utilisées par les top-level ci-dessus)
// ══════════════════════════════════════════════════════════════

Future<List<int>> _computeSharedSecretInternal(
  X25519 x25519,
  String myPrivateB64,
  String theirPublicB64,
) async {
  final myPrivateBytes = base64Decode(myPrivateB64);
  final theirPublicBytes = base64Decode(theirPublicB64);

  final myKeyPair = SimpleKeyPairData(
    myPrivateBytes,
    publicKey: SimplePublicKey([], type: KeyPairType.x25519),
    type: KeyPairType.x25519,
  );

  final theirPublicKey = SimplePublicKey(
    theirPublicBytes,
    type: KeyPairType.x25519,
  );

  final sharedSecret = await x25519.sharedSecretKey(
    keyPair: myKeyPair,
    remotePublicKey: theirPublicKey,
  );

  return await sharedSecret.extractBytes();
}

Future<List<int>> _deriveAESKeyInternal(
  Sha256 sha256Algo,
  List<int> sharedSecretBytes,
) async {
  final hkdf = Hkdf(hmac: Hmac(sha256Algo), outputLength: 32);

  final aesKey = await hkdf.deriveKey(
    secretKey: SecretKey(sharedSecretBytes),
    nonce: utf8.encode('SecureChat-v1'),
    info: utf8.encode('message-encryption'),
  );

  return await aesKey.extractBytes();
}

Future<String> _signDataInternal(
  Ed25519 ed25519,
  List<int> data,
  String signPrivateKeyB64,
) async {
  final privateBytes = base64Decode(signPrivateKeyB64);

  final keyPair = SimpleKeyPairData(
    privateBytes,
    publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
    type: KeyPairType.ed25519,
  );

  final signature = await ed25519.sign(data, keyPair: keyPair);
  return base64Encode(signature.bytes);
}

Future<bool> _verifySignatureInternal(
  Ed25519 ed25519,
  List<int> data,
  String signatureB64,
  String signPublicKeyB64,
) async {
  try {
    final signatureBytes = base64Decode(signatureB64);
    final publicKeyBytes = base64Decode(signPublicKeyB64);

    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
    final signature = Signature(signatureBytes, publicKey: publicKey);

    return await ed25519.verify(data, signature: signature);
  } catch (e) {
    return false;
  }
}

Uint8List _pbkdf2Derive(String password, Uint8List salt) {
  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  pbkdf2.init(Pbkdf2Parameters(salt, 100000, 32));
  return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
}