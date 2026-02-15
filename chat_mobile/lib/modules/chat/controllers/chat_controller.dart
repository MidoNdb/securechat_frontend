
import 'dart:io';
import 'dart:async';
import 'package:chat_mobile/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';
import '../../../data/services/message_service.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/services/secure_storage_service.dart';
import '../../../data/services/image_message_service.dart';
import '../../../data/services/voice_message_service.dart';

class ChatController extends GetxController {
  final MessageService _messageService = Get.find<MessageService>();
  final WebSocketService _websocketService = Get.find<WebSocketService>();
  final SecureStorageService _storage = Get.find<SecureStorageService>();
  
  late final ImageMessageService _imageService;
  late final VoiceMessageService _voiceService;
  
  // Conversation
  late Conversation conversation;

  // UI Controllers
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // States
  final messages = <Message>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSendingMessage = false.obs;
  final hasMessageText = false.obs;
  
  // Images sélectionnées
  final selectedImages = <File>[].obs;

  // User ID
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMoreMessages = true;

  StreamSubscription? _newMessagesSubscription;
  StreamSubscription? _callSignalsSubscription;

  @override
  void onInit() {
    super.onInit();
    
    // Initialiser les services multimédia
    try {
      _imageService = Get.find<ImageMessageService>();
      print('ImageMessageService initialisé');
    } catch (e) {
      print('ImageMessageService non disponible: $e');
    }
    
    try {
      _voiceService = Get.find<VoiceMessageService>();
      print('VoiceMessageService initialisé');
    } catch (e) {
      print('VoiceMessageService non disponible: $e');
    }
    
    // Écouter changements TextField
    messageController.addListener(() {
      final hasText = messageController.text.trim().isNotEmpty;
      if (hasMessageText.value != hasText) {
        hasMessageText.value = hasText;
      }
    });
    
    _initChat();
  }

 Future<void> _initChat() async {
  try {
    final args = Get.arguments as Map<String, dynamic>;
    conversation = args['conversation'] as Conversation;

    await _loadCurrentUserId();

    if (!_websocketService.isConnected.value) {
      await _websocketService.connect();
    }

    _messageService.joinConversation(conversation.id);
    await loadMessages();
    _listenNewMessages();
    _listenCallSignals();
    
    await _messageService.markConversationAsRead(conversation.id);

  } catch (e) {
    print('Erreur init chat: $e');
    _showError('Impossible de charger le chat');
  }
}

  Future<void> _loadCurrentUserId() async {
    try {
      final userId = await _storage.getUserId();
      _currentUserId = userId;
      print('User ID chargé: $userId');
    } catch (e) {
      print('Erreur chargement user ID: $e');
    }
  }

