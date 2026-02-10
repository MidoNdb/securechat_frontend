// lib/modules/chat/views/profile_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }
          
          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildBody(),
            ],
          );
        }),
      ),
    );
  }

  // ==================== APP BAR ====================
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Color(0xFF667eea),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30), // ✅ Réduit de 40 à 30
              _buildAvatar(),
              SizedBox(height: 8), // ✅ Réduit de 12 à 8
              _buildUserInfo(),
            ],
          ),
        ),
       
      ),
      // actions: [
      //   IconButton(
      //     icon: Icon(Icons.logout, color: Colors.white),
      //     tooltip: 'Déconnexion',
      //     onPressed: controller.logout,
      //   ),
      // ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 50,
          color: Color(0xFF667eea),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Ajouté
      children: [
        Text(
          controller.currentUser?.displayName ?? 'Utilisateur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20, // ✅ Réduit de 22 à 20
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1, // ✅ Ajouté
          overflow: TextOverflow.ellipsis, // ✅ Ajouté
        ),
        SizedBox(height: 4),
        Text(
          controller.currentUser?.phoneNumber ?? '',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ==================== BODY ====================
  
  Widget _buildBody() {
    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 20),
        
        // ✅ Informations utilisateur
        _buildSection(
          title: 'Mon compte',
          items: [
            _buildInfoTile(
              icon: Icons.person,
              title: 'Nom',
              value: controller.currentUser?.displayName ?? '-',
            ),
            Divider(height: 1),
            _buildInfoTile(
              icon: Icons.phone,
              title: 'Téléphone',
              value: controller.currentUser?.phoneNumber ?? '-',
            ),
            Divider(height: 1),
            _buildInfoTile(
              icon: Icons.email,
              title: 'Email',
              value: controller.currentUser?.email ?? 'Non renseigné',
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        // ✅ Actions
        _buildSection(
          title: 'Actions',
          items: [
            _buildActionTile(
              icon: Icons.lock,
              iconColor: Colors.orange,
              title: 'Confidentialité',
              onTap: () {
                Get.snackbar(
                  'Info',
                  'Fonctionnalité en cours de développement',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            Divider(height: 1),
            _buildActionTile(
              icon: Icons.devices,
              iconColor: Colors.blue,
              title: 'Appareils connectés',
              onTap: () {
                Get.snackbar(
                  'Info',
                  'Fonctionnalité en cours de développement',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            Divider(height: 1),
            _buildActionTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Déconnexion',
              onTap: controller.logout,
            ),
          ],
        ),
        
        SizedBox(height: 40),
        
        // ✅ Version
        Center(
          child: Text(
            'SecureChat v1.0.0',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        
        SizedBox(height: 40),
      ]),
    );
  }

  // ==================== WIDGETS HELPERS ====================
  
  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: items),
        ),
      ],
    );
  }

  // ✅ Tuile d'information (lecture seule)
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Color(0xFF667eea),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ✅ Tuile d'action (cliquable)
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}