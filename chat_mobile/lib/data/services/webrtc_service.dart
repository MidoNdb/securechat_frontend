// lib/data/services/webrtc_service.dart

import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  // Configuration ICE (STUN servers)
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // Set pour éviter le double traitement des streams distants
  final Set<String> _processedStreams = {};

  /// Créer une instance PeerConnection complète
  Future<RTCPeerConnection> createPeerConnectionInstance({
    MediaStream? localStream,
    Function(MediaStream)? onRemoteStream,
    Function(RTCIceCandidate)? onIceCandidate,
  }) async {
    print('🔧 Création PeerConnection...');
    
    final pc = await createPeerConnection(_configuration);

    // ════════════════════════════════════════════════════════════
    // ÉVÉNEMENT 1 : État de connexion
    // ════════════════════════════════════════════════════════════
    pc.onConnectionState = (state) {
      print("📡 WebRTC Connection State: $state");
      
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print('✅ WebRTC connecté avec succès');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          print('❌ WebRTC connexion échouée');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          print('⚠️ WebRTC déconnecté');
          break;
        default:
          break;
      }
    };

    // ════════════════════════════════════════════════════════════
    // ÉVÉNEMENT 2 : ICE Candidates
    // ════════════════════════════════════════════════════════════
    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        print('🧊 ICE Candidate généré');
        onIceCandidate?.call(candidate);
      }
    };

    // ════════════════════════════════════════════════════════════
    // ÉVÉNEMENT 3 : Réception de pistes distantes (AUDIO + VIDEO)
    // ════════════════════════════════════════════════════════════
    _processedStreams.clear(); // Reset pour chaque nouvelle connexion
    
    pc.onTrack = (event) {
      print('📥 onTrack déclenché: ${event.track.kind}');
      
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        final streamId = stream.id;
        
        // ✅ FIX : Éviter de traiter le même stream 2 fois
        if (!_processedStreams.contains(streamId)) {
          _processedStreams.add(streamId);
          
          print('✅ Stream distant reçu:');
          print('   - Stream ID: $streamId');
          print('   - Track kind: ${event.track.kind}');
          print('   - Audio tracks: ${stream.getAudioTracks().length}');
          print('   - Video tracks: ${stream.getVideoTracks().length}');
          
          // ✅ Activer TOUTES les pistes audio explicitement
          for (var track in stream.getAudioTracks()) {
            track.enabled = true;
            print('🔊 Audio track activé: ${track.id}');
          }
          
          // ✅ Activer les pistes vidéo si présentes
          for (var track in stream.getVideoTracks()) {
            track.enabled = true;
            print('🎥 Video track activé: ${track.id}');
          }
          
          // Callback vers le controller
          onRemoteStream?.call(stream);
        } else {
          print('⚠️ Stream $streamId déjà traité (ignoré)');
        }
      } else {
        print('⚠️ onTrack: Aucun stream dans event.streams');
      }
    };

    // ════════════════════════════════════════════════════════════
    // AJOUT DES PISTES LOCALES À LA PEERCONNECTION
    // ════════════════════════════════════════════════════════════
    if (localStream != null) {
      print('📤 Ajout des pistes locales:');
      
      for (var track in localStream.getTracks()) {
        await pc.addTrack(track, localStream);
        print('   ✅ Track ${track.kind} ajouté (${track.id})');
      }
      
      print('✅ ${localStream.getTracks().length} pistes locales ajoutées');
    }

    print('✅ PeerConnection créée avec succès');
    return pc;
  }

  /// Récupérer le stream local (caméra + micro)
  Future<MediaStream> getUserMedia({required bool hasVideo}) async {
    print('🎤 Demande d\'accès média (Video: $hasVideo)...');
    
    final Map<String, dynamic> constraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': hasVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
            }
          : false,
    };

    try {
      final stream = await navigator.mediaDevices.getUserMedia(constraints);
      
      print('✅ Stream local obtenu:');
      print('   - Audio tracks: ${stream.getAudioTracks().length}');
      print('   - Video tracks: ${stream.getVideoTracks().length}');
      
      // ✅ CRITIQUE : Activer EXPLICITEMENT toutes les pistes
      for (var track in stream.getAudioTracks()) {
        track.enabled = true;
        print('🔊 Audio track local activé: ${track.id}');
      }
      
      for (var track in stream.getVideoTracks()) {
        track.enabled = true;
        print('🎥 Video track local activé: ${track.id}');
      }
      
      return stream;
      
    } catch (e) {
      print('❌ Erreur getUserMedia: $e');
      rethrow;
    }
  }

  /// Créer une offre SDP avec contraintes appropriées
  Future<RTCSessionDescription> createOffer(
    RTCPeerConnection pc, {
    required bool hasVideo,
  }) async {
    print('📝 Création de l\'offre SDP (Video: $hasVideo)...');
    
    // ✅ FIX : Ajouter les contraintes offerToReceive
    final Map<String, dynamic> offerOptions = {
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': hasVideo,
    };

    try {
      final offer = await pc.createOffer(offerOptions);
      await pc.setLocalDescription(offer);
      
      print('✅ Offre SDP créée:');
      print('   - Type: ${offer.type}');
      print('   - SDP length: ${offer.sdp?.length ?? 0} chars');
      
      return offer;
      
    } catch (e) {
      print('❌ Erreur createOffer: $e');
      rethrow;
    }
  }

  /// Créer une réponse SDP
  Future<RTCSessionDescription> createAnswer(RTCPeerConnection pc) async {
    print('📝 Création de la réponse SDP...');
    
    // ✅ Contraintes pour answer (optionnel mais recommandé)
    final Map<String, dynamic> answerOptions = {
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true, // Accepte vidéo si offerte
    };

    try {
      final answer = await pc.createAnswer(answerOptions);
      await pc.setLocalDescription(answer);
      
      print('✅ Réponse SDP créée:');
      print('   - Type: ${answer.type}');
      print('   - SDP length: ${answer.sdp?.length ?? 0} chars');
      
      return answer;
      
    } catch (e) {
      print('❌ Erreur createAnswer: $e');
      rethrow;
    }
  }

  /// Définir la description distante (offre ou réponse reçue)
  Future<void> setRemoteDescription(
    RTCPeerConnection pc,
    String sdp,
    String type,
  ) async {
    print('📥 Définition de la description distante ($type)...');
    
    try {
      final remoteDesc = RTCSessionDescription(sdp, type);
      await pc.setRemoteDescription(remoteDesc);
      
      print('✅ Description distante définie');
      
    } catch (e) {
      print('❌ Erreur setRemoteDescription: $e');
      rethrow;
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _processedStreams.clear();
    print('🧹 WebRTCService nettoyé');
  }
}


// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class WebRTCService {
//   final Map<String, dynamic> _configuration = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//     ],
//     'sdpSemantics': 'unified-plan',
//   };

//   Future<RTCPeerConnection> createPeerConnectionInstance({
//     MediaStream? localStream,
//     Function(MediaStream)? onRemoteStream,
//     Function(RTCIceCandidate)? onIceCandidate,
//   }) async {
//     final pc = await createPeerConnection(_configuration);

//     pc.onConnectionState = (state) {
//       print("📡 WebRTC State: $state");
//     };

//     pc.onIceCandidate = (candidate) {
//       if (candidate != null) onIceCandidate?.call(candidate);
//     };

//     pc.onTrack = (event) {
//       if (event.streams.isNotEmpty && event.track.kind == 'video') {
//         print("🎥 Flux vidéo distant reçu");
//         onRemoteStream?.call(event.streams.first);
//       } else if (event.streams.isNotEmpty && event.track.kind == 'audio') {
//         print("🎤 Flux audio distant reçu");
//         onRemoteStream?.call(event.streams.first);
//       }
//     };

//     // On ajoute les pistes ici UNE SEULE FOIS
//     if (localStream != null) {
//       for (var track in localStream.getTracks()) {
//         await pc.addTrack(track, localStream);
//       }
//       print("✅ Pistes locales ajoutées à la PeerConnection");
//     }

//     return pc;
//   }

//   Future<MediaStream> getUserMedia({required bool hasVideo}) async {
//     final Map<String, dynamic> constraints = {
//       'audio': true,
//       'video': hasVideo ? {
//         'facingMode': 'user',
//         'width': {'ideal': 640}, // Réduit un peu pour la stabilité
//         'height': {'ideal': 480},
//       } : false,
//     };
    
//     try {
//       return await navigator.mediaDevices.getUserMedia(constraints);
//     } catch (e) {
//       print("❌ Erreur getUserMedia: $e");
//       rethrow;
//     }
//   }

//   Future<RTCSessionDescription> createOffer(RTCPeerConnection pc) async {
//     // On utilise des contraintes dynamiques selon ce qui a été ajouté
//     final offer = await pc.createOffer(); 
//     await pc.setLocalDescription(offer);
//     return offer;
//   }

//   Future<RTCSessionDescription> createAnswer(RTCPeerConnection pc) async {
//     final answer = await pc.createAnswer();
//     await pc.setLocalDescription(answer);
//     return answer;
//   }

//   // ... reste de tes méthodes (setRemoteDescription, etc.)
// }