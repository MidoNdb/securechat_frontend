// lib/modules/chat/widgets/inputs/audio_recorder_widget.dart
// ✅ VERSION AMÉLIORÉE - Interface moderne style WhatsApp

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/voice_message_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path) onRecordingComplete;
  final VoidCallback? onCancel;

  const AudioRecorderWidget({
    Key? key,
    required this.onRecordingComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with TickerProviderStateMixin {
  final VoiceMessageService _voiceService = Get.find<VoiceMessageService>();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  Timer? _amplitudeTimer;
  final amplitudeBars = <double>[].obs;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startRecording();
    _startAmplitudeUpdates();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _amplitudeTimer?.cancel();
    super.dispose();
  }
  
  void _setupAnimations() {
    // Animation pulse pour le cercle central
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Animation pour les barres
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
    
    // Initialiser les barres
    amplitudeBars.value = List.generate(40, (_) => 0.3);
  }
  
  void _startAmplitudeUpdates() {
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateAmplitudeBars(),
    );
  }
  
  void _updateAmplitudeBars() {
    final currentAmplitude = _voiceService.currentAmplitude.value;
    final newBars = List<double>.from(amplitudeBars);
    
    // Décaler toutes les barres vers la gauche
    newBars.removeAt(0);
    
    // Ajouter une nouvelle barre basée sur l'amplitude
    final newHeight = 0.3 + (currentAmplitude * 0.7);
    newBars.add(newHeight);
    
    amplitudeBars.value = newBars;
  }
  
  Future<void> _startRecording() async {
    final started = await _voiceService.startRecording();
    
    if (!started) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      Navigator.of(context).pop();
    }
  }
  
  Future<void> _stopAndSend() async {
    final file = await _voiceService.stopRecording();
    
    if (file != null && mounted) {
      widget.onRecordingComplete(file.path);
      Navigator.of(context).pop();
    }
  }
  
  Future<void> _cancel() async {
    await _voiceService.cancelRecording();
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec timer
            _buildHeader(),
            
            const SizedBox(height: 40),
            
            // Visualisation centrale
            Expanded(
              child: _buildVisualization(),
            ),
            
            // Contrôles
            _buildControls(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Bouton close
          IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
          
          const Spacer(),
          
          // Timer avec style WhatsApp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Point rouge clignotant
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.4 + (_pulseController.value * 0.6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 12),
                
                // Durée
                Obx(() => Text(
                  _formatDuration(Duration(milliseconds: _voiceService.recordingDuration.value)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                )),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Espace pour équilibrer
          const SizedBox(width: 48),
        ],
      ),
    );
  }
  
  Widget _buildVisualization() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cercle principal avec micro
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 60),
        
        // Barres d'amplitude style WhatsApp
        Obx(() => _buildAmplitudeBars()),
        
        const SizedBox(height: 30),
        
        // Texte indicateur
        Text(
          'Enregistrement...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAmplitudeBars() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(amplitudeBars.length, (index) {
          final height = amplitudeBars[index];
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 3,
            height: height * 80,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF667eea).withOpacity(0.6),
                  const Color(0xFF667eea),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton Supprimer
          _buildControlButton(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: Colors.red.shade400,
            onTap: _cancel,
          ),
          
          const SizedBox(width: 40),
          
          // Bouton Envoyer
          _buildControlButton(
            icon: Icons.send_rounded,
            label: 'Envoyer',
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            onTap: _stopAndSend,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color? color,
    Gradient? gradient,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: isPrimary ? gradient : null,
                color: !isPrimary ? color?.withOpacity(0.2) : null,
                shape: BoxShape.circle,
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

