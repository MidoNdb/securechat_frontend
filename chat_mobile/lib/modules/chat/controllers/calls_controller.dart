import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide navigator;
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

  final isVideoEnabled = true.obs;
  final isMicEnabled = true.obs;
  final isCallActive = false.obs;
  final isRemoteVideoAvailable = false.obs;
  final callStatus = "Initialisation...".obs;
  final isRinging = false.obs;

  String targetUserId = "";
  String? pendingRemoteSdp;
  String? currentConversationId;
  String callType = "VIDEO"; // Par défaut
  
  final List<RTCIceCandidate> _iceCandidatesQueue = [];
  StreamSubscription? _wsSubscription;

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
    _setupWebSocketListener();
    _loadArguments();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }
void _loadArguments() {
  if (Get.arguments != null) {
    // On utilise les clés définies dans MainShellController
    targetUserId = Get.arguments['targetId']?.toString() ?? "";
    currentConversationId = Get.arguments['conversationId']?.toString();
    
    // Harmonisation du type d'appel
    callType = Get.arguments['callType']?.toString().toUpperCase() ?? "VIDEO";
    
    if (Get.arguments['isCaller'] == true) {
      initCall(true);
    } else {
      // ✅ MODIFICATION : Utiliser 'remoteSdp' au lieu de 'sdp'
      pendingRemoteSdp = Get.arguments['remoteSdp']; 
      isRinging.value = true;
      callStatus.value = "Appel entrant...";
      
      print("📥 Appel entrant de: $targetUserId avec SDP: ${pendingRemoteSdp != null}");
    }
  }
}
  // void _loadArguments() {
  //   if (Get.arguments != null) {
  //     targetUserId = Get.arguments['targetId']?.toString() ?? "";
  //     currentConversationId = Get.arguments['conversationId']?.toString();
  //     // On récupère le type d'appel depuis les arguments (AUDIO ou VIDEO)
  //     callType = Get.arguments['callType']?.toString().toUpperCase() ?? "VIDEO";
      
  //     if (Get.arguments['isCaller'] == true) {
  //       initCall(true);
  //     } else {
  //       pendingRemoteSdp = Get.arguments['sdp'];
  //       isRinging.value = true;
  //       callStatus.value = "Appel entrant...";
  //     }
  //   }
  // }
void _setupWebSocketListener() {
  _wsSubscription = _wsService.messageStream.listen((data) {
    final String type = data['type'] ?? '';
    final payload = data['data'] ?? {};

    switch (type) {
      // On ignore 'incoming_call' ici car MainShell l'a déjà traité
      case 'call_accepted':
        _handleAnswer(payload['sdp']);
        break;
      case 'ice_candidate':
        _handleIceCandidate(payload);
        break;
      case 'call_rejected':
      case 'call_ended':
        _cleanupCall();
        if (Get.isDialogOpen ?? false) Get.back();
        Get.back();
        break;
    }
  });
}
// void _setupWebSocketListener() {
//   _wsSubscription = _wsService.messageStream.listen((data) {
//     final String type = data['type'] ?? '';
//     final payload = data['data'] ?? {};

//     print('📩 Signal WebRTC reçu: $type'); // ← DEBUG

//     switch (type) {
//       // ✅ AJOUT CRITIQUE : Gérer l'appel entrant
//       case 'incoming_call':
//         print('📞 Appel entrant détecté !');
//         _handleIncomingCall(payload);
//         break;
        
//       case 'call_accepted':
//         _handleAnswer(payload['sdp']);
//         break;
        
//       case 'ice_candidate':
//         _handleIceCandidate(payload);
//         break;
        
//       case 'call_rejected':
//       case 'call_ended':
//         _cleanupCall();
//         if (Get.currentRoute.contains('CALLS')) Get.back();
//         break;
//     }
//   });
// }

