// lib/modules/chat/views/contacts_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/contacts_controller.dart';
import '../controllers/messages_controller.dart';

class ContactsView extends GetView<ContactsController> {
  const ContactsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: const Color(0xFF667eea),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.person_add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredContacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucun contact',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Appuyez sur + pour ajouter',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = controller.filteredContacts[index];
            return _buildContactCard(contact);
          },
        );
      }),
    );
  }

// lib/modules/chat/views/contacts_view.dart

Widget _buildContactCard(Map<String, dynamic> contact) {
  final displayName = contact['display_name'] ?? 'Sans nom';
  final phoneNumber = contact['contact_phone'] ?? '';

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF667eea),
        child: Text(
          displayName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(displayName),
      subtitle: Text(phoneNumber),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => controller.onContactTap(contact),  // ✅ Méthode du controller
    ),
  );
}


  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Nom ou numéro...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: controller.searchContacts,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchQuery.value = '';
              Get.back();
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
// lib/modules/chat/views/contacts_view.dart

void _showAddContactDialog() {
  final phoneController = TextEditingController();
  final nicknameController = TextEditingController();
  final countryCode = '+222'.obs;
  final isChecking = false.obs;
  final isAdding = false.obs;
  final userFound = Rx<Map<String, dynamic>?>(null);

  Get.dialog(
    AlertDialog(
      title: const Text('Ajouter un contact'),
      content: Obx(() {
        if (userFound.value != null) {
          return _buildConfirmationStep(
            userFound.value!,
            nicknameController,
            phoneController,
            countryCode,
          );
        }

        return _buildPhoneInputStep(
          phoneController,
          countryCode,
          isChecking,
          userFound,
        );
      }),
      actions: [
        TextButton(
          onPressed: () {
            userFound.value = null;
            Get.back();
          },
          child: const Text('Annuler'),
        ),
        Obx(() {
          if (userFound.value != null) {
            return ElevatedButton(
              onPressed: isAdding.value
                  ? null
                  : () async {
                      print('🔘 Add button pressed');
                      print('   Nickname: "${nicknameController.text.trim()}"');
                      
                      isAdding.value = true;
                      
                      final fullPhone = countryCode.value + phoneController.text;
                      
                      final success = await controller.addContact(
                        phoneNumber: fullPhone,
                        nickname: nicknameController.text.trim(),
                      );

                      print('📋 Add result: $success');

                      if (success) {
                        print('✅ Closing dialog');
                        // ✅ CORRECTION: Fermer AVANT de changer isAdding
                        // Get.back();
                        Navigator.of(Get.context!).pop();
                        // ✅ Attendre que le dialogue soit fermé
                        await Future.delayed(const Duration(milliseconds: 100));
                        isAdding.value = false;
                      } else {
                        print('❌ Failed to add');
                        isAdding.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
              ),
              child: isAdding.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Ajouter'),
            );
          }

          return ElevatedButton(
            onPressed: isChecking.value
                ? null
                : () async {
                    if (phoneController.text.isEmpty) {
                      Get.snackbar(
                        '❌',
                        'Entrez un numéro',
                        backgroundColor: Colors.red.withOpacity(0.1),
                        colorText: Colors.red,
                      );
                      return;
                    }

                    isChecking.value = true;
                    
                    final fullPhone = countryCode.value + phoneController.text;
                    print('🔍 Checking phone: $fullPhone');
                    
                    final user = await controller.checkPhoneExists(fullPhone);

                    isChecking.value = false;

                    if (user != null) {
                      print('✅ User found: ${user['display_name']}');
                      userFound.value = user;
                    } else {
                      print('❌ User not found');
                      Get.snackbar(
                        '',
                        'Ce numéro n\'utilise pas l\'application',
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        colorText: Colors.orange,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: isChecking.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Vérifier'),
          );
        }),
      ],
    ),
    barrierDismissible: false,
  );
}

Widget _buildConfirmationStep(
  Map<String, dynamic> user,
  TextEditingController nicknameController,
  TextEditingController phoneController,
  Rx<String> countryCode,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle, color: Colors.green, size: 48),
      const SizedBox(height: 16),
      const Text(
        'Utilisateur trouvé!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        user['display_name'] ?? 'Sans nom',
        style: const TextStyle(fontSize: 16),
      ),
      Text(
        user['phone_number'] ?? '',
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: nicknameController,
        decoration: const InputDecoration(
          labelText: 'Nom du contact',  // ✅ Retirer "(optionnel)"
          hintText: 'Mon ami, Collègue, Papa...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        textCapitalization: TextCapitalization.words,
        autofocus: true,  // ✅ Auto-focus pour faciliter saisie
      ),
      const SizedBox(height: 8),
      Text(
        'Laissez vide pour utiliser "${user['display_name']}"',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    ],
  );
}

  Widget _buildPhoneInputStep(
    TextEditingController phoneController,
    Rx<String> countryCode,
    RxBool isChecking,
    Rx<Map<String, dynamic>?> userFound,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Entrez le numéro de téléphone',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Obx(() => DropdownButton<String>(
                  value: countryCode.value,
                  items: const [
                    DropdownMenuItem(value: '+222', child: Text('🇲🇷 +222')),
                    DropdownMenuItem(value: '+33', child: Text('🇫🇷 +33')),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                    DropdownMenuItem(value: '+212', child: Text('🇲🇦 +212')),
                    DropdownMenuItem(value: '+221', child: Text('🇸🇳 +221')),
                  ],
                  onChanged: (value) {
                    if (value != null) countryCode.value = value;
                  },
                )),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  hintText: '44010447',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => isChecking.value
            ? const LinearProgressIndicator()
            : const SizedBox.shrink()),
      ],
    );
  }

}

