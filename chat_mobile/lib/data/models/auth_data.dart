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
