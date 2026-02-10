// lib/data/models/conversation.dart

import 'message.dart';
import 'participant.dart';
import 'package:get/get.dart';

class Conversation {
  final String id;
  final String type;
  final String? name;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final Message? lastMessage;
  final List<Participant> participants;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    required this.createdAt,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.lastMessage,
    required this.participants,
  });

  /// ✅ Vérifie si c'est un groupe
  bool get isGroup => type == 'GROUP';

  /// ✅ Obtient l'autre participant (pour conversations directes)
  Participant? otherParticipant(String currentUserId) {  // ✅ String
    if (isGroup || participants.isEmpty) return null;

    return participants.firstWhereOrNull(
      (p) => p.userId != currentUserId,
    );
  }

  /// ✅ Nom à afficher
  String displayName(String currentUserId) {  // ✅ String
    return name ?? 'Conversation';
  }

  /// ✅ Parse depuis JSON (API backend)
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DIRECT',
      
      name: json['display_name']?.toString() ?? 
            json['name']?.toString() ?? 
            'Numéro inconnu',
      
      avatar: json['avatar']?.toString(),
      
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      
      unreadCount: _parseInt(json['unread_count']),
      
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => Participant.fromJson(p))
              .toList()
          : [],
    );
  }

  /// ✅ Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'last_message': lastMessage?.toJson(),
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }

  /// ✅ Copie avec modifications
  Conversation copyWith({
    String? id,
    String? type,
    String? name,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? unreadCount,
    Message? lastMessage,
    List<Participant>? participants,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
    );
  }

  /// ✅ Helper pour parser des entiers
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

// // lib/data/models/conversation.dart

// import 'message.dart';
// import 'participant.dart';
// import 'package:get/get.dart';

// class Conversation {
//   final String id;
//   final String type;
//   final String? name;  // ✅ Contient display_name du backend (nickname OU numéro)
//   final String? avatar;
//   final DateTime createdAt;
//   final DateTime? lastMessageAt;
//   final int unreadCount;
//   final Message? lastMessage;
//   final List<Participant> participants;

//   Conversation({
//     required this.id,
//     required this.type,
//     this.name,
//     this.avatar,
//     required this.createdAt,
//     this.lastMessageAt,
//     this.unreadCount = 0,
//     this.lastMessage,
//     required this.participants,
//   });

//   /// ✅ Vérifie si c'est un groupe
//   bool get isGroup => type == 'GROUP';

//   /// ✅ Obtient l'autre participant (pour conversations directes)
//   Participant? otherParticipant(int currentUserId) {
//     if (isGroup || participants.isEmpty) return null;

//     return participants.firstWhereOrNull(
//       (p) => p.userId != currentUserId,
//     );
//   }

//   /// ✅ Nom à afficher (déjà géré par le backend)
//   String displayName(int currentUserId) {
//     // Le backend envoie déjà display_name dans le champ "name"
//     // donc on le retourne directement
//     return name ?? 'Conversation';
//   }

//   /// ✅ Parse depuis JSON (API backend)
//   factory Conversation.fromJson(Map<String, dynamic> json) {
//     return Conversation(
//       id: json['id']?.toString() ?? '',
//       type: json['type']?.toString() ?? 'DIRECT',
      
//       // ✅ Le backend envoie display_name (nickname OU numéro)
//       name: json['display_name']?.toString() ?? 
//             json['name']?.toString() ?? 
//             'Numéro inconnu',
      
//       avatar: json['avatar']?.toString(),
      
//       createdAt: json['created_at'] != null
//           ? DateTime.parse(json['created_at'])
//           : DateTime.now(),
      
//       lastMessageAt: json['last_message_at'] != null
//           ? DateTime.parse(json['last_message_at'])
//           : null,
      
//       unreadCount: _parseInt(json['unread_count']),
      
//       lastMessage: json['last_message'] != null
//           ? Message.fromJson(json['last_message'])
//           : null,
      
//       participants: json['participants'] != null
//           ? (json['participants'] as List)
//               .map((p) => Participant.fromJson(p))
//               .toList()
//           : [],
//     );
//   }

//   /// ✅ Convertit en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'type': type,
//       'name': name,
//       'avatar': avatar,
//       'created_at': createdAt.toIso8601String(),
//       'last_message_at': lastMessageAt?.toIso8601String(),
//       'unread_count': unreadCount,
//       'last_message': lastMessage?.toJson(),
//       'participants': participants.map((p) => p.toJson()).toList(),
//     };
//   }

//   /// ✅ Copie avec modifications
//   Conversation copyWith({
//     String? id,
//     String? type,
//     String? name,
//     String? avatar,
//     DateTime? createdAt,
//     DateTime? lastMessageAt,
//     int? unreadCount,
//     Message? lastMessage,
//     List<Participant>? participants,
//   }) {
//     return Conversation(
//       id: id ?? this.id,
//       type: type ?? this.type,
//       name: name ?? this.name,
//       avatar: avatar ?? this.avatar,
//       createdAt: createdAt ?? this.createdAt,
//       lastMessageAt: lastMessageAt ?? this.lastMessageAt,
//       unreadCount: unreadCount ?? this.unreadCount,
//       lastMessage: lastMessage ?? this.lastMessage,
//       participants: participants ?? this.participants,
//     );
//   }

//   /// ✅ Helper pour parser des entiers
//   static int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
// }