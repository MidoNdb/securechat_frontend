// lib/data/models/participant.dart

class Participant {
  final String userId;  
  final String phoneNumber;
  final String? avatar;
  final String role;

  Participant({
    required this.userId,
    required this.phoneNumber,
    this.avatar,
    required this.role,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id']?.toString() ?? '',  // ✅ String
      phoneNumber: json['phone_number']?.toString() ?? 'Inconnu',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'role': role,
    };
  }
}