// ✅ NOUVELLE MÉTHODE : Gérer l'appel entrant
void _handleIncomingCall(Map<String, dynamic> payload) {
  print('📞 === APPEL ENTRANT ===');
  print('   SDP: ${payload['sdp']?.substring(0, 50) ?? "null"}...');
  print('   Call Type: ${payload['call_type']}');
  
  // Stocker le SDP distant
  pendingRemoteSdp = payload['sdp'];
  
  // Définir le type d'appel (AUDIO ou VIDEO)
  callType = (payload['call_type'] ?? 'VIDEO').toString().toUpperCase();
  
  // Activer le mode sonnerie
  isRinging.value = true;
  callStatus.value = "Appel entrant...";
  
  print('✅ Appel entrant configuré');
}

  // --- LOGIQUE CORE WEBRTC ---
  Future<void> initCall(bool isCaller) async {
  try {
    // 1. RÉCUPÉRATION ET NORMALISATION DES ARGUMENTS
    // On vérifie si les arguments existent, sinon on utilise les valeurs par défaut
    final args = Get.arguments ?? {};
    
    // On récupère le type d'appel (VIDEO ou AUDIO)
    final String rawType = (args['callType'] ?? callType).toString().toUpperCase();
    callType = rawType;
    
    // Déterminer si on doit activer la caméra
    bool wantVideo = (callType == "VIDEO"); 
    isVideoEnabled.value = wantVideo;

    print("📞 === INITIALISATION APPEL ===");
    print("   Type: $callType | Vidéo: $wantVideo | Est l'appelant: $isCaller");

    // 2. CONFIGURATION AUDIO
    // Active le haut-parleur automatiquement pour la vidéo, sinon reste sur l'écouteur
    await Helper.setSpeakerphoneOn(wantVideo);
    
    isRinging.value = false;
    isCallActive.value = true;
    callStatus.value = isCaller ? "Appel en cours..." : "Connexion...";

    // 3. RÉCUPÉRATION DU STREAM LOCAL (Micro + Caméra si besoin)
    localStream = await _webRTCService.getUserMedia(hasVideo: wantVideo);
    
    // Attacher le flux à l'aperçu local
    if (wantVideo) {
      localRenderer.srcObject = localStream;
      print("✅ Stream local attaché au renderer vidéo");
    } else {
      localRenderer.srcObject = null;
      print("✅ Mode audio uniquement (pas de caméra)");
    }

    // 4. CRÉATION DE LA PEERCONNECTION
    peerConnection = await _webRTCService.createPeerConnectionInstance(
      localStream: localStream,
      onRemoteStream: (stream) {
        print("📥 Flux distant reçu !");
        
        // Attacher le flux distant au renderer
        remoteRenderer.srcObject = stream;
        
        // Activer les pistes audio distantes pour entendre l'interlocuteur
        for (var track in stream.getAudioTracks()) {
          track.enabled = true;
          print("🔊 Piste audio distante activée: ${track.id}");
        }
        
        // Afficher la vidéo distante si c'est un appel vidéo
        isRemoteVideoAvailable.value = wantVideo;
        print("✅ Stream distant configuré (Audio: ${stream.getAudioTracks().length})");
      },
      onIceCandidate: (candidate) {
        print("🧊 ICE Candidate généré, envoi au serveur...");
        _sendSignaling('ice_candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      },
    );

    // 5. NÉGOCIATION SDP (OFFER / ANSWER)
    if (isCaller) {
      // --- CAS APPELANT ---
      print("📤 Création de l'offre SDP...");
      final offer = await _webRTCService.createOffer(
        peerConnection!,
        hasVideo: wantVideo,
      );
      
      _sendSignaling('call_offer', {
        'sdp': offer.sdp,
        'call_type': callType,
      });
      print("✅ Offre envoyée avec succès");

    } else {
      // --- CAS DESTINATAIRE (RÉPONDEUR) ---
      // On récupère le SDP de l'offre envoyé par le MainShellController
      final String? sdpToUse = args['remoteSdp'] ?? pendingRemoteSdp;

      if (sdpToUse != null) {
        print("📥 Application de l'offre distante...");
        await peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdpToUse, 'offer')
        );
        
        print("📝 Création de la réponse (Answer)...");
        final answer = await _webRTCService.createAnswer(peerConnection!);
        
        _sendSignaling('call_accepted', {
          'sdp': answer.sdp
        });
        
        // Une fois la connexion établie, on traite les candidats ICE qui étaient en attente
        _processQueuedCandidates();
        
        callStatus.value = "En communication";
        print("✅ Réponse envoyée, appel connecté");
      } else {
        throw "Erreur : Aucun SDP distant (offre) n'a été trouvé.";
      }
    }
    
    print("📞 === APPEL INITIALISÉ AVEC SUCCÈS ===");
    
  } catch (e, stackTrace) {
    print("❌ Erreur CRITIQUE initCall: $e");
    print(stackTrace);
    callStatus.value = "Erreur de connexion";
    _cleanupCall();
  }
}

  void _handleAnswer(String sdp) async {
    if (peerConnection != null) {
      final remoteDesc = await peerConnection!.getRemoteDescription();
      if (remoteDesc == null) {
        await peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, 'answer')
        );
        _processQueuedCandidates();
        callStatus.value = "En cours";
      }
    }
  }

  void _handleIceCandidate(Map<String, dynamic> payload) async {
    final candidate = RTCIceCandidate(
      payload['candidate'], 
      payload['sdpMid'], 
      payload['sdpMLineIndex']
    );

    if (peerConnection != null && (await peerConnection!.getRemoteDescription()) != null) {
      await peerConnection!.addCandidate(candidate);
    } else {
      _iceCandidatesQueue.add(candidate);
    }
  }

  void _processQueuedCandidates() async {
    for (var cand in _iceCandidatesQueue) {
      await peerConnection!.addCandidate(cand);
    }
    _iceCandidatesQueue.clear();
  }

  void _sendSignaling(String type, Map<String, dynamic> data) {
    if (currentConversationId == null) return;
    _wsService.sendCallSignal(
      targetId: targetUserId,
      conversationId: currentConversationId!,
      action: type,
      extraData: data,
    );
  }

  // --- ACTIONS ---

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
      localStream!.getAudioTracks().forEach((t) => t.enabled = isMicEnabled.value);
    }
  }

  void toggleVideo() {
    if (localStream != null && callType == "VIDEO") {
      isVideoEnabled.value = !isVideoEnabled.value;
      localStream!.getVideoTracks().forEach((t) => t.enabled = isVideoEnabled.value);
    }
  }

  Future<void> switchCamera() async {
    if (localStream != null && isVideoEnabled.value) {
      final videoTrack = localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> _cleanupCall() async {
    isCallActive.value = false;
    isRinging.value = false;
    
    localStream?.getTracks().forEach((t) => t.stop());
    localStream?.dispose();
    localStream = null;

    await peerConnection?.close();
    await peerConnection?.dispose();
    peerConnection = null;
    
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    _iceCandidatesQueue.clear();
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