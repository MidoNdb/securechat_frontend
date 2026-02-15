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
      body: Obx(() {
        final bool isVideoCall = controller.callType == 'VIDEO';
        
        return Stack(
          children: [
            Positioned.fill(
              child: (isVideoCall && controller.isRemoteVideoAvailable.value)
                  ? RTCVideoView(
                      controller.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : _placeholder(isVideoCall),
            ),

            if (isVideoCall && controller.isCallActive.value)
              Positioned(
                top: 50,
                right: 16,
                child: Container(
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
                ),
              ),

            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        Text(
                          controller.callStatus.value.toUpperCase(),
                          style: TextStyle(
                            color: controller.isCallConnected.value 
                                ? Colors.greenAccent 
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 13,
                          ),
                        ),
                        if (controller.isCallConnected.value && 
                            controller.callDuration.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              controller.callDuration.value,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "ID: ${controller.targetUserId.split('-').first}",
                    style: const TextStyle(
                      color: Colors.white60, 
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  if (controller.isCallConnected.value)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _audioWaveIndicator(),
                    ),
                ],
              ),
            ),

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
      }),
    );
  }

  Widget _audioWaveIndicator() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final height = 4.0 + (controller.audioLevel.value * 20 * ((index % 2) + 1));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    ));
  }

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

  Widget _activeCallControls(bool isVideoCall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Obx(() => IconButton(
          icon: Icon(
            controller.isMicEnabled.value ? Icons.mic : Icons.mic_off, 
            color: Colors.white, 
            size: 32,
          ),
          onPressed: () => controller.toggleMic(),
        )),

        FloatingActionButton(
          heroTag: "end_call",
          backgroundColor: Colors.red,
          onPressed: () => controller.endCall(),
          child: const Icon(Icons.call_end, size: 32), 
        ),

        if (isVideoCall)
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32), 
            onPressed: () => controller.switchCamera(),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _actionButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color, 
          onPressed: onTap,
          child: Icon(icon, size: 30), 
        ),
        const SizedBox(height: 10),
        Text(
          label, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(bool isVideoCall) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF0f0f0f)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person, 
                size: 90, 
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              isVideoCall ? "Vidéo en attente..." : "Appel Audio",
              style: const TextStyle(
                color: Colors.white60, 
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import '../controllers/calls_controller.dart';

// class CallsView extends GetView<CallsController> {
//   const CallsView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Obx(() {
//         final bool isVideoCall = controller.callType == 'VIDEO';
        
//         return Stack(
//           children: [
//             Positioned.fill(
//               child: (isVideoCall && controller.isRemoteVideoAvailable.value)
//                   ? RTCVideoView(
//                       controller.remoteRenderer,
//                       objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                     )
//                   : _placeholder(isVideoCall),
//             ),

//             if (isVideoCall && controller.isCallActive.value)
//               Positioned(
//                 top: 50,
//                 right: 16,
//                 child: Container(
//                   width: 120,
//                   height: 180,
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.white24, width: 2),
//                   ),
//                   clipBehavior: Clip.antiAlias,
//                   child: controller.isVideoEnabled.value
//                       ? RTCVideoView(
//                           controller.localRenderer,
//                           mirror: true,
//                           objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                         )
//                       : const Center(
//                           child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
//                         ),
//                 ),
//               ),

//             Positioned(
//               top: 60,
//               left: 0,
//               right: 0,
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.black38,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           controller.callStatus.value.toUpperCase(),
//                           style: const TextStyle(
//                             color: Colors.white, 
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 1.2,
//                             fontSize: 12,
//                           ),
//                         ),
//                         if (controller.isCallActive.value)
//                           Text(
//                             controller.callDuration.value,
//                             style: const TextStyle(
//                               color: Colors.greenAccent,
//                               fontSize: 24,
//                               fontWeight: FontWeight.w200,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Correspondant: ${controller.targetUserId.split('-').first}",
//                     style: const TextStyle(color: Colors.white70),
//                   ),
//                 ],
//               ),
//             ),

//             Positioned(
//               bottom: 50,
//               left: 0,
//               right: 0,
//               child: controller.isRinging.value
//                   ? _incomingCallControls()
//                   : _activeCallControls(isVideoCall),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _incomingCallControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _actionButton(
//           label: "Décliner", 
//           icon: Icons.call_end, 
//           color: Colors.red, 
//           onTap: () => controller.rejectCall()
//         ),
//         _actionButton(
//           label: "Répondre", 
//           icon: Icons.call, 
//           color: Colors.green, 
//           onTap: () => controller.acceptCall()
//         ),
//       ],
//     );
//   }

//   Widget _activeCallControls(bool isVideoCall) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         Obx(() => IconButton(
//           icon: Icon(
//             controller.isMicEnabled.value ? Icons.mic : Icons.mic_off, 
//             color: Colors.white, 
//             size: 30,
//           ),
//           onPressed: () => controller.toggleMic(),
//         )),

//         FloatingActionButton(
//           heroTag: "end_call",
//           backgroundColor: Colors.red, 
//           onPressed: () => controller.endCall(),
//           child: const Icon(Icons.call_end, size: 30), 
//         ),

//         if (isVideoCall)
//           IconButton(
//             icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30), 
//             onPressed: () => controller.switchCamera(),
//           )
//         else
//           const SizedBox(width: 48),
//       ],
//     );
//   }

//   Widget _actionButton({
//     required String label, 
//     required IconData icon, 
//     required Color color, 
//     required VoidCallback onTap
//   }) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         FloatingActionButton(
//           heroTag: label,
//           backgroundColor: color, 
//           onPressed: onTap,
//           child: Icon(icon), 
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(color: Colors.white)),
//       ],
//     );
//   }

//   Widget _placeholder(bool isVideoCall) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Color(0xFF2C3E50), Color(0xFF000000)],
//         ),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircleAvatar(
//               radius: 60,
//               backgroundColor: Colors.white10,
//               child: Icon(Icons.person, size: 80, color: Colors.white54),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isVideoCall ? "Vidéo en attente..." : "Appel Audio",
//               style: const TextStyle(color: Colors.white54, fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


