// lib/data/services/message_service.dart

import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import '../api/api_endpoints.dart';
import '../api/dio_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'crypto_service.dart';
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
  
  @override
  void onInit() {
    super.onInit();
    _listenWebSocket();
    print('✅ MessageService initialized');
  }
  
  @override
  void onClose() {
    _wsSubscription?.cancel();
    _newMessagesController.close();
    super.onClose();
  }
  
  void _listenWebSocket() {
    _wsSubscription = _wsService.messageStream.listen((data) {
      final type = data['type'] as String?;
      
      if (type == 'new_message') {
        _handleNewMessage(data);
      } else if (type == 'typing') {
        print('⌨️ ${data['user_name']} typing...');
      } else if (type == 'message_read_receipt') {
        print('✅ Message read: ${data['message_id']}');
      }
    });
  }
  
  Future<void> _handleNewMessage(Map<String, dynamic> data) async {  // ← AJOUT : async
  try {
    final messageData = data['message'] as Map<String, dynamic>;
    final message = Message.fromJson(messageData);
    
    print('📨 Nouveau message reçu: ${message.id}');
    print('   Type: ${message.type}');
    print('   Sender: ${message.senderId}');
    
    final currentUserId = _authService.currentUser.value?.userId;
    
    // ✅ Si c'est notre propre message, le passer directement
    if (message.senderId == currentUserId) {
      // Vérifier si on a le plaintext en cache
      final cached = await _secureStorage.getMessagePlaintext(message.id);
      if (cached != null) {
        _newMessagesController.add(message.copyWith(decryptedContent: cached));
      } else {
        _newMessagesController.add(message);
      }
      return;
    }
    
    // ✅ FIX CRITIQUE : Déchiffrer AVANT d'émettre dans le stream
    try {
      print('🔓 Déchiffrement en temps réel...');
      
      final decryptedContent = await decryptMessage(message);
      
      // Sauvegarder en cache pour la prochaine fois
      await _secureStorage.saveMessagePlaintext(message.id, decryptedContent);
      
      // Créer message avec contenu déchiffré
      final decryptedMessage = message.copyWith(
        decryptedContent: decryptedContent,
      );
      
      print('✅ Message déchiffré: ${decryptedContent.substring(0, 20)}...');
      
      // Émettre le message DÉCHIFFRÉ
      _newMessagesController.add(decryptedMessage);
      
    } catch (e) {
      print('❌ Erreur déchiffrement temps réel: $e');
      // En cas d'erreur, émettre quand même (sera réessayé au chargement)
      _newMessagesController.add(message.copyWith(
        decryptedContent: '[Message illisible]'
      ));
    }
    
  } catch (e) {
    print('❌ Handle new message error: $e');
  }
}
  
  // Future<void> _decryptAndEmit(Message message) async {
  //   try {
  //     final decrypted = await decryptMessage(message);
  //     final decryptedMessage = message.copyWith(decryptedContent: decrypted);
  //     _newMessagesController.add(decryptedMessage);
  //   } catch (e) {
  //     print('❌ Decrypt and emit error: $e');
  //     _newMessagesController.add(message);
  //   }
  // }
  
  Future<List<Conversation>?> getConversations() async {
    try {
      print('📥 Fetching conversations...');
      
      final response = await _dioClient.privateDio.get(ApiEndpoints.conversations);
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final conversations = data.map((json) => Conversation.fromJson(json)).toList();
        print('✅ ${conversations.length} conversations loaded');
        return conversations;
      }
      
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      print('❌ getConversations error: $e');
      return null;
    }
  }
  
  Future<Conversation?> createDirectConversation(String participantUserId) async {
    try {
      print('📝 Creating conversation with: $participantUserId');
      
      final response = await _dioClient.privateDio.post(
        ApiEndpoints.createConversation,
        data: {
          'type': 'DIRECT',
          'participant_ids': [participantUserId],
        },
      );
      
      if (response.statusCode == 201) {
        final conversation = Conversation.fromJson(response.data['data']);
        print('✅ Conversation created: ${conversation.id}');
        return conversation;
      }
      
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      print('❌ createDirectConversation error: $e');
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
      print('❌ getCurrentUser error: $e');
      return null;
    }
  }
  
  Future<Message> sendMessage({
    required String conversationId,
    required String recipientUserId,
    required String content,
    String type = 'TEXT',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('📤 Sending message...');
      
      final encrypted = await encryptMessage(recipientUserId, content);
      
      final data = {
        'conversation_id': conversationId,
        'recipient_user_id': recipientUserId,
        'type': type,
        'encrypted_content': encrypted['ciphertext'],
        'nonce': encrypted['nonce'],
        'auth_tag': encrypted['auth_tag'],
        'signature': encrypted['signature'],
        if (metadata != null) 'metadata': metadata,
      };
      
      final response = await _dioClient.privateDio.post(
        ApiEndpoints.sendMessage,
        data: data,
      );
      
      if (response.statusCode == 201) {
        final messageData = response.data['data'] as Map<String, dynamic>;
        final message = Message.fromJson(messageData);
        
        print('✅ Message sent: ${message.id}');
        
        await _secureStorage.saveMessagePlaintext(message.id, content);
        
        return message.copyWith(decryptedContent: content);
      }
      
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      print('❌ sendMessage error: $e');
      rethrow;
    }
  }
  
  Future<List<Message>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      print('📥 Fetching messages: $conversationId');
      
      final response = await _dioClient.privateDio.get(
        ApiEndpoints.getMessagesByConversation(conversationId),
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final messages = data.map((json) => Message.fromJson(json)).toList();
        
        print('✅ ${messages.length} messages fetched');
        
        final decryptedMessages = await _decryptMessages(messages);
        
        return decryptedMessages;
      }
      
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      print('❌ getConversationMessages error: $e');
      rethrow;
    }
  }

