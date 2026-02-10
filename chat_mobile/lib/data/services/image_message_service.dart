// lib/data/services/image_message_service.dart
// ✅ VERSION FINALE - Corrige l'erreur MAC authentication

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import '../models/message.dart';
import 'crypto_service.dart';
import 'file_service.dart';
import 'secure_storage_service.dart';
import '../api/dio_client.dart';
import '../api/api_endpoints.dart';

class ImageMessageService extends GetxService {
  final CryptoService _crypto = Get.find<CryptoService>();
  final FileService _fileService = Get.find<FileService>();
  final SecureStorageService _storage = Get.find<SecureStorageService>();
  final DioClient _dio = Get.find<DioClient>();
  
  // ==================== ENVOI IMAGE ====================
  
  Future<Message> sendImage({
    required String conversationId,
    required String recipientUserId,
    required File imageFile,
  }) async {
    try {
      print('📤 === ENVOI IMAGE ===');
      
      // 1. Compression
      final compressedBytes = await _fileService.compressImage(
        imageFile,
        maxSizeKB: 500,
        quality: 85,
      );
      
      print('   ✅ Compressée: ${compressedBytes.length / 1024} KB');
      
      // 2. Métadonnées
      final metadata = await _extractImageMetadata(imageFile, compressedBytes);
      
      // 3. Récupérer clés E2EE
      final myDhPrivateKey = await _storage.getDHPrivateKey();
      final mySignPrivateKey = await _storage.getSignPrivateKey();
      
      if (myDhPrivateKey == null || mySignPrivateKey == null) {
        throw Exception('Clés E2EE manquantes');
      }
      
      // 4. Récupérer clés publiques destinataire
      final recipientKeys = await _getRecipientPublicKeys(recipientUserId);
      
      print('   ✅ Clés récupérées');
      
      // 5. Convertir en Base64
      final base64Image = base64Encode(compressedBytes);
      
      // 6. Chiffrement
      print('   🔐 Chiffrement...');
      final encrypted = await _crypto.encryptMessage(
        plaintext: base64Image,
        myDhPrivateKeyB64: myDhPrivateKey,
        theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
        mySignPrivateKeyB64: mySignPrivateKey,
      );
      
      // 7. Préparation requête
      final payload = {
        'conversation_id': conversationId,
        'recipient_user_id': recipientUserId,
        'type': 'IMAGE',
        'encrypted_content': encrypted['ciphertext']!,
        'nonce': encrypted['nonce']!,
        'auth_tag': encrypted['auth_tag']!,
        'signature': encrypted['signature']!,
        'metadata': metadata,
      };
      
      // 8. Envoi HTTP
      final response = await _dio.privateDio.post(
        ApiEndpoints.sendMessage,
        data: payload,
      );
      
      // 9. Extraction message
      final messageData = response.data['data'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      
      // 10. Sauvegarder en cache (image en clair)
      await _fileService.saveToCacheDir(
        compressedBytes,
        message.id,
        extension: 'jpg',
      );
      
      print('✅ Image envoyée: ${message.id}');
      
      return message;
      
    } catch (e, stack) {
      print('❌ Erreur sendImage: $e');
      print('Stack: $stack');
      rethrow;
    }
  }
  
  // ==================== RÉCEPTION IMAGE ====================
  
  Future<File> decryptImage(Message message) async {
    try {
      print('🖼️ === DÉCHIFFREMENT IMAGE ${message.id} ===');
      print('   Sender: ${message.senderId}');
      print('   Recipient: ${message.recipientUserId}');
      
      // 1. Vérifier cache
      final cachedFile = await _fileService.getFromCache(message.id);
      if (cachedFile != null) {
        print('   ✅ Image depuis cache');
        return cachedFile;
      }
      
      // 2. Récupérer mes clés privées
      final myDhPrivateKey = await _storage.getDHPrivateKey();
      final currentUserId = await _storage.getUserId();
      
      if (myDhPrivateKey == null) {
        throw Exception('Clé DH manquante');
      }
      
      if (currentUserId == null) {
        throw Exception('User ID manquant');
      }
      
      print('   ✅ Mes clés récupérées');
      print('   User ID: $currentUserId');
      
      // 3. ✅ CORRECTION CRITIQUE : Déterminer quelles clés publiques utiliser
      String dhKeyUserId;
      String signKeyUserId;
      
      final isMyMessage = message.senderId == currentUserId;
      
      if (isMyMessage) {
        // ✅ C'EST MON MESSAGE
        print('   ℹ️ C\'est MON message');
        
        if (message.recipientUserId == null || message.recipientUserId!.isEmpty) {
          throw Exception('recipientUserId manquant pour mon message');
        }
        
        // Pour déchiffrer MON propre message :
        // - J'ai chiffré AVEC la clé publique DU DESTINATAIRE
        // - Donc j'utilise les clés publiques DU DESTINATAIRE pour déchiffrer
        dhKeyUserId = message.recipientUserId!;
        
        // - J'ai signé avec MA clé privée Sign
        // - Donc je vérifie avec MA clé publique Sign
        signKeyUserId = currentUserId;
        
        print('   🔐 DH: clés du destinataire ($dhKeyUserId)');
        print('   ✍️ Sign: mes clés ($signKeyUserId)');
        
      } else {
        // ✅ MESSAGE REÇU D'UN AUTRE
        print('   ℹ️ Message reçu de ${message.senderId}');
        
        // Pour déchiffrer un message REÇU :
        // - Ils ont chiffré AVEC MA clé publique DH
        // - Donc j'utilise LEURS clés publiques DH pour déchiffrer
        dhKeyUserId = message.senderId;
        
        // - Ils ont signé avec LEUR clé privée Sign
        // - Donc je vérifie avec LEUR clé publique Sign
        signKeyUserId = message.senderId;
        
        print('   🔐 DH: clés de l\'expéditeur ($dhKeyUserId)');
        print('   ✍️ Sign: clés de l\'expéditeur ($signKeyUserId)');
      }
      
      // 4. Récupérer les clés publiques appropriées
      final dhKeys = await _getRecipientPublicKeys(dhKeyUserId);
      final signKeys = await _getRecipientPublicKeys(signKeyUserId);
      
      print('   ✅ Clés publiques récupérées');
      print('   DH key preview: ${dhKeys['dh_public_key']!.substring(0, 20)}...');
      print('   Sign key preview: ${signKeys['sign_public_key']!.substring(0, 20)}...');
      
      // 5. ✅ Déchiffrement avec les BONNES clés
      print('   🔓 Déchiffrement...');
      final decryptedBase64 = await _crypto.decryptMessage(
        ciphertextB64: message.encryptedContent,
        nonceB64: message.nonce!,
        authTagB64: message.authTag!,
        signatureB64: message.signature!,
        myDhPrivateKeyB64: myDhPrivateKey,
        theirDhPublicKeyB64: dhKeys['dh_public_key']!,      // ✅ CORRECT
        theirSignPublicKeyB64: signKeys['sign_public_key']!, // ✅ CORRECT
      );
      
      print('   ✅ Déchiffrement réussi');
      
      // 6. Décoder Base64
      final imageBytes = base64Decode(decryptedBase64);
      
      print('   ✅ Image décodée: ${imageBytes.length / 1024} KB');
      
      // 7. Sauvegarder en cache
      final file = await _fileService.saveToCacheDir(
        Uint8List.fromList(imageBytes),
        message.id,
        extension: 'jpg',
      );
      
      print('✅ Image ${message.id} prête: ${file.path}');
      
      return file;
      
    } catch (e, stack) {
      print('❌ Erreur decryptImage: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
  
  // ==================== MÉTADONNÉES ====================
  
  Future<Map<String, dynamic>> _extractImageMetadata(
    File imageFile,
    Uint8List compressedBytes,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(compressedBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      return {
        'width': image.width,
        'height': image.height,
        'size': compressedBytes.length,
        'format': 'jpg',
        'original_name': imageFile.path.split('/').last,
      };
      
    } catch (e) {
      return {
        'size': compressedBytes.length,
        'format': 'jpg',
      };
    }
  }
  
  // ==================== RÉCUPÉRATION CLÉS ====================
  
  Future<Map<String, String>> _getRecipientPublicKeys(String userId) async {
    try {
      final response = await _dio.privateDio.get(
        ApiEndpoints.getPublicKeys(userId),
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        
        return {
          'dh_public_key': data['dh_public_key'] as String,
          'sign_public_key': data['sign_public_key'] as String,
        };
      }
      
      throw Exception('Error ${response.statusCode}');
      
    } catch (e) {
      print('❌ Erreur récupération clés: $e');
      rethrow;
    }
  }
  
  // ==================== UTILITAIRES ====================
  
  Future<bool> isImageCached(String messageId) async {
    return await _fileService.existsInCache(messageId);
  }
  
  Future<void> deleteImageFromCache(String messageId) async {
    await _fileService.deleteFromCache(messageId);
  }
}




// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:get/get.dart';
// import '../models/message.dart';
// import 'crypto_service.dart';
// import 'file_service.dart';
// import 'secure_storage_service.dart';
// import '../api/dio_client.dart';
// import '../api/api_endpoints.dart';

// class ImageMessageService extends GetxService {
//   final CryptoService _crypto = Get.find<CryptoService>();
//   final FileService _fileService = Get.find<FileService>();
//   final SecureStorageService _storage = Get.find<SecureStorageService>();
//   final DioClient _dio = Get.find<DioClient>();
  
//   // ==================== ENVOI IMAGE ====================
  
//   Future<Message> sendImage({
//     required String conversationId,
//     required String recipientUserId,
//     required File imageFile,
//   }) async {
//     try {
//       // 1. Compression
//       final compressedBytes = await _fileService.compressImage(
//         imageFile,
//         maxSizeKB: 500,
//         quality: 85,
//       );
      
//       // 2. Métadonnées
//       final metadata = await _extractImageMetadata(imageFile, compressedBytes);
      
//       // 3. Récupérer clés E2EE
//       final myDhPrivateKey = await _storage.getDHPrivateKey();
//       final mySignPrivateKey = await _storage.getSignPrivateKey();
      
//       if (myDhPrivateKey == null || mySignPrivateKey == null) {
//         throw Exception('Clés E2EE manquantes');
//       }
      
//       // 4. Récupérer clés publiques destinataire
//       final recipientKeys = await _getRecipientPublicKeys(recipientUserId);
      
//       // 5. Convertir en Base64
//       final base64Image = base64Encode(compressedBytes);
      
//       // 6. Chiffrement
//       final encrypted = await _crypto.encryptMessage(
//         plaintext: base64Image,
//         myDhPrivateKeyB64: myDhPrivateKey,
//         theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
//         mySignPrivateKeyB64: mySignPrivateKey,
//       );
      
//       // 7. Préparation requête
//       final payload = {
//         'conversation_id': conversationId,
//         'recipient_user_id': recipientUserId,
//         'type': 'IMAGE',
//         'encrypted_content': encrypted['ciphertext']!,
//         'nonce': encrypted['nonce']!,
//         'auth_tag': encrypted['auth_tag']!,
//         'signature': encrypted['signature']!,
//         'metadata': metadata,
//       };
      
//       // 8. Envoi HTTP
//       final response = await _dio.privateDio.post(
//         ApiEndpoints.sendMessage,
//         data: payload,
//       );
      
//       // 9. Extraction message
//       final messageData = response.data['data'] as Map<String, dynamic>;
//       final message = Message.fromJson(messageData);
      
//       // 10. Sauvegarder en cache
//       await _fileService.saveToCacheDir(
//         compressedBytes,
//         message.id,
//         extension: 'jpg',
//       );
      
//       return message;
      
//     } catch (e) {
//       print('❌ Erreur sendImage: $e');
//       rethrow;
//     }
//   }
  
//   // ==================== RÉCEPTION IMAGE ====================
  
//   Future<File> decryptImage(Message message) async {
//     try {
//       // 1. Vérifier cache
//       final cachedFile = await _fileService.getFromCache(message.id);
//       if (cachedFile != null) {
//         return cachedFile;
//       }
      
//       // 2. Récupérer clés E2EE
//       final myDhPrivateKey = await _storage.getDHPrivateKey();
      
//       if (myDhPrivateKey == null) {
//         throw Exception('Clé DH manquante');
//       }
      
//       // 3. Récupérer clés publiques expéditeur
//       final senderKeys = await _getRecipientPublicKeys(message.senderId);
      
//       // 4. Déchiffrement
//       final decryptedBase64 = await _crypto.decryptMessage(
//         ciphertextB64: message.encryptedContent,
//         nonceB64: message.nonce!,
//         authTagB64: message.authTag!,
//         signatureB64: message.signature!,
//         myDhPrivateKeyB64: myDhPrivateKey,
//         theirDhPublicKeyB64: senderKeys['dh_public_key']!,
//         theirSignPublicKeyB64: senderKeys['sign_public_key']!,
//       );
      
//       // 5. Décoder Base64
//       final imageBytes = base64Decode(decryptedBase64);
      
//       // 6. Sauvegarder en cache
//       final file = await _fileService.saveToCacheDir(
//         Uint8List.fromList(imageBytes),
//         message.id,
//         extension: 'jpg',
//       );
      
//       return file;
      
//     } catch (e) {
//       print('❌ Erreur decryptImage: $e');
//       rethrow;
//     }
//   }
  
//   // ==================== MÉTADONNÉES ====================
  
//   Future<Map<String, dynamic>> _extractImageMetadata(
//     File imageFile,
//     Uint8List compressedBytes,
//   ) async {
//     try {
//       final codec = await ui.instantiateImageCodec(compressedBytes);
//       final frame = await codec.getNextFrame();
//       final image = frame.image;
      
//       return {
//         'width': image.width,
//         'height': image.height,
//         'size': compressedBytes.length,
//         'format': 'jpg',
//         'original_name': imageFile.path.split('/').last,
//       };
      
//     } catch (e) {
//       return {
//         'size': compressedBytes.length,
//         'format': 'jpg',
//       };
//     }
//   }
  
//   // ==================== RÉCUPÉRATION CLÉS ====================
  
//   Future<Map<String, String>> _getRecipientPublicKeys(String userId) async {
//     try {
//       final response = await _dio.privateDio.get(
//         ApiEndpoints.getPublicKeys(userId),
//       );
      
//       if (response.statusCode == 200) {
//         final data = response.data['data'] as Map<String, dynamic>;
        
//         return {
//           'dh_public_key': data['dh_public_key'] as String,
//           'sign_public_key': data['sign_public_key'] as String,
//         };
//       }
      
//       throw Exception('Error ${response.statusCode}');
      
//     } catch (e) {
//       print('❌ Erreur récupération clés: $e');
//       rethrow;
//     }
//   }
  
//   // ==================== UTILITAIRES ====================
  
//   Future<bool> isImageCached(String messageId) async {
//     return await _fileService.existsInCache(messageId);
//   }
  
//   Future<void> deleteImageFromCache(String messageId) async {
//     await _fileService.deleteFromCache(messageId);
//   }
// }