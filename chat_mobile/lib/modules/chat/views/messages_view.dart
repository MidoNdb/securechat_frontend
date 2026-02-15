// lib/modules/chat/views/messages_view.dart

import 'package:chat_mobile/modules/chat/views/contacts_view.dart';
import 'package:chat_mobile/modules/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/messages_controller.dart';
import '../widgets/conversation_card.dart';
import '../widgets/search_bar_widget.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabs(),  // ✅ Tabs modifiés
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // --- HEADER AVEC DÉGRADÉ ---
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.lock, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'SecureChat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Row(
          //   children: [
          //     // _buildIconButton(
          //     //   icon: Icons.search,
          //     //   onPressed: () => print("Recherche avancée"),
          //     // ),
          //     // const SizedBox(width: 12),
          //     Stack(
          //       children: [
          //         _buildIconButton(
          //           icon: Icons.settings,
          //           onPressed: () => Get.toNamed('/settings'),
          //         ),
          //         Obx(() {
          //           if (controller.totalUnreadCount.value > 0) {
          //             return Positioned(
          //               right: 0,
          //               top: 0,
          //               child: Container(
          //                 padding: const EdgeInsets.all(4),
          //                 decoration: BoxDecoration(
          //                   color: Colors.red,
          //                   shape: BoxShape.circle,
          //                   border: Border.all(
          //                     color: const Color(0xFF764ba2),
          //                     width: 2,
          //                   ),
          //                 ),
          //                 constraints: const BoxConstraints(
          //                   minWidth: 18,
          //                   minHeight: 18,
          //                 ),
          //                 child: Text(
          //                   '${controller.totalUnreadCount.value}',
          //                   style: const TextStyle(
          //                     color: Colors.white,
          //                     fontSize: 10,
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //                   textAlign: TextAlign.center,
          //                 ),
          //               ),
          //             );
          //           }
          //           return const SizedBox.shrink();
          //         }),
          //       ],
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  // --- BARRE DE RECHERCHE ---
  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SearchBarWidget(
        onChanged: (val) => controller.searchConversations(val),
      ),
    );
  }

  // --- ONGLETS (DISCUSSIONS / GROUPES) - ✅ APPELS SUPPRIMÉ ---
  Widget _buildTabs() {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: [
          _buildTab(title: 'Discussions', index: 0),
          // _buildTab(title: 'Groupes', index: 1),
          // ✅ Onglet "Appels" supprimé
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required int index}) {
    return Expanded(
      child: Obx(() {
        final isActive = controller.selectedTabIndex.value == index;
        return InkWell(
          onTap: () => controller.changeTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive
                      ? const Color(0xFF667eea)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF667eea)
                    : Colors.grey[600],
                fontWeight: isActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  // --- LISTE DES CONVERSATIONS ---
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: LoadingIndicator());
      }

      if (controller.filteredConversations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Aucune discussion',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Appuyez sur + pour démarrer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: ListView.builder(
          itemCount: controller.filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = controller.filteredConversations[index];
            
            return ConversationCard(
              conversation: conversation,
              currentUserId: controller.currentUserId,
              onTap: () => controller.openConversation(conversation),
            );
          },
        ),
      );
    });
  }

  // ✅ FAB pour nouvelle conversation
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'messages_fab',
        onPressed: () {
          print('📝 Opening ContactsView for new conversation');
          Get.to(
            () => ContactsView(),
            transition: Transition.rightToLeft,
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}