Future<List<Message>> _decryptMessages(List<Message> messages) async {
  final decrypted = <Message>[];
  final currentUserId = _authService.currentUser.value?.userId;
  
  for (final message in messages) {
    try {
      // ✅ Vérifier champs E2EE obligatoires
      if (message.nonce == null || message.nonce!.isEmpty ||
          message.authTag == null || message.authTag!.isEmpty ||
          message.signature == null || message.signature!.isEmpty) {
        print('⚠️ Message ${message.id} sans champs E2EE complets');
        decrypted.add(message.copyWith(
          decryptedContent: '[Message non chiffré]'
        ));
        continue;
      }
      
      // ✅ Vérifier cache en premier
      final cached = await _secureStorage.getMessagePlaintext(message.id);
      
      if (cached != null) {
        decrypted.add(message.copyWith(decryptedContent: cached));
        print('📦 From cache: ${message.id}');
        continue;
      }
      
      // ✅ Déchiffrer
      final content = await decryptMessage(message);
      
      // ✅ Sauvegarder en cache pour la prochaine fois
      await _secureStorage.saveMessagePlaintext(message.id, content);
      
      decrypted.add(message.copyWith(decryptedContent: content));
      
      final preview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
      print('✅ Decrypted: ${message.id} - "$preview"');
      
    } catch (e) {
      print('❌ Decrypt error ${message.id}: $e');
      
      // ✅ Message d'erreur informatif selon le type d'erreur
      String fallbackText;
      
      if (e.toString().contains('Signature invalide')) {
        fallbackText = '[⚠️ Message chiffré avec anciennes clés]';
      } else if (e.toString().contains('recipientUserId missing')) {
        fallbackText = '[❌ Destinataire inconnu]';
      } else if (e.toString().contains('E2EE fields missing')) {
        fallbackText = '[💥 Message corrompu]';
      } else {
        fallbackText = '[🔒 Message illisible]';
      }
      
      decrypted.add(message.copyWith(decryptedContent: fallbackText));
    }
  }
  
  return decrypted;
}

