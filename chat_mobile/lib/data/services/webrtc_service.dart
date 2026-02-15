// lib/data/services/webrtc_service.dart

import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final Set<String> _processedStreams = {};

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<MediaStream> getUserMedia({required bool hasVideo}) async {
    final mediaConstraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': hasVideo
          ? {'facingMode': 'user', 'width': 1280, 'height': 720}
          : false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    for (final track in stream.getAudioTracks()) {
      track.enabled = true;
    }

    return stream;
  }

  Future<RTCPeerConnection> createPeerConnectionInstance({
    MediaStream? localStream,
    Function(MediaStream)? onRemoteStream,
    Function(RTCIceCandidate)? onIceCandidate,
    Function(RTCPeerConnectionState)? onConnectionState,
    Function(RTCIceConnectionState)? onIceConnectionState,
  }) async {
    final pc = await createPeerConnection(_configuration);

    pc.onConnectionState = (state) {
      onConnectionState?.call(state);
    };

    pc.onIceConnectionState = (state) {
      onIceConnectionState?.call(state);
    };

    pc.onIceCandidate = (candidate) {
      onIceCandidate?.call(candidate);
    };

    _processedStreams.clear();

    pc.onTrack = (event) {
      if (event.streams.isEmpty) return;

      final stream = event.streams.first;
      if (_processedStreams.contains(stream.id)) return;

      _processedStreams.add(stream.id);

      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }
      for (final track in stream.getVideoTracks()) {
        track.enabled = true;
      }

      onRemoteStream?.call(stream);

      // Forcer l'activation audio après un court délai (workaround WebRTC connu)
      Future.delayed(const Duration(milliseconds: 300), () {
        for (final track in stream.getAudioTracks()) {
          track.enabled = true;
        }
      });
    };

    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        await pc.addTrack(track, localStream);
      }
    }

    return pc;
  }

  Future<RTCSessionDescription> createOffer(
    RTCPeerConnection pc, {
    required bool hasVideo,
  }) async {
    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': hasVideo,
    });

    await pc.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(RTCPeerConnection pc) async {
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    return answer;
  }

  /// Nettoyage des ressources
  void dispose() {
    _processedStreams.clear();
  }
}