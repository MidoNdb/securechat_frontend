import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../controllers/calls_controller.dart';

class CallsView extends GetView<CallsController> {
  const CallsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(
        () {
          // Détection dynamique du type d'appel
          final bool isVideoCall = controller.callType == 'VIDEO';
          
          return Stack(
            children: [
              // 1. Flux Vidéo Distant (ou Placeholder si Audio)
              Positioned.fill(
                child: (isVideoCall && controller.isRemoteVideoAvailable.value)
                    ? RTCVideoView(
                        controller.remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : _placeholder(),
              ),

              // 2. Flux Vidéo Local (PiP) - Uniquement si c'est un appel vidéo
              if (isVideoCall && controller.isCallActive.value)
                Positioned(
                  top: 50,
                  right: 16,
                  child: Obx(() => Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: controller.isVideoEnabled.value
                        ? RTCVideoView(
                            controller.localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
                          ),
                  )),
                ),

              // 3. Status et ID (UI en haut)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.callStatus.value.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Utilisateur: ${controller.targetUserId.split('-').first}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // 4. Contrôles (Boutons en bas)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: controller.isRinging.value
                    ? _incomingCallControls()
                    : _activeCallControls(isVideoCall),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- CONTROLES APPEL ENTRANT ---
  Widget _incomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          label: "Décliner", 
          icon: Icons.call_end, 
          color: Colors.red, 
          onTap: () => controller.rejectCall()
        ),
        _actionButton(
          label: "Répondre", 
          icon: Icons.call, 
          color: Colors.green, 
          onTap: () => controller.acceptCall()
        ),
      ],
    );
  }

  // --- CONTROLES APPEL ACTIF ---
  Widget _activeCallControls(bool isVideoCall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Micro
        Obx(() => IconButton(
          icon: Icon(
            controller.isMicEnabled.value ? Icons.mic : Icons.mic_off, 
            color: Colors.white, 
            size: 30,
          ),
          onPressed: controller.toggleMic,
        )),

        // Bouton Fin d'appel
        FloatingActionButton(
          heroTag: "end_call",
          backgroundColor: Colors.red, 
          child: const Icon(Icons.call_end, size: 30), 
          onPressed: () => controller.endCall()
        ),

        // Bouton Caméra (Uniquement si c'est un appel Vidéo)
        if (isVideoCall)
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30), 
            onPressed: controller.switchCamera
          )
        else
          const SizedBox(width: 48), // Pour garder l'équilibre visuel
      ],
    );
  }

  // --- WIDGETS AUXILIAIRES ---
  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color, 
          onPressed: onTap,
          child: Icon(icon), 
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, size: 80, color: Colors.white54),
            ),
            if (controller.callType == 'AUDIO')
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("Appel Audio...", style: TextStyle(color: Colors.white54, fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }
}