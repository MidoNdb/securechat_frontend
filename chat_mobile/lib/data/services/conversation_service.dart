// lib/data/services/conversation_service.dart

import 'package:get/get.dart';
import '../api/api_endpoints.dart';
import '../api/dio_client.dart';
import '../models/conversation.dart';

/// Service de gestion des conversations
class ConversationService extends GetxService {
  final DioClient _dioClient = Get.find<DioClient>();
  
  /// Récupérer toutes les conversations
  Future<List<Conversation>> getConversations() async {
    try {
      print('📥 Récupération conversations...');
      
      final response = await _dioClient.privateDio.get(ApiEndpoints.conversations);
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final conversations = data
            .map((json) => Conversation.fromJson(json))
            .toList();
        
        print('✅ ${conversations.length} conversations récupérées');
        
        return conversations;
      } else {
        throw Exception('Erreur récupération conversations: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Erreur getConversations: $e');
      rethrow;
    }
  }
  
  /// Récupérer une conversation par ID
  Future<Conversation> getConversation(String id) async {
    try {
      final response = await _dioClient.privateDio.get(
        ApiEndpoints.conversationDetail(id),
      );
      
      if (response.statusCode == 200) {
        return Conversation.fromJson(response.data['data']);
      } else {
        throw Exception('Erreur récupération conversation: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Erreur getConversation: $e');
      rethrow;
    }
  }
  
  /// Créer une conversation
  Future<Conversation> createConversation({
    required String participantId,
    String type = 'DIRECT',
  }) async {
    try {
      print('📝 Création conversation avec: $participantId');
      
      final response = await _dioClient.privateDio.post(
        ApiEndpoints.createConversation,
        data: {
          'type': type,
          'participant_ids': [participantId],
        },
      );
      
      if (response.statusCode == 201) {
        final conversation = Conversation.fromJson(response.data['data']);
        print('✅ Conversation créée: ${conversation.id}');
        return conversation;
      } else {
        throw Exception('Erreur création conversation: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Erreur createConversation: $e');
      rethrow;
    }
  }
}