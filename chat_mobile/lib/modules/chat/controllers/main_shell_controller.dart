import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/services/secure_storage_service.dart';

class MainShellController extends GetxController {
  final currentIndex = 0.obs;
  
  // Services
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final SecureStorageService _storage = Get.find<SecureStorageService>();

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(),  // Messages (0)
    GlobalKey<NavigatorState>(),  // Contacts (1)
    GlobalKey<NavigatorState>(),  // Calls (2)
    GlobalKey<NavigatorState>(),  // Profile (3)
  ];

  @override
  void onInit() {
    super.onInit();
    print("MainShellController initialized");
    _listenForIncomingCalls();
  }

 
void _listenForIncomingCalls() {
  _wsService.messageStream.listen((data) {
    final type = data['type'] as String?;
    
    if (type == 'incoming_call') {
      print("Appel entrant WebRTC reçu !");
      
      print("   De: ${data['from_user_id']}");
      print("   Conversation: ${data['conversation_id']}");
      print("   Type: ${data['data']?['call_type']}");
      
      _handleIncomingCall(data);
    }
  });
}

  Future<void> _handleIncomingCall(Map<String, dynamic> data) async {
  try {
    print("APPEL ENTRANT (MainShellController)");
    
    // Extraire les données
    final payload = data['data'] ?? {};
    final senderId = data['from_user_id']?.toString() ?? 
                     data['sender_id']?.toString() ?? 
                     payload['sender_id']?.toString() ?? '';
    
    final conversationId = data['conversation_id']?.toString() ?? '';
    final sdp = payload['sdp']?.toString() ?? '';
    final callType = (payload['call_type'] ?? 'AUDIO').toString().toUpperCase();
    
    print("   De: $senderId");
    print("   Conversation: $conversationId");
    print("   Type: $callType");
    print("   SDP présent: ${sdp.isNotEmpty}");
    
    // Validation
    if (senderId.isEmpty) {
      print("senderId manquant");
      return;
    }
    
    if (conversationId.isEmpty) {
      print("conversationId manquant");
      return;
    }
    
    if (sdp.isEmpty) {
      print("SDP manquant");
      return;
    }
    
    // Récupérer l'ID utilisateur actuel
    final currentUserId = await _storage.getUserId();
    if (currentUserId == null) {
      print("Current user ID is null");
      return;
    }
    
    print("User ID retrieved: $currentUserId");
    
    // Arguments pour CallsView
    final arguments = {
      'conversationId': conversationId,  
      'targetId': senderId,
      'isCaller': false,
      'callType': callType,
      'sdp': sdp,
    };
    
    print("Navigation vers /calls avec arguments:");
    arguments.forEach((key, value) {
      print("   $key: ${value.toString().length > 50 ? '${value.toString().substring(0, 50)}...' : value}");
    });
    
    // Navigation
    Get.toNamed('/calls', arguments: arguments);
    
    print("Navigation effectuée");
    
  } catch (e, stackTrace) {
    print("Erreur _handleIncomingCall: $e");
    print("Stack trace: $stackTrace");
  }
}
  void changePage(int index) {
    if (currentIndex.value == index) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      currentIndex.value = index;
    }
  }

  void goToMessages() => changePage(0);
  void goToContacts() => changePage(1);
  void goToCalls() => changePage(2);
  void goToProfile() => changePage(3);

  // Gérer le bouton retour Android
  Future<bool> onWillPop() async {
    final currentNavigator = navigatorKeys[currentIndex.value].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true; 
  }

}

