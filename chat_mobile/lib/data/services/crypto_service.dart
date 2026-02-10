// lib/data/services/crypto_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' hide Hmac;
import 'package:pointycastle/export.dart' hide Mac, Signature;

/// Service centralisé pour toutes les opérations cryptographiques
/// 
/// Architecture:
/// - X25519 (Diffie-Hellman) → Secret partagé → Clé AES
/// - Ed25519 → Signatures (authenticité)
/// - AES-256-GCM → Chiffrement messages
/// - SHA-256 → Hash pour intégrité
/// - HKDF → Dérivation clé AES depuis secret DH
/// - PBKDF2 → Dérivation clé depuis mot de passe (backup)
class CryptoService {
  // Algorithmes
  final _x25519 = X25519();
  final _ed25519 = Ed25519();
  final _aesGcm = AesGcm.with256bits();
  final _sha256 = Sha256();

  // ==================== GÉNÉRATION CLÉS ====================

  /// Génère une paire de clés DH (X25519) pour secret partagé
  Future<Map<String, String>> generateDHKeyPair() async {
    try {
      final keyPair = await _x25519.newKeyPair();
      final privateBytes = await keyPair.extractPrivateKeyBytes();
      final publicKey = await keyPair.extractPublicKey();
      
      return {
        'private': base64Encode(privateBytes),
        'public': base64Encode(publicKey.bytes),
      };
    } catch (e) {
      throw Exception('Erreur génération clé DH: $e');
    }
  }

  /// Génère une paire de clés de signature (Ed25519)
  Future<Map<String, String>> generateSignKeyPair() async {
    try {
      final keyPair = await _ed25519.newKeyPair();
      final privateBytes = await keyPair.extractPrivateKeyBytes();
      final publicKey = await keyPair.extractPublicKey();
      
      return {
        'private': base64Encode(privateBytes),
        'public': base64Encode(publicKey.bytes),
      };
    } catch (e) {
      throw Exception('Erreur génération clé signature: $e');
    }
  }

  /// Génère les 2 paires de clés (DH + Signature)
  Future<Map<String, String>> generateAllKeys() async {
    try {
      final dhKeys = await generateDHKeyPair();
      final signKeys = await generateSignKeyPair();
      
      return {
        'dh_private_key': dhKeys['private']!,
        'dh_public_key': dhKeys['public']!,
        'sign_private_key': signKeys['private']!,
        'sign_public_key': signKeys['public']!,
      };
    } catch (e) {
      throw Exception('Erreur génération clés: $e');
    }
  }

  // ==================== CALCUL SECRET PARTAGÉ ====================

  /// Calcule le secret partagé Diffie-Hellman
  /// 
  /// Alice: secret = DH(alice_private, bob_public)
  /// Bob:   secret = DH(bob_private, alice_public)
  /// → Résultat identique!
  Future<List<int>> computeSharedSecret({
    required String myDhPrivateKeyB64,
    required String theirDhPublicKeyB64,
  }) async {
    try {
      // Décoder les clés
      final myPrivateBytes = base64Decode(myDhPrivateKeyB64);
      final theirPublicBytes = base64Decode(theirDhPublicKeyB64);
      
      // Reconstituer les objets clés
      final myKeyPair = SimpleKeyPairData(
        myPrivateBytes,
        publicKey: SimplePublicKey([], type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      
      final theirPublicKey = SimplePublicKey(
        theirPublicBytes,
        type: KeyPairType.x25519,
      );
      
      // Calcul DH
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: myKeyPair,
        remotePublicKey: theirPublicKey,
      );
      
      return await sharedSecret.extractBytes();
    } catch (e) {
      throw Exception('Erreur calcul secret partagé: $e');
    }
  }

  // ==================== DÉRIVATION CLÉ AES ====================

  /// Dérive une clé AES-256 depuis le secret partagé DH
  /// Utilise HKDF (HMAC-based Key Derivation Function)
  Future<List<int>> deriveAESKey(List<int> sharedSecretBytes) async {
    try {
      final hkdf = Hkdf(
        hmac: Hmac(_sha256),
        outputLength: 32, // 256 bits pour AES-256
      );
      
      final aesKeyBytes = await hkdf.deriveKey(
        secretKey: SecretKey(sharedSecretBytes),
        nonce: utf8.encode('SecureChat-v1'), // Salt
        info: utf8.encode('message-encryption'), // Context
      );
      
      return await aesKeyBytes.extractBytes();
    } catch (e) {
      throw Exception('Erreur dérivation clé AES: $e');
    }
  }

  // ==================== CHIFFREMENT MESSAGE ====================

  /// Chiffre un message avec AES-256-GCM
  /// 
  /// Étapes:
  /// 1. Calcule secret partagé DH
  /// 2. Dérive clé AES depuis secret
  /// 3. Chiffre message avec AES-GCM
  /// 4. Hash le ciphertext (intégrité)
  /// 5. Signe le hash (authenticité)
  /// 
  /// Retourne: {ciphertext, nonce, auth_tag, signature}
  Future<Map<String, String>> encryptMessage({
    required String plaintext,
    required String myDhPrivateKeyB64,
    required String theirDhPublicKeyB64,
    required String mySignPrivateKeyB64,
  }) async {
    try {
      print('🔐 Chiffrement message...');
      
      // 1. Calculer secret partagé DH
      final sharedSecretBytes = await computeSharedSecret(
        myDhPrivateKeyB64: myDhPrivateKeyB64,
        theirDhPublicKeyB64: theirDhPublicKeyB64,
      );
      
      print('✅ Secret partagé calculé (${sharedSecretBytes.length} bytes)');
      
      // 2. Dériver clé AES
      final aesKeyBytes = await deriveAESKey(sharedSecretBytes);
      print('✅ Clé AES dérivée (${aesKeyBytes.length} bytes)');
      
      // 3. Chiffrer avec AES-256-GCM
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(plaintext),
        secretKey: SecretKey(aesKeyBytes),
      );
      
      print('✅ Message chiffré');
      
      // 4. Hash du ciphertext (intégrité)
      final ciphertextHash = await _sha256.hash(secretBox.cipherText);
      print('✅ Hash calculé');
      
      // 5. Signer avec Ed25519 (authenticité)
      final signature = await _signData(
        ciphertextHash.bytes,
        mySignPrivateKeyB64,
      );
      
      print('✅ Signature créée');
      
      return {
        'ciphertext': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'auth_tag': base64Encode(secretBox.mac.bytes),
        'signature': signature,
      };
    } catch (e) {
      throw Exception('Erreur chiffrement: $e');
    }
  }

