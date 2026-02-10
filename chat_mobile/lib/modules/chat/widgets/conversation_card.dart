// lib/modules/chat/widgets/conversation_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/conversation.dart';

class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final String? currentUserId;
  final VoidCallback onTap;

  const ConversationCard({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),
            
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + Heure
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name ?? 'Conversation',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTimestamp(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Dernier message + Badge
                  Row(
                    children: [
                      Expanded(
                        child: _buildLastMessage(),
                      ),
                      if (conversation.unreadCount > 0)
                        _buildUnreadBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // AVATAR
  // ========================================
  
  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final name = conversation.name ?? 'C';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  // ========================================
  // TIMESTAMP
  // ========================================
  
  Widget _buildTimestamp() {
    final date = conversation.lastMessageAt ?? conversation.createdAt;
    final now = DateTime.now();
    final difference = now.difference(date);

    String timeText;
    
    if (difference.inMinutes < 1) {
      timeText = 'À l\'instant';
    } else if (difference.inHours < 1) {
      timeText = '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      timeText = DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      timeText = DateFormat('EEE', 'fr_FR').format(date);
    } else {
      timeText = DateFormat('dd/MM').format(date);
    }

    return Text(
      timeText,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  // ========================================
  // ✅ DERNIER MESSAGE (CORRIGÉ)
  // ========================================
  
  Widget _buildLastMessage() {
    final lastMessage = conversation.lastMessage;
    
    // Cas 1 : Pas de dernier message
    if (lastMessage == null) {
      return Text(
        'Aucun message',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Cas 2 : Message déchiffré disponible
    if (lastMessage.decryptedContent != null && 
        lastMessage.decryptedContent!.isNotEmpty) {
      final isMine = lastMessage.senderId == currentUserId;
      
      return Text(
        isMine 
            ? 'Vous: ${lastMessage.decryptedContent}'
            : lastMessage.decryptedContent!,
        style: TextStyle(
          fontSize: 14,
          color: conversation.unreadCount > 0
              ? Colors.black87
              : Colors.grey[600],
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Cas 3 : Message chiffré (non déchiffré)
    return Row(
      children: [
        Icon(
          Icons.lock,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          'Message chiffré',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // ========================================
  // BADGE NON LUS
  // ========================================
  
  Widget _buildUnreadBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        conversation.unreadCount > 99
            ? '99+'
            : conversation.unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

