
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';
import '../../../data/services/message_service.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/services/secure_storage_service.dart';
import '../views/chat_view.dart';

class MessagesController extends GetxController {
  final MessageService _messageService = Get.find<MessageService>();
  final WebSocketService _webSocketService = Get.find<WebSocketService>();
  final SecureStorageService _storage = Get.find<SecureStorageService>();

  final conversations = <Conversation>[].obs;
  final filteredConversations = <Conversation>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedTabIndex = 0.obs;
  final totalUnreadCount = 0.obs;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  @override
  void onInit() {
    super.onInit();
    initializeMessages();
  }

  Future<void> initializeMessages() async {
    await _initCurrentUser();
    await loadConversations();
    _webSocketService.connect();
    listenToNewMessages();
  }

  Future<void> _initCurrentUser() async {
    try {
      final userId = await _storage.getUserId();
      
      if (userId != null) {
        _currentUserId = userId;
        print('Current user ID: $_currentUserId');
      } else {
        print('No user ID in storage');
        await _loadUserIdFromAPI();
      }
    } catch (e) {
      print('_initCurrentUser: $e');
      await _loadUserIdFromAPI();
    }
  }

  Future<void> _loadUserIdFromAPI() async {
    try {
      final data = await _messageService.getCurrentUser();
      
      if (data != null) {
        final userIdValue = data['user_id'] ?? data['id'];
        
        if (userIdValue != null) {
          _currentUserId = userIdValue.toString();
          print(' Current user ID from API: $_currentUserId');
          
          await _storage.saveUserId(_currentUserId!);
        }
      }
    } catch (e) {
      print('_loadUserIdFromAPI: $e');
    }
  }