  // ==================== DÉCHIFFREMENT MESSAGE ====================

  /// Déchiffre un message
  /// 
  /// Étapes:
  /// 1. Vérifie la signature (authenticité)
  /// 2. Recalcule secret partagé DH
  /// 3. Dérive clé AES
  /// 4. Déchiffre avec AES-GCM
  Future<String> decryptMessage({
    required String ciphertextB64,
    required String nonceB64,
    required String authTagB64,
    required String signatureB64,
    required String myDhPrivateKeyB64,
    required String theirDhPublicKeyB64,
    required String theirSignPublicKeyB64,
  }) async {
    try {
      print('🔓 Déchiffrement message...');
      
      // 1. Décoder
      final ciphertext = base64Decode(ciphertextB64);
      final nonce = base64Decode(nonceB64);
      final authTag = base64Decode(authTagB64);
      
      // 2. Vérifier signature AVANT de déchiffrer
      final ciphertextHash = await _sha256.hash(ciphertext);
      
      final isValidSignature = await _verifySignature(
        ciphertextHash.bytes,
        signatureB64,
        theirSignPublicKeyB64,
      );
      
      if (!isValidSignature) {
        throw Exception('❌ Signature invalide - Message compromis!');
      }
      
      print('✅ Signature valide');
      
      // 3. Calculer secret partagé DH
      final sharedSecretBytes = await computeSharedSecret(
        myDhPrivateKeyB64: myDhPrivateKeyB64,
        theirDhPublicKeyB64: theirDhPublicKeyB64,
      );
      
      // 4. Dériver clé AES
      final aesKeyBytes = await deriveAESKey(sharedSecretBytes);
      
      // 5. Déchiffrer
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(authTag),
      );
      
      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: SecretKey(aesKeyBytes),
      );
      