Future<String> decryptMessage(Message message) async {
  try {
    print('🔓 === DÉCHIFFREMENT MESSAGE ===');
    print('   Message ID: ${message.id}');
    print('   From: ${message.senderId}');
    
    // ✅ VÉRIFICATION STRICTE des champs E2EE
    if (message.nonce == null || message.nonce!.isEmpty) {
      throw Exception('E2EE fields missing: nonce');
    }
    if (message.authTag == null || message.authTag!.isEmpty) {
      throw Exception('E2EE fields missing: authTag');
    }
    if (message.signature == null || message.signature!.isEmpty) {
      throw Exception('E2EE fields missing: signature');
    }
    
    final currentUserId = _authService.currentUser.value?.userId;
    final myDhPrivate = await _secureStorage.getDHPrivateKey();
    
    if (myDhPrivate == null) {
      throw Exception('Private key missing');
    }
    
    String dhKeyOwnerId;  // Propriétaire de la clé DH publique utilisée pour chiffrement
    String signKeyOwnerId; // Propriétaire de la clé Sign publique pour vérification signature
    
    if (message.senderId == currentUserId) {
      
      print('   ℹ️ Message envoyé par NOUS');
      
      // ✅ DH : On a chiffré POUR le destinataire → Utiliser sa clé DH publique
      if (message.recipientUserId == null || message.recipientUserId!.isEmpty) {
        throw Exception('recipientUserId missing for own message');
      }
      dhKeyOwnerId = message.recipientUserId!;
      
      // ✅ SIGNATURE : On a signé avec NOTRE clé Sign privée → Vérifier avec NOTRE clé Sign publique
      signKeyOwnerId = currentUserId!;
      
      print('   🔐 DH Key: Clés du DESTINATAIRE $dhKeyOwnerId');
      print('   ✍️ Sign Key: NOTRE clé publique $signKeyOwnerId');
      
    } else {
      
      print('   ℹ️ Message reçu de l\'extérieur');
      
      // ✅ DH : Ils ont chiffré POUR nous → Ils ont utilisé NOTRE clé DH publique → On utilise LEUR clé DH publique
      dhKeyOwnerId = message.senderId;
      
      // ✅ SIGNATURE : Ils ont signé avec LEUR clé Sign privée → Vérifier avec LEUR clé Sign publique
      signKeyOwnerId = message.senderId;
      
      print('   🔐 DH Key: Clés de l\'EXPÉDITEUR $dhKeyOwnerId');
      print('   ✍️ Sign Key: Clé publique de l\'EXPÉDITEUR $signKeyOwnerId');
    }
    
    
    final dhKeys = await _getRecipientPublicKeys(dhKeyOwnerId);
    final signKeys = await _getRecipientPublicKeys(signKeyOwnerId);
    
    print('   ✅ Clés DH récupérées de $dhKeyOwnerId');
    print('   ✅ Clés Sign récupérées de $signKeyOwnerId');
   
    final plaintext = await _cryptoService.decryptMessage(
      ciphertextB64: message.encryptedContent,
      nonceB64: message.nonce!,
      authTagB64: message.authTag!,
      signatureB64: message.signature!,
      myDhPrivateKeyB64: myDhPrivate,
      theirDhPublicKeyB64: dhKeys['dh_public_key']!,      // ← Pour DH
      theirSignPublicKeyB64: signKeys['sign_public_key']!, // ← Pour signature
    );
    
    print('✅ Déchiffrement réussi: ${plaintext.substring(0, min(20, plaintext.length))}...');
    
    return plaintext;
    
  } catch (e) {
    print('❌ decryptMessage error: $e');
    rethrow;
  }
}



// Future<String> decryptMessage(Message message) async {
//   try {
//     print('🔓 Decrypting message ${message.id}');
//     print('   From: ${message.senderId}');
    
//     // ✅ VÉRIFICATION STRICTE des champs E2EE
//     if (message.nonce == null || message.nonce!.isEmpty) {
//       throw Exception('E2EE fields missing: nonce');
//     }
//     if (message.authTag == null || message.authTag!.isEmpty) {
//       throw Exception('E2EE fields missing: authTag');
//     }
//     if (message.signature == null || message.signature!.isEmpty) {
//       throw Exception('E2EE fields missing: signature');
//     }
    
