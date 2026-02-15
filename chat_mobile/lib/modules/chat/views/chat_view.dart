// lib/modules/chat/views/chat_view.dart
//  VERSION FINALE AMÉLIORÉE - UX optimale avec tous les nouveaux widgets

import 'dart:io';
import 'package:chat_mobile/app/routes/app_routes.dart';
import 'package:chat_mobile/modules/chat/widgets/inputs/audio_recorder.dart';
import 'package:chat_mobile/modules/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/inputs/media_picker_widget.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Liste des messages
          Expanded(child: _buildMessagesList()),
          
          // Prévisualisation images
          Obx(() {
            if (controller.selectedImages.isEmpty) return const SizedBox.shrink();
            return _buildImagePreview();
          }),
          
          // Zone d'input
          _buildInputArea(context),
        ],
      ),
    );
  }

  // ==================== APPBAR ====================
  
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final displayName = controller.conversation.name ?? 'Conversation';

    return AppBar(
      backgroundColor: const Color(0xFF667eea),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          // Avatar avec gradient
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                _getInitial(displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  controller.conversation.isGroup
                      ? '${controller.conversation.participants.length} participants'
                      : 'En ligne',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () => _handleCall(isVideo: true),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () => _handleCall(isVideo: false),
        ),
        _buildOptionsMenu(),
      ],
    );
  }
  // --- LOGIQUE DES APPELS CENTRALISÉE ---
  
  void _handleCall({required bool isVideo}) {
    final String targetId = controller.recipientId;
    
    if (targetId.isEmpty) {
      Get.snackbar(
        "Erreur", 
        "Destinataire introuvable",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white
      );
      return;
    }

    // Modifie cette partie dans ton ChatView
final arguments = {
  'conversationId': controller.conversation.id,
  'targetId': targetId,
  'callType': isVideo ? 'VIDEO' : 'AUDIO', // <--- METTRE EN MAJUSCULES ICI
  'isCaller': true,
};
    
    print(" Lancement de l'appel (${isVideo ? 'VIDEO' : 'AUDIO'}) vers $targetId");
    Get.toNamed(AppRoutes.CALLS, arguments: arguments);
  }

   // --- COMPOSANTS UI ---

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        // Logique de menu simplifiée
        print('Option sélectionnée: $value');
      },
      itemBuilder: (context) => [
        _buildPopupItem('info', Icons.info_outline, 'Info'),
        _buildPopupItem('mute', Icons.notifications_off_outlined, 'Désactiver'),
        _buildPopupItem('clear', Icons.delete_outline, 'Effacer'),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }


  
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'info':
            _showComingSoon('Info conversation');
            break;
          case 'mute':
            _showComingSoon('Désactiver notifications');
            break;
          case 'clear':
            _showComingSoon('Effacer conversation');
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem(Icons.info_outline_rounded, 'Info', 'info'),
        _buildPopupMenuItem(Icons.notifications_off_outlined, 'Désactiver', 'mute'),
        _buildPopupMenuItem(Icons.delete_outline_rounded, 'Effacer', 'clear'),
      ],
    );
  }
  
  PopupMenuItem<String> _buildPopupMenuItem(IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  // ==================== PRÉVISUALISATION IMAGES ====================

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de prévisualisation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.selectedImages.length} image(s) sélectionnée(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.selectedImages.clear(),
                  child: const Text('Tout supprimer'),
                ),
              ],
            ),
          ),
          
          // Liste des images
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: controller.selectedImages.length,
              itemBuilder: (context, index) {
                final imageFile = controller.selectedImages[index];
                
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Stack(
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      ),
                      
                      // Bouton supprimer
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => controller.removeImageFromSelection(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INPUT AREA ====================

  Widget _buildInputArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton attachements
          _buildAttachmentButton(context),
          
          const SizedBox(width: 8),
          
          // TextField
          Expanded(child: _buildTextField(context)),
          
          const SizedBox(width: 8),
          
          // Bouton Send
          _buildSendButton(),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMediaPicker(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.1),
                const Color(0xFF764ba2).withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF667eea),
            size: 28,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton micro
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: Color(0xFF667eea)),
            iconSize: 24,
            padding: const EdgeInsets.only(left: 12, right: 4),
            constraints: const BoxConstraints(),
            onPressed: () => _showVoiceRecorder(context),
          ),
          
          // TextField
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: const InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          
          const SizedBox(width: 8),
        ],
      ),
    );
  }
  
  Widget _buildSendButton() {
    return Obx(() {
      final hasText = controller.hasMessageText.value;
      final hasImages = controller.selectedImages.isNotEmpty;
      final isSending = controller.isSendingMessage.value;
      final canSend = (hasText || hasImages) && !isSending;
      
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSend ? controller.sendMessage : null,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: canSend
                  ? const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: canSend ? null : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: canSend
                  ? [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: isSending
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: canSend ? Colors.white : Colors.grey[400],
                    size: 22,
                  ),
          ),
        ),
      );
    });
  }

  // ==================== LISTE MESSAGES ====================

  Widget _buildMessagesList() {
    return Obx(() {
      if (controller.isLoading.value && controller.messages.isEmpty) {
        return const Center(child: LoadingIndicator());
      }

      if (controller.messages.isEmpty) {
        return _buildEmptyState();
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            if (controller.scrollController.position.pixels == 0) {
              controller.onLoadMore();
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: controller.messages.length + 
                     (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (controller.isLoadingMore.value && index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingIndicator(),
                ),
              );
            }

            final messageIndex = controller.isLoadingMore.value 
                ? index - 1 
                : index;
            final message = controller.messages[messageIndex];
            final isMe = message.senderId == controller.currentUserId;

            return MessageBubble(
              message: message,
              isMe: isMe,
              showAvatar: controller.conversation.isGroup,
              senderName: isMe ? null : message.senderName,
            );
          },
        ),
      );
    });
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.1),
                  const Color(0xFF764ba2).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: const Color(0xFF667eea).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez le premier message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _showMediaPicker(BuildContext context) {
    showMediaPicker(
      context,
      onImagesSelected: (images) {
        for (final image in images) {
          controller.addImageToSelection(image);
        }
      },
      onSingleImageSelected: (image) {
        controller.addImageToSelection(image);
      },
    );
  }

  void _showVoiceRecorder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height,
        child: AudioRecorderWidget(
          onRecordingComplete: (voiceFilePath) async {
            await controller.sendVoiceMessage(voiceFilePath);
          },
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Bientôt disponible',
      '$feature sera disponible prochainement',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
      colorText: const Color(0xFF667eea),
      icon: const Icon(Icons.info_outline, color: Color(0xFF667eea)),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  // ==================== HELPERS ====================

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    
    if (RegExp(r'^\+?\d').hasMatch(name)) {
      return name.replaceAll(RegExp(r'[^\d]'), '')[0];
    }
    
    return name[0].toUpperCase();
  }
}


