// lib/modules/chat/widgets/message_bubble.dart
// ✅ VERSION AMÉLIORÉE - Switch automatique selon type de message

import 'package:chat_mobile/data/models/message.dart';
import 'package:flutter/material.dart';
import 'bubbles/text_bubble.dart';
import 'bubbles/image_bubble.dart';
import 'bubbles/voice_bubble.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? senderName;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.senderName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Switch selon le type de message
    switch (message.type.toUpperCase()) {
      case 'IMAGE':
        return ImageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          senderName: senderName,
        );
      
      case 'VOICE':
        return VoiceBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          senderName: senderName,
        );
      
      case 'FILE':
        // TODO: Implémenter FileBubble
        return _buildComingSoon('FILE');
      
      case 'TEXT':
      default:
        return TextBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          senderName: senderName,
        );
    }
  }
  
  /// Widget temporaire pour types non implémentés
  Widget _buildComingSoon(String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Type $type - Bientôt disponible',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


