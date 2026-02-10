// lib/data/services/contact_service.dart

import 'package:get/get.dart';
import '../api/dio_client.dart';
import '../api/api_endpoints.dart';

class ContactService extends GetxService {
  late final DioClient _dioClient;

  @override
  void onInit() {
    super.onInit();
    _dioClient = Get.find<DioClient>();
  }

  // 1. Vérifier si un numéro existe
  Future<Map<String, dynamic>?> checkPhoneNumber(String phoneNumber) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.searchContacts,
        queryParameters: {'q': phoneNumber},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true && data['data'] is List) {
          final users = data['data'] as List;
          
          if (users.isNotEmpty) {
            final user = users.firstWhere(
              (u) => u['phone_number'] == phoneNumber,
              orElse: () => null,
            );
            return user;
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ checkPhoneNumber: $e');
      return null;
    }
  }

// 2. Ajouter un contact
Future<Map<String, dynamic>?> addContact({
  required String phoneNumber,
  required String nickname,
  String? notes,
}) async {
  try {
    print('📤 Adding contact:');
    print('   Phone: $phoneNumber');
    print('   Nickname: "$nickname"');  // ✅ Guillemets pour voir si vide
    print('   Notes: "$notes"');
    
    final response = await _dioClient.post(
      ApiEndpoints.contacts,
      data: {
        'phone_number': phoneNumber,
        'nickname': nickname,
        'notes': notes ?? '',
      },
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response data: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        print('✅ Contact added successfully');
        print('   Display name: ${data['data']['display_name']}');
        print('   Nickname: ${data['data']['nickname']}');
        return data['data'];
      }
    }
    
    print('⚠️ Unexpected response format');
    return null;
  } catch (e) {
    print('❌ addContact error: $e');
    rethrow;
  }
}

  // 3. Charger tous les contacts
  Future<List<Map<String, dynamic>>> getContacts({
    bool? favorites,
    bool? blocked,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (favorites != null) params['favorites'] = favorites.toString();
      if (blocked != null) params['blocked'] = blocked.toString();
      if (search != null) params['search'] = search;

      final response = await _dioClient.get(
        ApiEndpoints.contacts,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('❌ getContacts: $e');
      return [];
    }
  }

  // 4. Bloquer/débloquer
  Future<bool> toggleBlock(String contactId, bool currentlyBlocked) async {
    try {
      final endpoint = currentlyBlocked
          ? '${ApiEndpoints.contacts}$contactId/unblock/'
          : '${ApiEndpoints.contacts}$contactId/block/';

      final response = await _dioClient.post(endpoint, data: {});

      return response.statusCode == 200;
    } catch (e) {
      print('❌ toggleBlock: $e');
      return false;
    }
  }

  // 5. Toggle favoris
  Future<bool> toggleFavorite(String contactId) async {
    try {
      final response = await _dioClient.post(
        '${ApiEndpoints.contacts}$contactId/favorite/',
        data: {},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ toggleFavorite: $e');
      return false;
    }
  }

  // 6. Supprimer contact
  Future<bool> deleteContact(String contactId) async {
    try {
      final response = await _dioClient.delete(
        '${ApiEndpoints.contacts}$contactId/',
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ deleteContact: $e');
      return false;
    }
  }
}