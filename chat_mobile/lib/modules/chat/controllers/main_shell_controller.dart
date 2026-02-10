import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/services/secure_storage_service.dart';

class MainShellController extends GetxController {
  final currentIndex = 0.obs;
  
  // Services
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final SecureStorageService _storage = Get.find<SecureStorageService>();

  // ✅ NavigatorKey pour chaque onglet
  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(),  // Messages (0)
    GlobalKey<NavigatorState>(),  // Contacts (1)
    GlobalKey<NavigatorState>(),  // Calls (2)
    GlobalKey<NavigatorState>(),  // Profile (3)
  ];

  @override
  void onInit() {
    super.onInit();
    print("🏠 MainShellController initialized");
    // ✅ Écouter les appels entrants
    _listenForIncomingCalls();
  }

  /// Écoute les messages WebSocket pour détecter une offre d'appel
  void _listenForIncomingCalls() {
    print("👂 MainShellController: Listening for incoming calls");
    
    _wsService.messageStream.listen((data) {
      final type = data['type'];
      print("📨 MainShellController received: $type");
      
      // Si on reçoit une offre d'appel
      if (type == 'call_offer') {
        print("🔔🔔🔔 Appel entrant détecté!");
        print("📞 Data: $data");
        
        _handleIncomingCall(data);
      }
    });
  }

  /// Gérer l'appel entrant
  Future<void> _handleIncomingCall(Map<String, dynamic> data) async {
    try {
      // Récupérer les infos
      final senderId = data['sender_id'] ?? data['data']?['sender_id'];
      final payload = data['data'] ?? data;
      final sdp = payload['sdp'];
      final callType = payload['call_type'] ?? 'video'; // 'video' ou 'audio'
      
      print("📞 Sender ID: $senderId");
      print("📞 Call type: $callType");
      print("📞 SDP: ${sdp != null ? 'YES' : 'NO'}");
      
      if (senderId == null || sdp == null) {
        print("❌ Missing sender_id or sdp");
        return;
      }

      // Récupérer l'ID utilisateur actuel
      final currentUserId = await _storage.getUserId();
      if (currentUserId == null) {
        print("❌ Current user ID is null");
        return;
      }

      print("📞 Current user: $currentUserId");
      
      // Générer un ID d'appel
      final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      
      // ✅ Arguments COMPLETS pour CallsController
      final arguments = {
        'callId': callId,
        'conversationId': '', // Peut être vide pour l'instant
        'callerId': senderId,
        'receiverId': currentUserId,
        'targetId': senderId,
        'callType': callType, // ✅ 'video' ou 'audio', pas 'hasVideo'
        'isCaller': false,
        'remoteSdp': sdp, // ✅ SDP de l'offre
      };
      
      print("📦 Navigating to /calls with arguments:");
      print("   $arguments");
      
      // ✅ Navigation vers l'écran d'appel
      Get.toNamed('/calls', arguments: arguments);
      
    } catch (e, stackTrace) {
      print("❌ Error handling incoming call: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // ✅ Changer d'onglet
  void changePage(int index) {
    if (currentIndex.value == index) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      currentIndex.value = index;
    }
  }

  // ✅ Raccourcis navigation
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





// // lib/modules/main/controllers/main_shell_controller.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class MainShellController extends GetxController {
//   final currentIndex = 0.obs;
  
//   // ✅ NavigatorKey pour chaque onglet
//   final List<GlobalKey<NavigatorState>> navigatorKeys = [
//     GlobalKey<NavigatorState>(),  // Messages (0)
//     GlobalKey<NavigatorState>(),  // Contacts (1)
//     GlobalKey<NavigatorState>(),  // Calls (2)
//     GlobalKey<NavigatorState>(),  // Profile (3)
//   ];

//   // ✅ Changer d'onglet
//   void changePage(int index) {
//     if (currentIndex.value == index) {
//       // Si on reclique sur le même onglet, retour à la racine
//       navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
//     } else {
//       currentIndex.value = index;
//     }
//   }

//   // ✅ Raccourcis navigation
//   void goToMessages() => changePage(0);
//   void goToContacts() => changePage(1);
//   void goToCalls() => changePage(2);
//   void goToProfile() => changePage(3);
// }

