// lib/data/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../../core/shared/environment.dart';
import '../api/api_endpoints.dart';
import 'secure_storage_service.dart';

/// Service WebSocket pour messagerie temps réel
/// 
/// Architecture B: Réception messages en temps réel
/// - Envoi: HTTP (MessageService)
/// - Réception: WebSocket (ce service)
class WebSocketService extends GetxService {
  // ═══════════════════════════════════════════════════════════════
  // PROPRIÉTÉS
  // ═══════════════════════════════════════════════════════════════
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  bool _manualDisconnect = false;
  
  final _secureStorage = Get.find<SecureStorageService>();
  
  // État de connexion
  final isConnected = false.obs;
  final connectionError = Rx<String?>(null);
  
  // Stream des messages reçus
  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }
  
  // ═══════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════
  
  @override
  void onInit() {
    super.onInit();
    print('✅ WebSocketService initialized');
    print('   Environment: ${AppEnvironment.name}');
    print('   WS URL: ${AppEnvironment.fullWsUrl}');
  }
  
  @override
  void onClose() {
    disconnect();
    _messageController?.close();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    super.onClose();
  }
  
  // ═══════════════════════════════════════════════════════════════
  // CONNEXION
  // ═══════════════════════════════════════════════════════════════
  
  /// Connecter au WebSocket
  Future<void> connect() async {
    if (_isConnecting || isConnected.value) {
      print('⚠️ Déjà connecté ou connexion en cours');
      return;
    }
    
    try {
      _isConnecting = true;
      _manualDisconnect = false;
      
      // Récupérer le token
      final token = await _secureStorage.getAccessToken();
      if (token == null) {
        throw Exception('Pas de token d\'authentification');
      }
      
      print('🔌 Connexion WebSocket...');
      print('   URL: ${AppEnvironment.fullWsUrl}');
      
      // Créer la connexion WebSocket avec token
      final wsUrl = '${AppEnvironment.fullWsUrl}?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Écouter les messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      
      // Marquer comme connecté
      isConnected.value = true;
      connectionError.value = null;
      _reconnectAttempts = 0;
      _isConnecting = false;
      
      print('✅ WebSocket connecté');
      
      // Démarrer ping pour maintenir connexion
      _startPingTimer();
      
    } catch (e) {
      _isConnecting = false;
      isConnected.value = false;
      connectionError.value = e.toString();
      
      print('❌ Erreur connexion WebSocket: $e');
      
      // Retry automatique
      if (!_manualDisconnect) {
        _scheduleReconnect();
      }
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // DÉCONNEXION
  // ═══════════════════════════════════════════════════════════════
  
  /// Déconnecter du WebSocket
  void disconnect() {
    print('🔌 Déconnexion WebSocket...');
    
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    
    _channel?.sink.close(status.goingAway);
    _channel = null;
    
    isConnected.value = false;
    
    print('✅ WebSocket déconnecté');
  }
  
  // ═══════════════════════════════════════════════════════════════
  // ENVOI DE MESSAGES
  // ═══════════════════════════════════════════════════════════════
  
  /// Rejoindre une conversation
  void joinConversation(String conversationId) {
    if (!isConnected.value) {
      print('⚠️ WebSocket non connecté');
      return;
    }
    
    final message = {
      'action': 'join_conversation',
      'conversation_id': conversationId,
    };
    
    _send(message);
    print('📨 Rejoint conversation: $conversationId');
  }

  void sendCallSignal({
    required String targetId,
    required String conversationId,
    required String action,
    Map<String, dynamic>? extraData,
  }) {
    if (!isConnected.value) {
      print("⚠️ Signal d'appel non envoyé : WebSocket déconnecté");
      return;
    }
    
    final payload = {
      'action': 'call_signal',
      'target_id': targetId,
      'conversation_id': conversationId,
      'signal': action, 
      'data': extraData ?? {},
    };
    
    print("📤 Envoi signal WebRTC: $action vers $targetId");
    _send(payload);
  }

  
  /// Envoyer indicateur de saisie
  void sendTyping(String conversationId, bool isTyping) {
    if (!isConnected.value) return;
    
    final message = {
      'action': 'typing',
      'conversation_id': conversationId,
      'is_typing': isTyping,
    };
    
    _send(message);
  }
  
  /// Marquer messages comme lus (via WebSocket pour notification instantanée)
  void markMessagesRead(List<String> messageIds) {
    if (!isConnected.value || messageIds.isEmpty) return;
    
    final message = {
      'action': 'mark_read',
      'message_ids': messageIds,
    };
    
    _send(message);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // GESTION DES MESSAGES REÇUS
  // ═══════════════════════════════════════════════════════════════
  
void _onMessage(dynamic message) {
  try {
    final data = jsonDecode(message as String) as Map<String, dynamic>;
    final type = data['type'] as String?;
    
    print('📩 Message WebSocket reçu: $type');
    
    // Dispatcher selon le type
    switch (type) {
      // ════════════════════════════════════════════════════════
      // CONNEXION & CONVERSATION
      // ════════════════════════════════════════════════════════
      case 'connection_established':
        print('✅ Connexion WebSocket établie');
        print('   User ID: ${data['user_id']}');
        break;
        
      case 'joined_conversation':
        print('✅ Conversation rejointe: ${data['conversation_id']}');
        break;
      
      // ════════════════════════════════════════════════════════
      // MESSAGERIE
      // ════════════════════════════════════════════════════════
      case 'new_message':
        // Nouveau message reçu → Envoyer au stream
        _messageController?.add(data);
        print('📨 Nouveau message: ${data['message']?['id']}');
        break;
        
      case 'typing':
        // Indicateur de saisie
        _messageController?.add(data);
        break;
        
      case 'message_read_receipt':
        // Accusé de lecture
        _messageController?.add(data);
        print('✅ Message lu: ${data['message_id']}');
        break;
        
      case 'message_sent':
        // Confirmation envoi
        print('✅ Message envoyé: ${data['message_id']}');
        break;
      
      // ════════════════════════════════════════════════════════
      // ✅✅✅ SIGNAUX WEBRTC (AJOUT CRITIQUE) ✅✅✅
      // ════════════════════════════════════════════════════════
      case 'incoming_call':
        print('📞 Appel entrant WebRTC reçu !');
        print('   De: ${data['from_user_id']}');
        print('   Conversation: ${data['conversation_id']}');
        print('   Type: ${data['data']?['call_type']}');
        _messageController?.add(data); // ← Broadcast vers les listeners
        break;
      
      case 'call_accepted':
        print('✅ Appel accepté reçu');
        print('   SDP: ${data['data']?['sdp']?.substring(0, 50) ?? "null"}...');
        _messageController?.add(data);
        break;
      
      case 'ice_candidate':
        print('🧊 ICE Candidate reçu');
        _messageController?.add(data);
        break;
      
      case 'call_rejected':
        print('❌ Appel rejeté');
        _messageController?.add(data);
        break;
      
      case 'call_ended':
        print('📞 Appel terminé');
        _messageController?.add(data);
        break;
      
      // ════════════════════════════════════════════════════════
      // ERREURS
      // ════════════════════════════════════════════════════════
      case 'error':
        print('❌ Erreur WebSocket: ${data['error']}');
        connectionError.value = data['error'] as String?;
        break;
      
      // ════════════════════════════════════════════════════════
      // TYPE INCONNU
      // ════════════════════════════════════════════════════════
      default:
        print('⚠️ Type de message inconnu: $type');
        print('   Données complètes: $data');
        // ✅ Quand même broadcaster pour debug
        _messageController?.add(data);
    }
    
  } catch (e) {
    print('❌ Erreur parsing message WebSocket: $e');
   
  }
}
  
  void _onError(dynamic error) {
    print('❌ Erreur WebSocket: $error');
    
    isConnected.value = false;
    connectionError.value = error.toString();
    
    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }
  
  void _onDone() {
    print('🔌 WebSocket fermé');
    
    isConnected.value = false;
    _pingTimer?.cancel();
    
    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // RECONNEXION AUTOMATIQUE
  // ═══════════════════════════════════════════════════════════════
  
  void _scheduleReconnect() {
    if (_manualDisconnect) return;
    
    if (_reconnectAttempts >= ApiEndpoints.wsMaxReconnectAttempts) {
      print('❌ Nombre max de tentatives de reconnexion atteint');
      connectionError.value = 'Impossible de se reconnecter au serveur';
      return;
    }
    
    _reconnectAttempts++;
    
    print('🔄 Tentative de reconnexion $_reconnectAttempts/${ApiEndpoints.wsMaxReconnectAttempts}...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(ApiEndpoints.wsReconnectDelay, () {
      connect();
    });
  }


  
  // ═══════════════════════════════════════════════════════════════
  // PING POUR MAINTENIR CONNEXION
  // ═══════════════════════════════════════════════════════════════
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(ApiEndpoints.wsPingInterval, (timer) {
      if (isConnected.value) {
        _send({'action': 'ping'});
      }
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // ENVOI BRUT
  // ═══════════════════════════════════════════════════════════════
  
  void _send(Map<String, dynamic> data) {
    try {
      final json = jsonEncode(data);
      _channel?.sink.add(json);
    } catch (e) {
      print('❌ Erreur envoi message WebSocket: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Reconnecter manuellement
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }
}

