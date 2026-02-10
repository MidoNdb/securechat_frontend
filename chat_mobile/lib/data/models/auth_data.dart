// lib/data/models/auth_data.dart

class AuthData {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String deviceId;
  final String dhPrivateKey;
  final String signPrivateKey;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.deviceId,
    required this.dhPrivateKey,
    required this.signPrivateKey,
  });

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user_id': userId,
    'device_id': deviceId,
    'dh_private_key': dhPrivateKey,
    'sign_private_key': signPrivateKey,
  };

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
    accessToken: json['access_token'],
    refreshToken: json['refresh_token'],
    userId: json['user_id'],
    deviceId: json['device_id'],
    dhPrivateKey: json['dh_private_key'],
    signPrivateKey: json['sign_private_key'],
  );
}


// // lib/models/auth_data.dart
// class AuthData {
//   final String accessToken;
//   final String refreshToken;
//   final String userId;
//   final String deviceId;
//   final String privateKey;

//   AuthData({
//     required this.accessToken,
//     required this.refreshToken,
//     required this.userId,
//     required this.deviceId,
//     required this.privateKey,
//   });

//   // Conversion vers JSON pour stockage
//   Map<String, String> toMap() {
//     return {
//       'access_token': accessToken,
//       'refresh_token': refreshToken,
//       'user_id': userId,
//       'device_id': deviceId,
//       'private_key': privateKey,
//     };
//   }

//   // Création depuis JSON
//   factory AuthData.fromMap(Map<String, String> map) {
//     return AuthData(
//       accessToken: map['access_token']!,
//       refreshToken: map['refresh_token']!,
//       userId: map['user_id']!,
//       deviceId: map['device_id']!,
//       privateKey: map['private_key']!,
//     );
//   }
// }