      print('✅ Message déchiffré');
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('Erreur déchiffrement: $e');
    }
  }

  // ==================== SIGNATURE / VÉRIFICATION ====================

  /// Signe des données avec Ed25519
  Future<String> _signData(
    List<int> data,
    String signPrivateKeyB64,
  ) async {
    try {
      final privateBytes = base64Decode(signPrivateKeyB64);
      
      final keyPair = SimpleKeyPairData(
        privateBytes,
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
      
      final signature = await _ed25519.sign(
        data,
        keyPair: keyPair,
      );
      
      return base64Encode(signature.bytes);
    } catch (e) {
      throw Exception('Erreur signature: $e');
    }
  }

  /// Vérifie une signature Ed25519
  Future<bool> _verifySignature(
    List<int> data,
    String signatureB64,
    String signPublicKeyB64,
  ) async {
    try {
      final signatureBytes = base64Decode(signatureB64);
      final publicKeyBytes = base64Decode(signPublicKeyB64);
      
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );
      
      final signature = Signature(
        signatureBytes,
        publicKey: publicKey,
      );
      
      return await _ed25519.verify(
        data,
        signature: signature,
      );
    } catch (e) {
      print('❌ Erreur vérification signature: $e');
      return false;
    }
  }

  // ==================== HASH ====================

  /// Calcule SHA-256 d'une chaîne
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Calcule SHA-256 de bytes
  Future<List<int>> hashBytes(List<int> input) async {
    final hash = await _sha256.hash(input);
    return hash.bytes;
  }

  // ==================== BACKUP CLÉS AVEC MOT DE PASSE ====================

  /// Chiffre des données avec un mot de passe (pour backup des clés privées)
  /// 
  /// Utilise:
  /// - PBKDF2 avec 100,000 itérations pour dériver la clé
  /// - AES-256-GCM pour le chiffrement
  /// - Salt et nonce aléatoires pour chaque opération
  /// 
  /// Format retourné: Base64(salt + nonce + ciphertext + tag)
  Future<String> encryptWithPassword({
    required String plaintext,
    required String password,
  }) async {
    try {
      print('🔐 Chiffrement avec mot de passe...');
      
      // Génération salt aléatoire (32 bytes = 256 bits)
      final salt = _generateRandomBytes(32);
      
      // Dérivation clé depuis mot de passe avec PBKDF2
      final key = await _deriveKeyFromPassword(password, salt);
      
      // Génération nonce aléatoire (12 bytes pour GCM)
      final nonce = _generateRandomBytes(12);
      
      // Chiffrement AES-256-GCM avec PointyCastle
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        128, // tag length en bits (16 bytes)
        nonce,
        Uint8List(0), // additional authenticated data (vide)
      );
      
      cipher.init(true, params);
      
      final plaintextBytes = utf8.encode(plaintext);
      final ciphertext = cipher.process(Uint8List.fromList(plaintextBytes));
      
      // Format: salt(32) + nonce(12) + ciphertext+tag
      final combined = Uint8List.fromList([
        ...salt,
        ...nonce,
        ...ciphertext,
      ]);
      
      print('✅ Chiffré avec mot de passe');
      
      return base64.encode(combined);
    } catch (e) {
      print('❌ encryptWithPassword error: $e');
      rethrow;
    }
  }
  
  /// Déchiffre des données avec un mot de passe
  /// 
  /// Lève une exception si:
  /// - Le mot de passe est incorrect
  /// - Les données sont corrompues
  /// - Le tag d'authentification ne correspond pas
  Future<String> decryptWithPassword({
    required String ciphertext,
    required String password,
  }) async {
    try {
      print('🔓 Déchiffrement avec mot de passe...');
      
      final combined = base64.decode(ciphertext);
      
      // Vérification taille minimale
      if (combined.length < 44) {
        throw Exception('Données trop courtes - format invalide');
      }
      
      // Extraction salt, nonce, ciphertext+tag
      final salt = combined.sublist(0, 32);
      final nonce = combined.sublist(32, 44);
      final encrypted = combined.sublist(44);
      
      // Dérivation clé depuis mot de passe avec même PBKDF2
      final key = await _deriveKeyFromPassword(password, salt);
      
      // Déchiffrement AES-256-GCM
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        128,
        nonce,
        Uint8List(0),
      );
      
      cipher.init(false, params);
      
      final plaintext = cipher.process(encrypted);
      
      print('✅ Déchiffré avec mot de passe');
      
      return utf8.decode(plaintext);
    } catch (e) {
      print('❌ decryptWithPassword error: $e');
      // Message d'erreur clair pour l'utilisateur
      throw Exception('Mot de passe incorrect ou données corrompues');
    }
  }
  
  /// Dérive une clé de 256 bits depuis un mot de passe avec PBKDF2
  /// 
  /// Paramètres:
  /// - HMAC-SHA256 comme fonction pseudo-aléatoire
  /// - 100,000 itérations (recommandé OWASP pour 2024)
  /// - 32 bytes de sortie (256 bits pour AES-256)
  Future<Uint8List> _deriveKeyFromPassword(String password, Uint8List salt) async {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    
    // 100,000 itérations pour production
    // Note: Peut être réduit à 10,000 en développement pour performance
    pbkdf2.init(Pbkdf2Parameters(salt, 100000, 32));
    
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
  
  /// Génère des bytes aléatoires cryptographiquement sécurisés
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (i) => random.nextInt(256))
    );
  }
}