  Future<void> loadConversations() async {
    try {
      isLoading.value = true;
      
      final result = await _messageService.getConversations();
      
      if (result != null && result.isNotEmpty) {
        
        for (var conversation in result) {
          if (conversation.lastMessage != null) {
            try {
              final msg = conversation.lastMessage!;
              
              String decryptedText;
              
              if (msg.type == 'IMAGE') {
                decryptedText = 'Photo';
              } else if (msg.type == 'VIDEO') {
                decryptedText = 'Vidéo';
              } else if (msg.type == 'VOICE') {
                decryptedText = 'Message vocal';
              } else if (msg.type == 'FILE') {
                decryptedText = 'Fichier';
              } 
              else {
                if (msg.senderId == _currentUserId) {
                  print('Message de nous-même, recherche dans le cache...');
                  
                  final cached = await _storage.getMessagePlaintext(msg.id);
                  
                  if (cached != null) {
                    decryptedText = cached;
                    print('Trouvé dans le cache: "$decryptedText"');
                  } else {
                    print('Cache manquant pour notre message ${msg.id}');
                    
                    if (msg.nonce == null || msg.authTag == null || msg.signature == null) {
                      decryptedText = '[Message]';
                    } else {
                      try {
                        decryptedText = await _messageService.decryptMessage(msg);
                      } catch (e) {
                        print('Déchiffrement échoué: $e');
                        decryptedText = '[Message illisible]';
                      }
                    }
                  }
                } 
                else {
                  print('Message reçu, déchiffrement...');
                  
                  // Vérifier si le message a les champs E2EE
                  if (msg.nonce == null || msg.authTag == null || msg.signature == null) {
                    print('Champs E2EE manquants');
                    decryptedText = '[Message]';
                  } else {
                    try {
                      decryptedText = await _messageService.decryptMessage(msg);
                      print('Déchiffré: "$decryptedText"');
                    } catch (e) {
                      print('Erreur déchiffrement: $e');
                      
                      // Gérer les différents types d'erreurs
                      if (e.toString().contains('Signature invalide')) {
                        decryptedText = '[Message illisible]';
                      } else if (e.toString().contains('E2EE fields missing')) {
                        decryptedText = '[Message]';
                      } else if (e.toString().contains('SecretBoxAuthenticationError')) {
                        decryptedText = '[Message illisible]';
                      } else {
                        decryptedText = '[Erreur]';
                      }
                    }
                  }
                }
              }
              
              final index = result.indexOf(conversation);
              result[index] = conversation.copyWith(
                lastMessage: msg.copyWith(
                  decryptedContent: decryptedText,
                ),
              );
              
            } catch (e) {
              print('Erreur traitement dernier message: $e');
              
              final index = result.indexOf(conversation);
              result[index] = conversation.copyWith(
                lastMessage: conversation.lastMessage!.copyWith(
                  decryptedContent: '[Erreur]',
                ),
              );
            }
          }
        }
        
        // Trie par date (plus récent en premier)
        result.sort((a, b) {
          final aDate = a.lastMessageAt ?? a.createdAt;
          final bDate = b.lastMessageAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
        
        conversations.assignAll(result);
        
        print('Loaded ${conversations.length} conversations');
        print('Conversations: ${conversations.map((c) => '${c.name} (${c.id})').toList()}');
        
        _applyCurrentFilter();
        calculateUnreadCount();
      } else {
        print('No conversations loaded');
        conversations.clear();
        filteredConversations.clear();
      }
    } catch (e) {
      print('loadConversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void openConversation(Conversation conversation) {
    print('Opening conversation: ${conversation.name} (${conversation.id})');
    
    Get.to(
      () => const ChatView(),
      arguments: {
        'conversation': conversation,
      },
      preventDuplicates: true,
    )?.then((_) {
      print('Returned from ChatView - Reloading conversations');
      loadConversations();
    });
  }

  Future<void> openOrCreateConversation({
    required String contactUserId,
    required String contactName,
  }) async {
    try {
      print('Looking for conversation with user: $contactUserId');
      print('   Contact name: $contactName');
      
      var existing = conversations.firstWhereOrNull((conv) {
        if (conv.isGroup) return false;
        return conv.participants.any((p) => p.userId == contactUserId);
      });

      if (existing == null) {
        print('Not found locally, reloading conversations...');
        await loadConversations();
        
        existing = conversations.firstWhereOrNull((conv) {
          if (conv.isGroup) return false;
          return conv.participants.any((p) => p.userId == contactUserId);
        });
      }

      if (existing != null) {
        print('Found existing conversation: ${existing.name}');
        
        Get.off(
          () => const ChatView(),
          arguments: {
            'conversation': existing,
          },
        )?.then((_) {
          print('Returned from ChatView - Reloading conversations');
          loadConversations();
        });
        return;
      }

      print('Creating new conversation with $contactUserId...');
      
      final newConversation = await _messageService.createDirectConversation(
        contactUserId,
      );

      if (newConversation != null) {
        print('Conversation created: ${newConversation.name} (${newConversation.id})');
        
        await loadConversations();
        
        Get.off(
          () => const ChatView(),
          arguments: {
            'conversation': newConversation,
          },
        )?.then((_) {
          print('Returned from ChatView - Reloading conversations');
          loadConversations();
        });
      } else {
        throw Exception('Failed to create conversation');
      }
      
    } catch (e) {
      print('openOrCreateConversation: $e');
      
      Get.snackbar(
        '',
        'Impossible de créer la conversation',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void listenToNewMessages() {
    _webSocketService.messageStream.listen((data) {
      try {
        if (data['type'] == 'new_message' && data['message'] != null) {
          final messageData = data['message'] as Map<String, dynamic>;
          final message = Message.fromJson(messageData);
          
          updateConversationWithNewMessage(message);
          calculateUnreadCount();
        }
      } catch (e) {
        print('Erreur parsing message WebSocket: $e');
      }
    });
  }

  Future<void> updateConversationWithNewMessage(Message message) async {
    final index = conversations.indexWhere(
      (conv) => conv.id == message.conversationId,
    );

    if (index != -1) {
      final conv = conversations[index];
      
      // Afficher le bon texte selon le type
      String displayText;
      if (message.type == 'IMAGE') {
        displayText = 'Photo';
      } else if (message.type == 'VIDEO') {
        displayText = 'Vidéo';
      } else if (message.type == 'VOICE') {
        displayText = 'vocal';
      } else if (message.type == 'FILE') {
        displayText = '';
      } else {
        // Pour les messages texte, essayer de déchiffrer
        try {
          displayText = await _messageService.decryptMessage(message);
        } catch (e) {
          displayText = '[Nouveau message]';
        }
      }
      
      final updatedConv = conv.copyWith(
        lastMessage: message.copyWith(decryptedContent: displayText),
        lastMessageAt: message.timestamp,
        unreadCount: conv.unreadCount + 1,
      );

      conversations.removeAt(index);
      conversations.insert(0, updatedConv);
      
      _applyCurrentFilter();
    } else {
      await loadConversations();
    }
  }

  void searchConversations(String query) {
    searchQuery.value = query;
    _applyCurrentFilter();
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
    _applyCurrentFilter();
  }

  void _applyCurrentFilter() {
    print(' Applying filter - currentUserId: $_currentUserId');
    print('Total conversations: ${conversations.length}');
    
    if (searchQuery.isNotEmpty) {
      filteredConversations.assignAll(
        conversations.where((c) {
          final name = (c.name ?? 'Conversation').toLowerCase();
          final lastMsg = c.lastMessage?.decryptedContent?.toLowerCase() ?? '';
          final query = searchQuery.value.toLowerCase();
          return name.contains(query) || lastMsg.contains(query);
        }).toList(),
      );
      print(' Filtered by search: ${filteredConversations.length} results');
      return;
    }

    switch (selectedTabIndex.value) {
      case 0: // Discussions (1-to-1)
        filteredConversations.assignAll(
          conversations.where((c) => !c.isGroup).toList()
        );
        break;
      case 1: // Groupes
        filteredConversations.assignAll(
          conversations.where((c) => c.isGroup).toList()
        );
        break;
      default:
        filteredConversations.assignAll(conversations);
    }
    
    print(' Filtered conversations: ${filteredConversations.length}');
  }

  void calculateUnreadCount() {
    totalUnreadCount.value = conversations.fold(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  Future<void> refresh() async {
    await loadConversations();
  }
}

