import 'dart:async';
import 'package:chat_mobile/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../data/services/websocket_service.dart';
import '../../../data/services/webrtc_service.dart';

class CallsController extends GetxController {
  RTCPeerConnection? peerConnection;
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final WebRTCService _webRTCService = WebRTCService();

  MediaStream? localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  String conversationId = "";
  String targetUserId = "";
  bool isCaller = false;
  String callType = "VIDEO";
  String? pendingRemoteSdp;
  
  final List<RTCIceCandidate> _iceCandidatesQueue = [];
  StreamSubscription? _wsSubscription;
  Timer? _callTimer;
  int _secondsElapsed = 0;

  final isVideoEnabled = true.obs;
  final isMicEnabled = true.obs;
  final isCallActive = false.obs;
  final isCallConnected = false.obs;
  final isRemoteVideoAvailable = false.obs;
  final callStatus = "Initialisation...".obs;
  final isRinging = false.obs;
  final callDuration = "".obs;
  final audioLevel = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    
    try {
      final args = Get.arguments as Map<String, dynamic>;
      conversationId = args['conversationId'] as String;
      targetUserId = args['targetId'] as String;
      callType = (args['callType'] as String).toUpperCase();
      isCaller = args['isCaller'] as bool;
      
      _initRenderers().then((_) {
        _setupWebSocketListener();
        
        if (isCaller) {
          callStatus.value = "Appel en cours...";
          initCall(true);
        } else {
          final remoteSdp = args['sdp'] as String?;
          if (remoteSdp != null) {
            pendingRemoteSdp = remoteSdp;
          }
          isRinging.value = true;
          callStatus.value = "Appel entrant...";
        }
      });
      
    } catch (e) {
      Get.back();
      // Get.snackbar('Erreur', 'Impossible d\'initialiser l\'appel');
    }
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void _setupWebSocketListener() {
    _wsSubscription = _wsService.messageStream.listen((data) {
      final String type = data['type'] ?? '';
      final payload = data['data'] ?? {};

      switch (type) {
        case 'call_accepted':
          final sdp = payload['sdp'];
          if (sdp != null && sdp.isNotEmpty) {
            callStatus.value = "Connexion...";
            _handleAnswer(sdp);
          }
          break;
          
        case 'ice_candidate':
          _handleIceCandidate(payload);
          break;
          
        case 'call_rejected':
          _cleanupCall();
          Get.back();
          // Get.snackbar('Appel rejeté', 'L\'appelé a décliné');
          break;
          
        case 'call_ended':
          _cleanupCall();
          Get.back();
          break;
      }
    });
  }

  Future<void> initCall(bool isCaller) async {
    try {
      isRinging.value = false;
      isCallActive.value = true;

      bool wantVideo = (callType == "VIDEO");
      isVideoEnabled.value = wantVideo;

      await Helper.setSpeakerphoneOn(true);

      localStream = await _webRTCService.getUserMedia(hasVideo: wantVideo);
      
      if (wantVideo) {
        localRenderer.srcObject = localStream;
      }

      peerConnection = await _webRTCService.createPeerConnectionInstance(
        localStream: localStream,
        onRemoteStream: (stream) {
          remoteRenderer.srcObject = stream;
          
          for (var track in stream.getAudioTracks()) {
            track.enabled = true;
          }
          
          isRemoteVideoAvailable.value = stream.getVideoTracks().isNotEmpty;
          isCallConnected.value = true;
          callStatus.value = "Connecté";
          _startTimer();
        },
        onIceCandidate: (candidate) {
          _sendSignaling('ice_candidate', {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
        },
      );

      if (isCaller) {
        final offer = await _webRTCService.createOffer(
          peerConnection!, 
          hasVideo: wantVideo,
        );
        
        _sendSignaling('call_offer', {
          'sdp': offer.sdp,
          'call_type': callType,
        });
      } else {
        final String? sdpToUse = Get.arguments['sdp'] ?? pendingRemoteSdp;
        
        if (sdpToUse != null && sdpToUse.isNotEmpty) {
          await peerConnection!.setRemoteDescription(
            RTCSessionDescription(sdpToUse, 'offer')
          );
          
          final answer = await _webRTCService.createAnswer(peerConnection!);
          
          _sendSignaling('call_accepted', {'sdp': answer.sdp});
          
          _processQueuedCandidates();
        } else {
          throw Exception('SDP distant manquant');
        }
      }
      
    } catch (e) {
      _cleanupCall();
      Get.back();
      Get.snackbar('Erreur', 'La connexion a échoué');
    }
  }

  void _handleAnswer(String sdp) async {
    try {
      if (peerConnection != null) {
        await peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, 'answer')
        );
        
        _processQueuedCandidates();
      }
    } catch (e) {
      print('Erreur _handleAnswer: $e');
    }
  }

  void _handleIceCandidate(Map<String, dynamic> payload) async {
    try {
      final candidate = RTCIceCandidate(
        payload['candidate'],
        payload['sdpMid'],
        payload['sdpMLineIndex'],
      );
      
      if (peerConnection != null && 
          (await peerConnection!.getRemoteDescription()) != null) {
        await peerConnection!.addCandidate(candidate);
      } else {
        _iceCandidatesQueue.add(candidate);
      }
    } catch (e) {
      print('Erreur ICE: $e');
    }
  }

  void _processQueuedCandidates() async {
    if (_iceCandidatesQueue.isNotEmpty && peerConnection != null) {
      for (var cand in _iceCandidatesQueue) {
        try {
          await peerConnection!.addCandidate(cand);
        } catch (e) {
          print(' Erreur ajout candidate: $e');
        }
      }
      _iceCandidatesQueue.clear();
    }
  }

  void _sendSignaling(String type, Map<String, dynamic> data) {
    _wsService.sendCallSignal(
      targetId: targetUserId,
      conversationId: conversationId,
      action: type,
      extraData: data,
    );
  }

  void _startTimer() {
    _callTimer?.cancel();
    _secondsElapsed = 0;
    
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      int minutes = _secondsElapsed ~/ 60;
      int seconds = _secondsElapsed % 60;
      callDuration.value = 
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    });
  }

  Future<void> acceptCall() async {
    await initCall(false);
  }

  void rejectCall() {
    _sendSignaling('call_rejected', {});
    _cleanupCall();
    Get.back();
  }

  void endCall() {
    _sendSignaling('call_ended', {});
    _cleanupCall();
    Get.back();
  }

  void toggleMic() {
    if (localStream != null) {
      isMicEnabled.value = !isMicEnabled.value;
      
      for (var track in localStream!.getAudioTracks()) {
        track.enabled = isMicEnabled.value;
      }
    }
  }

  Future<void> switchCamera() async {
    if (localStream != null && isVideoEnabled.value) {
      try {
        final videoTrack = localStream!.getVideoTracks().first;
        await Helper.switchCamera(videoTrack);
      } catch (e) {
        print("Erreur switchCamera: $e");
      }
    }
  }

    void _startAudioLevelMonitoring() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!isCallActive.value || !isCallConnected.value) {
        timer.cancel();
        return;
      }
      
      audioLevel.value = 0.3 + (0.7 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
    });
  }

  Future<void> _cleanupCall() async {
    try {
      _callTimer?.cancel();
      
      localStream?.getTracks().forEach((t) => t.stop());
      await peerConnection?.close();
      peerConnection = null;
      
      isCallActive.value = false;
      isCallConnected.value = false;
      
    } catch (e) {
      print('Erreur cleanup: $e');
    }
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    _cleanupCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    
    super.onClose();
  }
}





