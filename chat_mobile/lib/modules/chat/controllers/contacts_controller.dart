// lib/modules/chat/controllers/contacts_controller.dart

import 'package:chat_mobile/modules/chat/controllers/messages_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/contact_service.dart';
import '../../../data/models/contact.dart' as models;

class ContactsController extends GetxController {
  final ContactService _contactService = Get.find<ContactService>();

  final contacts = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      isLoading.value = true;
      final result = await _contactService.getContacts();
      contacts.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> checkPhoneExists(String phoneNumber) async {
    return await _contactService.checkPhoneNumber(phoneNumber);
  }

 // lib/modules/chat/controllers/contacts_controller.dart

Future<bool> addContact({
  required String phoneNumber,
  required String nickname,
  String? notes,
}) async {
  try {
    isLoading.value = true;

    print('🔄 ContactsController.addContact:');
    print('   Phone: $phoneNumber');
    print('   Nickname: "$nickname"');

    final newContact = await _contactService.addContact(
      phoneNumber: phoneNumber,
      nickname: nickname,
      notes: notes,
    );

    if (newContact != null) {
      print('Contact received from service:');
      print('   ID: ${newContact['id']}');
      print('   Display name: ${newContact['display_name']}');
      print('   Nickname: ${newContact['nickname']}');
      
      contacts.insert(0, newContact);
      
      Get.snackbar(
        'Succès',
        'Contact "${newContact['display_name']}" ajouté',  // ✅ Affiche le nom
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
      
      return true;  // ✅ IMPORTANT: Retourne true
    }

    print('newContact is null');
    return false;
  } catch (e) {
    print('addContact exception: $e');
    Get.snackbar(
      'Erreur',
      e.toString().contains('already exists')
          ? 'Ce contact existe déjà'
          : 'Impossible d\'ajouter le contact',
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      duration: const Duration(seconds: 3),
    );
    return false;
  } finally {
    isLoading.value = false;
  }
}

  Future<void> toggleBlock(String contactId, bool currentlyBlocked) async {
    final success = await _contactService.toggleBlock(contactId, currentlyBlocked);
    
    if (success) {
      final index = contacts.indexWhere((c) => c['id'] == contactId);
      if (index != -1) {
        contacts[index]['is_blocked'] = !currentlyBlocked;
        contacts.refresh();
      }
      
      Get.snackbar(
        '',
        currentlyBlocked ? 'Contact débloqué' : 'Contact bloqué',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    }
  }

  Future<void> toggleFavorite(String contactId, bool currentlyFavorite) async {
    final success = await _contactService.toggleFavorite(contactId);
    
    if (success) {
      final index = contacts.indexWhere((c) => c['id'] == contactId);
      if (index != -1) {
        contacts[index]['is_favorite'] = !currentlyFavorite;
        contacts.refresh();
      }
    }
  }

  Future<void> deleteContact(String contactId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Supprimer ce contact ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _contactService.deleteContact(contactId);
      
      if (success) {
        contacts.removeWhere((c) => c['id'] == contactId);
        Get.snackbar(
          '✅',
          'Contact supprimé',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
      }
    }
  }

  void searchContacts(String query) {
    searchQuery.value = query;
  }

  List<Map<String, dynamic>> get filteredContacts {
    if (searchQuery.isEmpty) return contacts;

    return contacts.where((contact) {
      final name = (contact['display_name'] ?? '').toString().toLowerCase();
      final phone = (contact['contact_phone'] ?? '').toString();
      final query = searchQuery.value.toLowerCase();

      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get favoriteContacts {
    return contacts.where((c) => c['is_favorite'] == true).toList();
  }

  List<Map<String, dynamic>> get blockedContacts {
    return contacts.where((c) => c['is_blocked'] == true).toList();
  }

  // lib/modules/chat/controllers/contacts_controller.dart

// ✅ Quand un contact est sélectionné
void onContactTap(Map<String, dynamic> contact) {
  final contactUserId = contact['contact_user_id']?.toString();
  final contactName = contact['display_name'] ?? 'Contact';
  
  if (contactUserId == null) {
    Get.snackbar('❌', 'ID utilisateur manquant');
    return;
  }
  
  print('📞 Contact selected: $contactName ($contactUserId)');
  
  // ✅ Appelle MessagesController pour gérer la navigation
  final messagesController = Get.find<MessagesController>();
  messagesController.openOrCreateConversation(
    contactUserId: contactUserId,
    contactName: contactName,
  );
}
}

