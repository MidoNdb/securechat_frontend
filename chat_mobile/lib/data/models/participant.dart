// lib/data/models/participant.dart

class Participant {
  final String userId;  // ✅ String UUID (corrigé de int)
  final String phoneNumber;
  final String? avatar;
  final String role;

  Participant({
    required this.userId,
    required this.phoneNumber,
    this.avatar,
    required this.role,
  });

  /// ✅ Parse depuis JSON (API backend)
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id']?.toString() ?? '',  // ✅ String
      phoneNumber: json['phone_number']?.toString() ?? 'Inconnu',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'member',
    );
  }

  /// ✅ Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'role': role,
    };
  }
}

// // lib/data/models/participant.dart

// class Participant {
//   final int userId;
//   final String phoneNumber;  // ✅ Numéro de téléphone au lieu de displayName
//   final String? avatar;
//   final String role;

//   Participant({
//     required this.userId,
//     required this.phoneNumber,
//     this.avatar,
//     required this.role,
//   });

//   /// ✅ Parse depuis JSON (API backend)
//   factory Participant.fromJson(Map<String, dynamic> json) {
//     return Participant(
//       userId: _parseInt(json['user_id']),
//       phoneNumber: json['phone_number']?.toString() ?? 'Inconnu',
//       avatar: json['avatar']?.toString(),
//       role: json['role']?.toString() ?? 'member',
//     );
//   }

//   /// ✅ Convertit en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'user_id': userId,
//       'phone_number': phoneNumber,
//       'avatar': avatar,
//       'role': role,
//     };
//   }

//   /// ✅ Helper pour parser des entiers
//   static int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
// }