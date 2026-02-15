// lib/data/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../../core/shared/environment.dart';
import '../api/api_endpoints.dart';
import 'secure_storage_service.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  bool _manualDisconnect = false;

  final _secureStorage = Get.find<SecureStorageService>();

  final isConnected = false.obs;
  final connectionError = Rx<String?>(null);

  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  @override
  void onClose() {
    disconnect();
    _messageController?.close();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    super.onClose();
  }

  Future<void> connect() async {
    if (_isConnecting || isConnected.value) return;

    try {
      _isConnecting = true;
      _manualDisconnect = false;

      final token = await _secureStorage.getAccessToken();
      if (token == null) throw Exception('Pas de token');

      final wsUrl = '${AppEnvironment.fullWsUrl}?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      isConnected.value = true;
      connectionError.value = null;
      _reconnectAttempts = 0;
      _isConnecting = false;
      _startPingTimer();
    } catch (e) {
      _isConnecting = false;
      isConnected.value = false;
      connectionError.value = e.toString();

      if (!_manualDisconnect) _scheduleReconnect();
    }
  }

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    _channel?.sink.close(status.goingAway);
    _channel = null;

    isConnected.value = false;
  }

  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  void joinConversation(String conversationId) {
    if (!isConnected.value) return;
    _send({'action': 'join_conversation', 'conversation_id': conversationId});
  }

  void sendCallSignal({
    required String targetId,
    required String conversationId,
    required String action,
    Map<String, dynamic>? extraData,
  }) {
    if (!isConnected.value) return;
    _send({
      'action': 'call_signal',
      'target_id': targetId,
      'conversation_id': conversationId,
      'signal': action,
      'data': extraData ?? {},
    });
  }

  void sendTyping(String conversationId, bool isTyping) {
    if (!isConnected.value) return;
    _send({
      'action': 'typing',
      'conversation_id': conversationId,
      'is_typing': isTyping,
    });
  }

  void markMessagesRead(List<String> messageIds) {
    if (!isConnected.value || messageIds.isEmpty) return;
    _send({'action': 'mark_read', 'message_ids': messageIds});
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        // Messages qui ne nécessitent pas de broadcast
        case 'connection_established':
        case 'joined_conversation':
        case 'message_sent':
          break;

        // Erreurs
        case 'error':
          connectionError.value = data['error'] as String?;
          break;

        // Tout le reste → broadcast vers les listeners
        case 'new_message':
        case 'typing':
        case 'message_read_receipt':
        case 'incoming_call':
        case 'call_accepted':
        case 'ice_candidate':
        case 'call_rejected':
        case 'call_ended':
        default:
          _messageController?.add(data);
      }
    } catch (_) {}
  }

  void _onError(dynamic error) {
    isConnected.value = false;
    connectionError.value = error.toString();
    if (!_manualDisconnect) _scheduleReconnect();
  }

  void _onDone() {
    isConnected.value = false;
    _pingTimer?.cancel();
    if (!_manualDisconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;
    if (_reconnectAttempts >= ApiEndpoints.wsMaxReconnectAttempts) {
      connectionError.value = 'Impossible de se reconnecter au serveur';
      return;
    }

    _reconnectAttempts++;

    // Exponential backoff : 3s, 6s, 12s, 24s, 48s
    final delay = ApiEndpoints.wsReconnectDelay *
        pow(2, _reconnectAttempts - 1).toInt();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect());
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(ApiEndpoints.wsPingInterval, (_) {
      if (isConnected.value) _send({'action': 'ping'});
    });
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {}
  }
}