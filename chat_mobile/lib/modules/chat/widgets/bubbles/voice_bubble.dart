// lib/modules/chat/widgets/bubbles/voice_bubble.dart
// ✅ VERSION AMÉLIORÉE - Style WhatsApp avec couleurs de l'app

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../data/models/message.dart';
import '../../../../data/services/voice_message_service.dart';

class VoiceBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? senderName;

  const VoiceBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.senderName,
  }) : super(key: key);

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble>
    with SingleTickerProviderStateMixin {
  final VoiceMessageService _voiceService = Get.find<VoiceMessageService>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final isPlaying = false.obs;
  final isLoading = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  
  File? _audioFile;
  late AnimationController _waveController;
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _initAudio();
    _setupAudioListeners();
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  // ==================== INITIALISATION ====================
  
  Future<void> _initAudio() async {
    try {
      isLoading.value = true;
      
      // Déchiffrer et récupérer le fichier audio
      _audioFile = await _voiceService.decryptVoice(widget.message);
      
      // Extraire durée depuis metadata
      if (widget.message.metadata != null && 
          widget.message.metadata!['duration'] != null) {
        totalDuration.value = Duration(
          seconds: widget.message.metadata!['duration'] as int
        );
      }
      
    } catch (e) {
      print('❌ Erreur init audio: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void _setupAudioListeners() {
    // État de lecture
    _audioPlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = (state == PlayerState.playing);
    });
    
    // Position actuelle
    _audioPlayer.onPositionChanged.listen((position) {
      currentPosition.value = position;
    });
    
    // Durée totale
    _audioPlayer.onDurationChanged.listen((duration) {
      if (duration.inSeconds > 0) {
        totalDuration.value = duration;
      }
    });
    
    // Fin de lecture
    _audioPlayer.onPlayerComplete.listen((_) {
      currentPosition.value = Duration.zero;
      isPlaying.value = false;
    });
  }
  
  // ==================== LECTURE ====================
  
  Future<void> _togglePlayPause() async {
    try {
      if (_audioFile == null) {
        await _initAudio();
        if (_audioFile == null) return;
      }
      
      if (isPlaying.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioFile!.path));
      }
      
    } catch (e) {
      print('❌ Erreur lecture: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de lire le message vocal',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
  
  // ==================== UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 200,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: widget.isMe 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            // Nom expéditeur (si groupe)
            if (!widget.isMe && widget.senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  widget.senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Bubble vocal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: widget.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isMe ? null : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                  bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton Play/Pause
                  _buildPlayButton(),
                  
                  const SizedBox(width: 8),
                  
                  // Waveform + Progress
                  Expanded(
                    child: _buildWaveform(),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Durée
                  _buildDurationText(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayButton() {
    return Obx(() {
      if (isLoading.value) {
        return Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              widget.isMe ? Colors.white : const Color(0xFF667eea),
            ),
          ),
        );
      }
      
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _togglePlayPause,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isMe 
                  ? Colors.white.withOpacity(0.25)
                  : const Color(0xFF667eea).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying.value ? Icons.pause : Icons.play_arrow,
              size: 20,
              color: widget.isMe ? Colors.white : const Color(0xFF667eea),
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildWaveform() {
    return Obx(() {
      final progress = totalDuration.value.inMilliseconds > 0
          ? currentPosition.value.inMilliseconds / 
            totalDuration.value.inMilliseconds
          : 0.0;
      
      return SizedBox(
        height: 32,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return CustomPaint(
              painter: VoiceWaveformPainter(
                progress: progress,
                animationValue: isPlaying.value ? _waveController.value : 0.0,
                color: widget.isMe ? Colors.white : const Color(0xFF667eea),
                isPlaying: isPlaying.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      );
    });
  }
  
  Widget _buildDurationText() {
    return Obx(() {
      final duration = isPlaying.value && totalDuration.value.inSeconds > 0
          ? totalDuration.value - currentPosition.value
          : totalDuration.value;
      
      return Text(
        _formatDuration(duration),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: widget.isMe 
              ? Colors.white.withOpacity(0.9)
              : Colors.grey[700],
        ),
      );
    });
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ==================== WAVEFORM PAINTER AMÉLIORÉ ====================

class VoiceWaveformPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;
  final bool isPlaying;
  
  VoiceWaveformPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.isPlaying,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    
    const barCount = 35;
    final barWidth = size.width / barCount;
    final barGap = barWidth * 0.4;
    final barActualWidth = barWidth - barGap;
    
    // Hauteurs prédéfinies pour un aspect naturel
    final heights = _generateHeights(barCount);
    
    for (int i = 0; i < barCount; i++) {
      // Hauteur avec animation si en lecture
      var normalizedHeight = heights[i];
      
      if (isPlaying) {
        // Animation ondulante
        final wave = (i / barCount * 2 * 3.14159) + (animationValue * 2 * 3.14159);
        final waveEffect = (1 + (0.3 * (1 + (i % 2 == 0 ? 1 : -1) * 
          (normalizedHeight * 0.5 + 0.5) * (1 + (i % 3 == 0 ? 0.2 : 0)))));
        normalizedHeight *= waveEffect;
        normalizedHeight = normalizedHeight.clamp(0.3, 1.0);
      }
      
      final barHeight = size.height * normalizedHeight;
      final x = i * barWidth;
      final y = (size.height - barHeight) / 2;
      
      // Couleur selon progression
      final isBeforeProgress = (i / barCount) <= progress;
      paint.color = isBeforeProgress
          ? color
          : color.withOpacity(0.3);
      
      // Dessiner la barre avec coins arrondis
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barActualWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }
  
  List<double> _generateHeights(int count) {
    // Génère un pattern naturel de hauteurs
    return List.generate(count, (i) {
      final base = 0.3;
      final variation = (i % 5 == 0 ? 0.7 : 
                        i % 3 == 0 ? 0.5 : 
                        i % 2 == 0 ? 0.4 : 0.35);
      return base + variation;
    });
  }
  
  @override
  bool shouldRepaint(VoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.isPlaying != isPlaying;
  }
}

