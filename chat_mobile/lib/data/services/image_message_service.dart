// lib/data/services/image_message_service.dart

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

  // Cache des clés publiques (même pattern que MessageService)
  final Map<String, _CachedKeys> _publicKeysCache = {};

  Future<Message> sendImage({
    required String conversationId,
    required String recipientUserId,
    required File imageFile,
  }) async {
    // Compression
    final compressedBytes = await _fileService.compressImage(
      imageFile,
      maxSizeKB: 500,
      quality: 85,
    );

    final metadata = await _extractImageMetadata(imageFile, compressedBytes);

    // Clés E2EE
    final myDhPrivateKey = await _storage.getDHPrivateKey();
    final mySignPrivateKey = await _storage.getSignPrivateKey();

    if (myDhPrivateKey == null || mySignPrivateKey == null) {
      throw Exception('Clés E2EE manquantes');
    }

    final recipientKeys = await _getPublicKeysCached(recipientUserId);
    final base64Image = base64Encode(compressedBytes);

    // Chiffrement (Isolate via CryptoService si pas en cache)
    final encrypted = await _crypto.encryptMessage(
      plaintext: base64Image,
      myDhPrivateKeyB64: myDhPrivateKey,
      theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
      mySignPrivateKeyB64: mySignPrivateKey,
    );

    final response = await _dio.privateDio.post(
      ApiEndpoints.sendMessage,
      data: {
        'conversation_id': conversationId,
        'recipient_user_id': recipientUserId,
        'type': 'IMAGE',
        'encrypted_content': encrypted['ciphertext']!,
        'nonce': encrypted['nonce']!,
        'auth_tag': encrypted['auth_tag']!,
        'signature': encrypted['signature']!,
        'metadata': metadata,
      },
    );

    final message = Message.fromJson(response.data['data'] as Map<String, dynamic>);

    // Sauvegarder en cache
    await _fileService.saveToCacheDir(
      compressedBytes,
      message.id,
      extension: 'jpg',
    );

    return message;
  }

  Future<File> decryptImage(Message message) async {
    // Vérifier cache fichier
    final cachedFile = await _fileService.getFromCache(message.id);
    if (cachedFile != null) return cachedFile;

    final myDhPrivateKey = await _storage.getDHPrivateKey();
    final currentUserId = await _storage.getUserId();

    if (myDhPrivateKey == null || currentUserId == null) {
      throw Exception('Clés ou userId manquants');
    }

    // Déterminer les bonnes clés (même logique que MessageService.decryptMessage)
    String dhKeyUserId;
    String signKeyUserId;
    final isMyMessage = message.senderId == currentUserId;

    if (isMyMessage) {
      if (message.recipientUserId == null || message.recipientUserId!.isEmpty) {
        throw Exception('recipientUserId manquant');
      }
      dhKeyUserId = message.recipientUserId!;
      signKeyUserId = currentUserId;
    } else {
      dhKeyUserId = message.senderId;
      signKeyUserId = message.senderId;
    }

    final dhKeys = await _getPublicKeysCached(dhKeyUserId);
    final signKeys = dhKeyUserId == signKeyUserId
        ? dhKeys
        : await _getPublicKeysCached(signKeyUserId);

    // Déchiffrement (Isolate si premier message de cette conversation)
    final decryptedBase64 = await _crypto.decryptMessage(
      ciphertextB64: message.encryptedContent,
      nonceB64: message.nonce!,
      authTagB64: message.authTag!,
      signatureB64: message.signature!,
      myDhPrivateKeyB64: myDhPrivateKey,
      theirDhPublicKeyB64: dhKeys['dh_public_key']!,
      theirSignPublicKeyB64: signKeys['sign_public_key']!,
    );

    final imageBytes = base64Decode(decryptedBase64);

    return await _fileService.saveToCacheDir(
      Uint8List.fromList(imageBytes),
      message.id,
      extension: 'jpg',
    );
  }

  Future<Map<String, String>> _getPublicKeysCached(String userId) async {
    final cached = _publicKeysCache[userId];
    if (cached != null && !cached.isExpired) return cached.keys;

    final response = await _dio.privateDio.get(
      ApiEndpoints.getPublicKeys(userId),
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>;
      final keys = {
        'dh_public_key': data['dh_public_key'] as String,
        'sign_public_key': data['sign_public_key'] as String,
      };

      _publicKeysCache[userId] = _CachedKeys(
        keys: keys,
        fetchedAt: DateTime.now(),
      );
      return keys;
    }

    throw Exception('Erreur récupération clés');
  }

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
    } catch (_) {
      return {
        'size': compressedBytes.length,
        'format': 'jpg',
      };
    }
  }

  Future<bool> isImageCached(String messageId) async {
    return await _fileService.existsInCache(messageId);
  }

  Future<void> deleteImageFromCache(String messageId) async {
    await _fileService.deleteFromCache(messageId);
  }
}

class _CachedKeys {
  final Map<String, String> keys;
  final DateTime fetchedAt;
  _CachedKeys({required this.keys, required this.fetchedAt});
  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 30);
}