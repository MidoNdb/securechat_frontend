// lib/data/services/message_service.dart

import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import '../api/api_endpoints.dart';
import '../api/dio_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'crypto_service.dart';
import 'crypto_isolate.dart';
import 'websocket_service.dart';
import 'auth_service.dart';
import 'secure_storage_service.dart';

class MessageService extends GetxService {
  final DioClient _dioClient = Get.find<DioClient>();
  final CryptoService _cryptoService = Get.find<CryptoService>();
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final AuthService _authService = Get.find<AuthService>();
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();

  StreamSubscription? _wsSubscription;
  final _newMessagesController = StreamController<Message>.broadcast();
  Stream<Message> get newMessagesStream => _newMessagesController.stream;

  // ══════════════════════════════════════════════════════════
  // CACHE DES CLÉS PUBLIQUES
  // ══════════════════════════════════════════════════════════

  final Map<String, _CachedPublicKeys> _publicKeysCache = {};

  @override
  void onInit() {
    super.onInit();
    _listenWebSocket();
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    _newMessagesController.close();
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════
  // WEBSOCKET LISTENER
  // ══════════════════════════════════════════════════════════

  void _listenWebSocket() {
    _wsSubscription = _wsService.messageStream.listen((data) {
      final type = data['type'] as String?;
      if (type == 'new_message') {
        _handleNewMessage(data);
      }
    });
  }

  Future<void> _handleNewMessage(Map<String, dynamic> data) async {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      final currentUserId = _authService.currentUser.value?.userId;

      if (message.senderId == currentUserId) {
        final cached = await _secureStorage.getMessagePlaintext(message.id);
        _newMessagesController.add(
          cached != null ? message.copyWith(decryptedContent: cached) : message,
        );
        return;
      }

      try {
        final plaintext = await decryptMessage(message);
        await _secureStorage.saveMessagePlaintext(message.id, plaintext);
        _newMessagesController.add(message.copyWith(decryptedContent: plaintext));
      } catch (e) {
        _newMessagesController.add(
          message.copyWith(decryptedContent: '[Message illisible]'),
        );
      }
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ══════════════════════════════════════════════════════════

  Future<List<Conversation>?> getConversations() async {
    try {
      final response = await _dioClient.privateDio.get(ApiEndpoints.conversations);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => Conversation.fromJson(json)).toList();
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      return null;
    }
  }

  Future<Conversation?> createDirectConversation(String participantUserId) async {
    try {
      final response = await _dioClient.privateDio.post(
        ApiEndpoints.createConversation,
        data: {
          'type': 'DIRECT',
          'participant_ids': [participantUserId],
        },
      );
      if (response.statusCode == 201) {
        return Conversation.fromJson(response.data['data']);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dioClient.privateDio.get(ApiEndpoints.me);
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // ENVOI MESSAGE
  // ══════════════════════════════════════════════════════════

  Future<Message> sendMessage({
    required String conversationId,
    required String recipientUserId,
    required String content,
    String type = 'TEXT',
    Map<String, dynamic>? metadata,
  }) async {
    final encrypted = await encryptMessage(recipientUserId, content);

    final response = await _dioClient.privateDio.post(
      ApiEndpoints.sendMessage,
      data: {
        'conversation_id': conversationId,
        'recipient_user_id': recipientUserId,
        'type': type,
        'encrypted_content': encrypted['ciphertext'],
        'nonce': encrypted['nonce'],
        'auth_tag': encrypted['auth_tag'],
        'signature': encrypted['signature'],
        if (metadata != null) 'metadata': metadata,
      },
    );

    if (response.statusCode == 201) {
      final message = Message.fromJson(response.data['data'] as Map<String, dynamic>);
      await _secureStorage.saveMessagePlaintext(message.id, content);
      return message.copyWith(decryptedContent: content);
    }

    throw Exception('Error ${response.statusCode}');
  }

  // ══════════════════════════════════════════════════════════
  // CHARGEMENT + DÉCHIFFREMENT BATCH (Isolate)
  // ══════════════════════════════════════════════════════════

  Future<List<Message>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dioClient.privateDio.get(
      ApiEndpoints.getMessagesByConversation(conversationId),
      queryParameters: {'page': page, 'page_size': pageSize},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      final messages = data.map((json) => Message.fromJson(json)).toList();
      return await _decryptMessages(messages);
    }

    throw Exception('Error ${response.statusCode}');
  }

  Future<List<Message>> _decryptMessages(List<Message> messages) async {
    final currentUserId = _authService.currentUser.value?.userId;
    final myDhPrivate = await _secureStorage.getDHPrivateKey();

    if (myDhPrivate == null) {
      return messages.map((m) =>
        m.copyWith(decryptedContent: '[Clé privée manquante]')
      ).toList();
    }

    // Phase 1 : Séparer les messages déjà en cache des messages à déchiffrer
    final decrypted = <int, Message>{};
    final toDecrypt = <int, Message>{};
    final userIdsNeeded = <String>{};

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];

      if (!_hasE2EEFields(msg)) {
        decrypted[i] = msg.copyWith(decryptedContent: '[Non chiffré]');
        continue;
      }

      // Vérifier cache plaintext
      final cached = await _secureStorage.getMessagePlaintext(msg.id);
      if (cached != null) {
        decrypted[i] = msg.copyWith(decryptedContent: cached);
        continue;
      }

      toDecrypt[i] = msg;

      // Collecter les userIds nécessaires pour les clés publiques
      if (msg.senderId == currentUserId) {
        if (msg.recipientUserId != null && msg.recipientUserId!.isNotEmpty) {
          userIdsNeeded.add(msg.recipientUserId!);
        }
        if (currentUserId != null) userIdsNeeded.add(currentUserId);
      } else {
        userIdsNeeded.add(msg.senderId);
      }
    }

    // Si tout est en cache, pas besoin d'Isolate
    if (toDecrypt.isEmpty) {
      return List.generate(messages.length, (i) => decrypted[i]!);
    }

    // Phase 2 : Pré-charger les clés publiques en parallèle
    await Future.wait(userIdsNeeded.map((id) => _getPublicKeysCached(id)));

    // Phase 3 : Préparer les items pour le batch Isolate
    final batchItems = <DecryptItemParams>[];
    final indexToMessageId = <String, int>{};

    for (final entry in toDecrypt.entries) {
      final msg = entry.value;
      String dhKeyOwnerId;
      String signKeyOwnerId;

      if (msg.senderId == currentUserId) {
        if (msg.recipientUserId == null || msg.recipientUserId!.isEmpty) {
          decrypted[entry.key] = msg.copyWith(decryptedContent: '[Destinataire inconnu]');
          continue;
        }
        dhKeyOwnerId = msg.recipientUserId!;
        signKeyOwnerId = currentUserId!;
      } else {
        dhKeyOwnerId = msg.senderId;
        signKeyOwnerId = msg.senderId;
      }

      final dhKeys = _publicKeysCache[dhKeyOwnerId]?.keys;
      final signKeys = dhKeyOwnerId == signKeyOwnerId
          ? dhKeys
          : _publicKeysCache[signKeyOwnerId]?.keys;

      if (dhKeys == null || signKeys == null) {
        decrypted[entry.key] = msg.copyWith(decryptedContent: '[Clés publiques manquantes]');
        continue;
      }

      batchItems.add(DecryptItemParams(
        messageId: msg.id,
        ciphertextB64: msg.encryptedContent,
        nonceB64: msg.nonce!,
        authTagB64: msg.authTag!,
        signatureB64: msg.signature!,
        theirDhPublicKeyB64: dhKeys['dh_public_key']!,
        theirSignPublicKeyB64: signKeys['sign_public_key']!,
      ));

      indexToMessageId[msg.id] = entry.key;
    }

    // Phase 4 : Déchiffrement batch dans UN SEUL Isolate
    if (batchItems.isNotEmpty) {
      final batchResult = await _cryptoService.decryptBatch(
        items: batchItems,
        myDhPrivateKeyB64: myDhPrivate,
      );

      // Traiter les résultats
      for (final entry in batchResult.successes.entries) {
        final idx = indexToMessageId[entry.key];
        if (idx != null) {
          final msg = toDecrypt[idx]!;
          decrypted[idx] = msg.copyWith(decryptedContent: entry.value);
          // Sauvegarder en cache pour la prochaine fois
          _secureStorage.saveMessagePlaintext(entry.key, entry.value);
        }
      }

      for (final entry in batchResult.errors.entries) {
        final idx = indexToMessageId[entry.key];
        if (idx != null) {
          final msg = toDecrypt[idx]!;
          final fallback = entry.value.contains('Signature invalide')
              ? '[Clés incompatibles]'
              : '[Message illisible]';
          decrypted[idx] = msg.copyWith(decryptedContent: fallback);
        }
      }
    }

    // Phase 5 : Rassembler dans l'ordre original
    return List.generate(messages.length, (i) {
      return decrypted[i] ?? messages[i].copyWith(decryptedContent: '[Erreur]');
    });
  }

  bool _hasE2EEFields(Message msg) {
    return msg.nonce != null &&
        msg.nonce!.isNotEmpty &&
        msg.authTag != null &&
        msg.authTag!.isNotEmpty &&
        msg.signature != null &&
        msg.signature!.isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════
  // DÉCHIFFREMENT UNITAIRE (pour les messages temps réel)
  // ══════════════════════════════════════════════════════════

  Future<String> decryptMessage(Message message) async {
    if (!_hasE2EEFields(message)) {
      throw Exception('E2EE fields missing');
    }

    final currentUserId = _authService.currentUser.value?.userId;
    final myDhPrivate = await _secureStorage.getDHPrivateKey();

    if (myDhPrivate == null) {
      throw Exception('Private key missing');
    }

    String dhKeyOwnerId;
    String signKeyOwnerId;

    if (message.senderId == currentUserId) {
      if (message.recipientUserId == null || message.recipientUserId!.isEmpty) {
        throw Exception('recipientUserId missing');
      }
      dhKeyOwnerId = message.recipientUserId!;
      signKeyOwnerId = currentUserId!;
    } else {
      dhKeyOwnerId = message.senderId;
      signKeyOwnerId = message.senderId;
    }

    final dhKeys = await _getPublicKeysCached(dhKeyOwnerId);
    final signKeys = dhKeyOwnerId == signKeyOwnerId
        ? dhKeys
        : await _getPublicKeysCached(signKeyOwnerId);

    return await _cryptoService.decryptMessage(
      ciphertextB64: message.encryptedContent,
      nonceB64: message.nonce!,
      authTagB64: message.authTag!,
      signatureB64: message.signature!,
      myDhPrivateKeyB64: myDhPrivate,
      theirDhPublicKeyB64: dhKeys['dh_public_key']!,
      theirSignPublicKeyB64: signKeys['sign_public_key']!,
    );
  }

  // ══════════════════════════════════════════════════════════
  // CHIFFREMENT
  // ══════════════════════════════════════════════════════════

  Future<Map<String, String>> encryptMessage(
    String recipientUserId,
    String plaintext,
  ) async {
    final myDhPrivate = await _secureStorage.getDHPrivateKey();
    final mySignPrivate = await _secureStorage.getSignPrivateKey();

    if (myDhPrivate == null || mySignPrivate == null) {
      throw Exception('Private keys missing');
    }

    final recipientKeys = await _getPublicKeysCached(recipientUserId);

    return await _cryptoService.encryptMessage(
      plaintext: plaintext,
      myDhPrivateKeyB64: myDhPrivate,
      theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
      mySignPrivateKeyB64: mySignPrivate,
    );
  }

  // ══════════════════════════════════════════════════════════
  // CACHE DES CLÉS PUBLIQUES (TTL 30 min)
  // ══════════════════════════════════════════════════════════

  Future<Map<String, String>> _getPublicKeysCached(String userId) async {
    final cached = _publicKeysCache[userId];
    if (cached != null && !cached.isExpired) {
      return cached.keys;
    }

    final response = await _dioClient.privateDio.get(
      ApiEndpoints.getPublicKeys(userId),
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>;
      final keys = {
        'dh_public_key': data['dh_public_key'] as String,
        'sign_public_key': data['sign_public_key'] as String,
      };

      _publicKeysCache[userId] = _CachedPublicKeys(
        keys: keys,
        fetchedAt: DateTime.now(),
      );

      return keys;
    }

    throw Exception('Failed to fetch public keys for $userId');
  }

  void invalidatePublicKeysCache([String? userId]) {
    if (userId != null) {
      _publicKeysCache.remove(userId);
    } else {
      _publicKeysCache.clear();
    }
  }

  // ══════════════════════════════════════════════════════════
  // UTILITAIRES
  // ══════════════════════════════════════════════════════════

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _dioClient.privateDio.post(
        ApiEndpoints.markAsRead,
        data: {'conversation_id': conversationId},
      );
    } catch (_) {}
  }

  void joinConversation(String conversationId) {
    _wsService.joinConversation(conversationId);
  }

  void sendTypingIndicator(String conversationId, bool isTyping) {
    _wsService.sendTyping(conversationId, isTyping);
  }
}

class _CachedPublicKeys {
  final Map<String, String> keys;
  final DateTime fetchedAt;

  _CachedPublicKeys({required this.keys, required this.fetchedAt});

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 30);
}