  Future<void> loadMessages({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;

      final loadedMessages = await _messageService.getConversationMessages(
        conversationId: conversation.id,
        page: _currentPage,
        pageSize: _pageSize,
      );

      messages.value = loadedMessages.reversed.toList();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

    } catch (e) {
      print('Erreur loadMessages: $e');
      _showError('Impossible de charger les messages');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onLoadMore() async {
    if (isLoadingMore.value || !_hasMoreMessages) return;

    try {
      isLoadingMore.value = true;
      _currentPage++;

      final olderMessages = await _messageService.getConversationMessages(
        conversationId: conversation.id,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (olderMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        messages.insertAll(0, olderMessages.reversed);
      }

    } catch (e) {
      print('Erreur onLoadMore: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _listenNewMessages() {
    _newMessagesSubscription = _messageService.newMessagesStream.listen(
      (message) {
        if (message.conversationId == conversation.id) {
          
          if (message.type == 'VOICE') {
            print('Message vocal reçu: ${message.id}');
          } else if (message.type == 'IMAGE') {
            print('Message image reçu: ${message.id}');
          }
          
          _addNewMessage(message);
        }
      },
      onError: (error) {
        print('Erreur stream: $error');
      },
    );
  }
  Future<void> _addNewMessage(Message message) async {  // async
  final exists = messages.any((m) => m.id == message.id);
  if (exists) {
    print('Message déjà présent: ${message.id}');
    return;
  }

  print('Ajout nouveau message: ${message.id}');
  
  Message finalMessage = message;
  
  if (message.type == 'TEXT' && 
      message.decryptedContent == null && 
      message.encryptedContent != null) {
    
    print('Message encore chiffré, déchiffrement...');
    
    try {
      final decryptedContent = await _messageService.decryptMessage(message);
      
      finalMessage = message.copyWith(
        decryptedContent: decryptedContent,
      );
      
      print('Message déchiffré: ${decryptedContent.substring(0, 20)}...');
      
    } catch (e) {
      print('Erreur déchiffrement: $e');
      // Garder le message chiffré si erreur
    }
  }

  messages.add(finalMessage);
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _scrollToBottom();
  });

  if (message.senderId != _currentUserId) {
    _messageService.markConversationAsRead(conversation.id);
  }
}

  Future<void> sendMessage() async {
    // Si images sélectionnées, envoyer images
    if (selectedImages.isNotEmpty) {
      await sendSelectedImages();
      return;
    }
    
    // Sinon envoyer texte
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    if (isSendingMessage.value) return;

    try {
      isSendingMessage.value = true;

      final recipientId = _getRecipientId();

      final sentMessage = await _messageService.sendMessage(
        conversationId: conversation.id,
        recipientUserId: recipientId,
        content: text,
        type: 'TEXT',
      );

      messageController.clear();
      _addNewMessage(sentMessage);

    } catch (e) {
      print('Erreur sendMessage: $e');
      _showError('Impossible d\'envoyer le message');
    } finally {
      isSendingMessage.value = false;
    }
  }

  void addImageToSelection(File imageFile) {
    if (selectedImages.length >= 10) {
      _showWarning('Maximum 10 images à la fois');
      return;
    }
    
    selectedImages.add(imageFile);
    print('Image ajoutée à la sélection (${selectedImages.length}/10)');
  }

  void removeImageFromSelection(int index) {
    selectedImages.removeAt(index);
    print('Image retirée de la sélection (${selectedImages.length}/10)');
  }

  Future<void> sendSelectedImages() async {
    if (selectedImages.isEmpty) return;
    if (isSendingMessage.value) return;

    try {
      isSendingMessage.value = true;
      
      final recipientId = _getRecipientId();
      final imagesToSend = List<File>.from(selectedImages);
      
      print('Envoi de ${imagesToSend.length} image(s)...');
      
      // Vider la sélection immédiatement
      selectedImages.clear();

      // Envoyer chaque image
      int successCount = 0;
      for (int i = 0; i < imagesToSend.length; i++) {
        try {
          print('Envoi image ${i + 1}/${imagesToSend.length}...');
          
          final message = await _imageService.sendImage(
            conversationId: conversation.id,
            recipientUserId: recipientId,
            imageFile: imagesToSend[i],
          );

          _addNewMessage(message);
          successCount++;
          
        } catch (e) {
          print('Erreur envoi image ${i + 1}: $e');
        }
      }

      if (successCount > 0) {
        // _showSuccess('$successCount image(s) envoyée(s)');
      } else {
        // _showError('Aucune image envoyée');
      }

    } catch (e) {
      print('Erreur sendSelectedImages: $e');
      _showError('Impossible d\'envoyer les images');
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> sendVoiceMessage(String voiceFilePath) async {
    print('Chemin fichier: $voiceFilePath');
    
    if (isSendingMessage.value) {
      print('Envoi déjà en cours, annulation');
      return;
    }

    try {
      isSendingMessage.value = true;
      
      // Vérifier le fichier existe
      final voiceFile = File(voiceFilePath);
      if (!await voiceFile.exists()) {
        throw Exception('Fichier vocal introuvable: $voiceFilePath');
      }
      
      final fileSize = await voiceFile.length();
      print('Fichier vocal trouvé: ${fileSize / 1024} KB');
      
     
      
      //  Récupérer le destinataire
      final recipientId = _getRecipientId();
      print(' Destinataire: $recipientId');
      
      //  Envoyer via le service
      print('Chiffrement et envoi en cours...');
      final message = await _voiceService.sendVoice(
        conversationId: conversation.id,
        recipientUserId: recipientId,
        voiceFile: voiceFile,
      );

      print('Message vocal envoyé: ${message.id}');
      
      //  Ajouter à la liste
      _addNewMessage(message);
      
      
      print('🎤 === FIN ENVOI MESSAGE VOCAL ===');

    } catch (e, stackTrace) {
      print('Erreur sendVoiceMessage: $e');
      print('Stack trace: $stackTrace');
      _showError('Impossible d\'envoyer le message vocal');
    } finally {
      isSendingMessage.value = false;
    }
  }

  String _getRecipientId() {
    try {
      final recipient = conversation.participants
          .firstWhere((p) => p.userId != _currentUserId);
      return recipient.userId;
    } catch (e) {
      print('Erreur récupération recipientId: $e');
      throw Exception('Impossible de trouver le destinataire');
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  
  void _showSuccess(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green[900],
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      icon: const Icon(Icons.error_outline, color: Colors.red),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
   // --- APPELS WEBRTC ---

void _listenCallSignals() {
  _callSignalsSubscription = _websocketService.messageStream.listen((data) {
    final type = data['type'] as String?;
    
    if (type == 'incoming_call') {
      
      final payload = data['data'] ?? {};
      final fromUserId = data['from_user_id']?.toString() ?? data['sender_id']?.toString() ?? "";
      final conversationId = data['conversation_id']?.toString() ?? "";
      final callType = (payload['call_type'] ?? 'AUDIO').toString().toUpperCase();
      final sdp = payload['sdp']?.toString() ?? "";
      
      print('   De: $fromUserId');
      print('   Conversation: $conversationId');
      print('   Type: $callType');
      print('   SDP présent: ${sdp.isNotEmpty}');
      
      if (fromUserId.isEmpty) {
        print('fromUserId MANQUANT');
        return;
      }
      
      if (conversationId.isEmpty) {
        print('conversationId MANQUANT');
        return;
      }
      
      if (sdp.isEmpty) {
        print('SDP MANQUANT');
        return;
      }
      
      print('Navigation vers CallsView...');
      
      Get.toNamed(AppRoutes.CALLS, arguments: {
        'conversationId': conversation.id, 
        'targetId': fromUserId,
        'isCaller': false,
        'callType': callType,
        'sdp': sdp,
      });
      
      print('Navigation effectuée');
    }
  });
}
  String get recipientId {
    try {
      return conversation.participants
          .firstWhere((p) => p.userId != _currentUserId).userId;
    } catch (e) {
      return '';
    }
  }


  void _showWarning(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.orange.withOpacity(0.1),
      colorText: Colors.orange[900],
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    _newMessagesSubscription?.cancel();
    _callSignalsSubscription?.cancel(); 
    super.onClose();
  }
}

