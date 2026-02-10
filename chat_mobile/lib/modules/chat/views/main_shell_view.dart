// lib/modules/main/views/main_shell_view.dart

import 'package:chat_mobile/modules/chat/views/callslistview.dart';
import 'package:chat_mobile/modules/chat/views/messages_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../chat/controllers/main_shell_controller.dart';
import '../../chat/views/contacts_view.dart';
import '../../chat/views/calls_view.dart';
import '../../chat/views/profile_view.dart';

class MainShellView extends GetView<MainShellController> {
  const MainShellView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ Gère le retour dans les navigators imbriqués
        final currentIndex = controller.currentIndex.value;
        final navigator = controller.navigatorKeys[currentIndex].currentState;
        
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return false;  // Ne quitte pas l'app
        }
        
        return true;  // Quitte l'app si pas de page précédente
      },
      child: Scaffold(
        body: Obx(() => IndexedStack(
          index: controller.currentIndex.value,
          children: [
            // ✅ Chaque page a son propre Navigator
            _buildNavigator(0, const MessagesView()),
            _buildNavigator(1, const ContactsView()),
            _buildNavigator(2,  CallsListView()),
            _buildNavigator(3, const ProfileView()),
          ],
        )),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // ✅ Navigator imbriqué pour chaque onglet
  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: controller.navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Obx(() => BottomNavigationBar(
      currentIndex: controller.currentIndex.value,
      onTap: controller.changePage,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF667eea),
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Conversations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contacts),
          label: 'Contacts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.phone),
          label: 'Appels',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ));
  }
}
