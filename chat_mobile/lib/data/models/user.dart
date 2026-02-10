// lib/data/models/user.dart

class User {
  final int id;
  final String userId;
  final String phoneNumber;
  final String? phoneNumberHash;
  final String? displayName;
  final String? email;
  final String? avatar;
  final String? publicKey;
  final String? safetyNumber;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;

  User({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    this.phoneNumberHash,
    this.displayName,
    this.email,
    this.avatar,
    this.publicKey,
    this.safetyNumber,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
  });

  String get name => displayName ?? phoneNumber;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'],
      phoneNumberHash: json['phone_number_hash'],
      displayName: json['display_name'],
      email: json['email'],
      avatar: json['avatar'],
      publicKey: json['public_key'],
      safetyNumber: json['safety_number'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'phone_number_hash': phoneNumberHash,
      'display_name': displayName,
      'email': email,
      'avatar': avatar,
      'public_key': publicKey,
      'safety_number': safetyNumber,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? userId,
    String? phoneNumber,
    String? phoneNumberHash,
    String? displayName,
    String? email,
    String? avatar,
    String? publicKey,
    String? safetyNumber,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberHash: phoneNumberHash ?? this.phoneNumberHash,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      publicKey: publicKey ?? this.publicKey,
      safetyNumber: safetyNumber ?? this.safetyNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}