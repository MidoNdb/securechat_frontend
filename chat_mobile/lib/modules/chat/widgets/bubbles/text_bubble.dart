// lib/modules/chat/widgets/bubbles/text_bubble.dart
// ✅ CODE EXTRAIT DE VOTRE message_bubble.dart EXISTANT

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/message.dart';

class TextBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? senderName;

  const TextBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.senderName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) _buildAvatar(),
          if (!isMe && showAvatar) const SizedBox(width: 8),
          Flexible(child: _buildBubble(context)),
          if (isMe && showAvatar) const SizedBox(width: 8),
          if (isMe && showAvatar) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF667eea),
      child: Text(
        (senderName ?? 'U')[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF667eea) : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && showAvatar && senderName != null) ...[
            Text(
              senderName!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message.decryptedContent ?? '[Message chiffré]',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : Colors.grey[600],
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.white70;
        break;
      case 'sent':
        icon = Icons.check;
        color = Colors.white70;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.lightBlueAccent;
        break;
      case 'failed':
        icon = Icons.error_outline;
        color = Colors.red[300]!;
        break;
      default:
        icon = Icons.check;
        color = Colors.white70;
    }

    return Icon(icon, size: 14, color: color);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}