

import '../../core/shared/environment.dart';

class ApiEndpoints {
  static String get baseUrl => AppEnvironment.baseUrl;
  static String get wsUrl => AppEnvironment.wsUrl;

  // AUTH
  static const String register = '/api/auth/register/';
  static const String login = '/api/auth/login/';
  static const String logout = '/api/auth/logout/';
  static const String me = '/api/auth/me/';
  static const String updateKeys = '/api/auth/update-keys/';

  // Dans ta classe ApiEndpoints, ajoute:

static String sendOtp() => '/api/auth/send-otp/';
static String verifyOtp() => '/api/auth/verify-otp/';


  // CONTACTS
  static const String contacts = '/api/contacts/';
  static const String searchContacts = '/api/contacts/search/';
  
  // CONVERSATIONS
  static const String conversations = '/api/conversations/';
  static const String createConversation = '/api/conversations/';
  
  // MESSAGES
  static const String messages = '/api/messages/';
  static const String sendMessage = '/api/messages/'; 
  static const String markAsRead = '/api/messages/mark-read/';
  static String getMessagesByConversation(String conversationId) {
    return '/api/messages/conversation/$conversationId/';  
  }
  

  
  // HELPERS
  static String getUserPublicKeys(int userId) => '/api/users/$userId/public-keys/';

  static const String uploadPublicKeys = '/api/users/public-keys/';
   
  static String getPublicKeys(String userId) => '/api/users/$userId/public-keys/';
  
  
  static String conversationDetail(String id) => '/api/conversations/$id/';
  static String conversationMessages(String id) => '/api/messages/conversation/$id/';
  
  static const String markRead = '/api/messages/mark-read/';
  static String messageDetail(String id) => '/api/messages/$id/';
  
  static String contactDetail(String id) => '/api/contacts/$id/';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const int wsMaxReconnectAttempts = 5;
  static const Duration wsPingInterval = Duration(seconds: 30);
  

  // Backup des clés privées
  static const String uploadEncryptedKeys = '/api/auth/backup-keys/upload/';
  static const String downloadEncryptedKeys = '/api/auth/backup-keys/download/';
}

