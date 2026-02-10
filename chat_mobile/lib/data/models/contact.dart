// lib/data/models/contact.dart

class Contact {
  final int id;
  final int userId;
  final int contactUserId;
  final String? contactUserName;
  final String? contactUserAvatar;
  final String? contactUserPhone;
  final bool isMarked;
  final bool isBlocked;
  final DateTime addedAt;

  Contact({
    required this.id,
    required this.userId,
    required this.contactUserId,
    this.contactUserName,
    this.contactUserAvatar,
    this.contactUserPhone,
    this.isMarked = false,
    this.isBlocked = false,
    required this.addedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      userId: json['user_id'],
      contactUserId: json['contact_user_id'],
      contactUserName: json['contact_user_name'],
      contactUserAvatar: json['contact_user_avatar'],
      contactUserPhone: json['contact_user_phone'],
      isMarked: json['is_marked'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_user_id': contactUserId,
      'contact_user_name': contactUserName,
      'contact_user_avatar': contactUserAvatar,
      'contact_user_phone': contactUserPhone,
      'is_marked': isMarked,
      'is_blocked': isBlocked,
      'added_at': addedAt.toIso8601String(),
    };
  }
}