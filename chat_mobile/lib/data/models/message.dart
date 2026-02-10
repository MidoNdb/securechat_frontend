// lib/data/models/message.dart

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? recipientUserId;
  final String? senderName;
  final String? decryptedContent;
  final String encryptedContent;
  final String? nonce;
  final String? authTag;
  final String? signature;
  final String type;
  final String? status;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.recipientUserId,
    this.senderName,
    this.decryptedContent,
    required this.encryptedContent,
    this.nonce,
    this.authTag,
    this.signature,
    this.type = 'TEXT',
    this.status,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? 
                     json['conversation']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ??
               json['from_user']?.toString() ?? '',
      recipientUserId: json['recipient_user_id']?.toString(),
      senderName: json['sender_name']?.toString(),
      encryptedContent: json['encrypted_content']?.toString() ?? '',
      nonce: json['nonce']?.toString(),
      authTag: json['auth_tag']?.toString(),
      signature: json['signature']?.toString(),
      decryptedContent: null,
      type: json['type']?.toString() ?? 'TEXT',
      status: json['status']?.toString(),
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      isRead: json['is_read'] == true,
      isDelivered: json['is_delivered'] == true,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      if (recipientUserId != null) 'recipient_user_id': recipientUserId,
      'sender_name': senderName,
      'encrypted_content': encryptedContent,
      'nonce': nonce,
      'auth_tag': authTag,
      'signature': signature,
      'type': type,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_delivered': isDelivered,
      if (metadata != null) 'metadata': metadata,
    };
  }

  Message copyWith({
    String? recipientUserId,
    String? decryptedContent,
    String? status,
    bool? isRead,
    bool? isDelivered,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      senderName: senderName,
      decryptedContent: decryptedContent ?? this.decryptedContent,
      encryptedContent: encryptedContent,
      nonce: nonce,
      authTag: authTag,
      signature: signature,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      metadata: metadata,
    );
  }
}



// // lib/data/models/message.dart

// class Message {
//   // ═══════════════════════════════════════════════════════════════
//   // IDs
//   // ═══════════════════════════════════════════════════════════════
//   final String id;  // ✅ UUID String
//   final String conversationId;  // ✅ UUID String
//   final String senderId;  // ✅ UUID String (corrigé)
  
//   // ═══════════════════════════════════════════════════════════════
//   // CONTENU
//   // ═══════════════════════════════════════════════════════════════
//   final String? senderName;
//   final String? decryptedContent;  // ✅ Contenu déchiffré (pour affichage)
  
//   // ═══════════════════════════════════════════════════════════════
//   // CHAMPS E2EE (Backend)
//   // ═══════════════════════════════════════════════════════════════
//   final String encryptedContent;  // ✅ Base64 ciphertext
//   final String? nonce;             // ✅ Base64 nonce (12 bytes)
//   final String? authTag;           // ✅ Base64 auth tag (16 bytes)
//   final String? signature;         // ✅ Base64 Ed25519 signature
  
//   // ═══════════════════════════════════════════════════════════════
//   // MÉTADONNÉES
//   // ═══════════════════════════════════════════════════════════════
//   final String type;
//   final String? status;
//   final DateTime timestamp;
//   final bool isRead;
//   final bool isDelivered;
//   final Map<String, dynamic>? metadata;

//   Message({
//     required this.id,
//     required this.conversationId,
//     required this.senderId,
//     this.senderName,
//     this.decryptedContent,
//     required this.encryptedContent,
//     this.nonce,
//     this.authTag,
//     this.signature,
//     this.type = 'TEXT',
//     this.status,
//     required this.timestamp,
//     this.isRead = false,
//     this.isDelivered = false,
//     this.metadata,
//   });

//   // ═══════════════════════════════════════════════════════════════
//   // FROM JSON (Backend)
//   // ═══════════════════════════════════════════════════════════════
//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id']?.toString() ?? '',
//       conversationId: json['conversation_id']?.toString() ?? 
//                      json['conversation']?.toString() ?? '',
//       senderId: json['sender_id']?.toString() ??   // ✅ String maintenant
//                json['from_user']?.toString() ?? '',
//       senderName: json['sender_name']?.toString(),
      
//       // ✅ Champs E2EE séparés
//       encryptedContent: json['encrypted_content']?.toString() ?? '',
//       nonce: json['nonce']?.toString(),
//       authTag: json['auth_tag']?.toString(),
//       signature: json['signature']?.toString(),
      
//       // Pas de contenu déchiffré depuis JSON (sera fait par service)
//       decryptedContent: null,
      
//       type: json['type']?.toString() ?? 'TEXT',
//       status: json['status']?.toString(),
      
//       timestamp: json['created_at'] != null
//           ? DateTime.parse(json['created_at'])
//           : json['timestamp'] != null
//               ? DateTime.parse(json['timestamp'])
//               : DateTime.now(),
      
//       isRead: json['is_read'] == true,
//       isDelivered: json['is_delivered'] == true,
//       metadata: json['metadata'] != null 
//           ? Map<String, dynamic>.from(json['metadata'])
//           : null,
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // TO JSON
//   // ═══════════════════════════════════════════════════════════════
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'conversation_id': conversationId,
//       'sender_id': senderId,
//       'sender_name': senderName,
//       'encrypted_content': encryptedContent,
//       'nonce': nonce,
//       'auth_tag': authTag,
//       'signature': signature,
//       'type': type,
//       'status': status,
//       'timestamp': timestamp.toIso8601String(),
//       'is_read': isRead,
//       'is_delivered': isDelivered,
//       if (metadata != null) 'metadata': metadata,
//     };
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // COPY WITH
//   // ═══════════════════════════════════════════════════════════════
//   Message copyWith({
//     String? decryptedContent,
//     String? status,
//     bool? isRead,
//     bool? isDelivered,
//   }) {
//     return Message(
//       id: id,
//       conversationId: conversationId,
//       senderId: senderId,
//       senderName: senderName,
//       decryptedContent: decryptedContent ?? this.decryptedContent,
//       encryptedContent: encryptedContent,
//       nonce: nonce,
//       authTag: authTag,
//       signature: signature,
//       type: type,
//       status: status ?? this.status,
//       timestamp: timestamp,
//       isRead: isRead ?? this.isRead,
//       isDelivered: isDelivered ?? this.isDelivered,
//       metadata: metadata,
//     );
//   }
// }