//     final myDhPrivate = await _secureStorage.getDHPrivateKey();
    
//     if (myDhPrivate == null) {
//       throw Exception('Private key missing');
//     }
    
//     final currentUserId = _authService.currentUser.value?.userId;
    
//     // ✅ LOGIQUE CORRECTE : Déterminer qui est "l'autre"
//     String otherUserId;
    
//     if (message.senderId == currentUserId) {
//       // ✅ CAS 1 : C'est NOTRE message → Utiliser le DESTINATAIRE
//       if (message.recipientUserId == null || message.recipientUserId!.isEmpty) {
//         // ⚠️ FALLBACK : Si recipient manque, chercher dans participants
//         print('   ⚠️ recipientUserId manquant, tentative fallback...');
        
//         // Option A : Utiliser le premier participant qui n'est pas nous
//         // (nécessite d'avoir accès à la conversation, sinon lever exception)
//         throw Exception('recipientUserId missing for own message');
//       }
      
//       otherUserId = message.recipientUserId!;
//       print('   → Message de NOUS → Clés du DESTINATAIRE: $otherUserId');
      
//     } else {
//       // ✅ CAS 2 : Message REÇU → Utiliser l'EXPÉDITEUR
//       otherUserId = message.senderId;
//       print('   → Message REÇU → Clés de l\'EXPÉDITEUR: $otherUserId');
//     }
    
//     // ✅ Récupérer clés publiques de "l'autre"
//     final otherUserKeys = await _getRecipientPublicKeys(otherUserId);
    
//     // ✅ Déchiffrer
//     final plaintext = await _cryptoService.decryptMessage(
//       ciphertextB64: message.encryptedContent,
//       nonceB64: message.nonce!,
//       authTagB64: message.authTag!,
//       signatureB64: message.signature!,
//       myDhPrivateKeyB64: myDhPrivate,
//       theirDhPublicKeyB64: otherUserKeys['dh_public_key']!,
//       theirSignPublicKeyB64: otherUserKeys['sign_public_key']!,
//     );
    
//     print('✅ Déchiffrement réussi');
    
//     return plaintext;
    
//   } catch (e) {
//     print('❌ decryptMessage error: $e');
//     rethrow;
//   }
// }
  
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _dioClient.privateDio.post(
        ApiEndpoints.markAsRead,
        data: {'conversation_id': conversationId},
      );
      print('✅ Marked as read');
    } catch (e) {
      print('❌ markConversationAsRead error: $e');
    }
  }
  
  Future<Map<String, String>> encryptMessage(
    String recipientUserId,
    String plaintext,
  ) async {
    try {
      print('🔐 Encrypting for: $recipientUserId');
      
      final myDhPrivate = await _secureStorage.getDHPrivateKey();
      final mySignPrivate = await _secureStorage.getSignPrivateKey();
      
      if (myDhPrivate == null || mySignPrivate == null) {
        throw Exception('Private keys missing');
      }
      
      final recipientKeys = await _getRecipientPublicKeys(recipientUserId);
      
      final encrypted = await _cryptoService.encryptMessage(
        plaintext: plaintext,
        myDhPrivateKeyB64: myDhPrivate,
        theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
        mySignPrivateKeyB64: mySignPrivate,
      );
      
      print('✅ Encrypted');
      
      return encrypted;
    } catch (e) {
      print('❌ encryptMessage error: $e');
      rethrow;
    }
  }
  
  
  Future<Map<String, String>> _getRecipientPublicKeys(String userId) async {
    try {
      final response = await _dioClient.privateDio.get(
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
      print('❌ getPublicKeys error: $e');
      rethrow;
    }
  }
  
  void joinConversation(String conversationId) {
    _wsService.joinConversation(conversationId);
  }
  
  void sendTypingIndicator(String conversationId, bool isTyping) {
    _wsService.sendTyping(conversationId, isTyping);
  }
}

