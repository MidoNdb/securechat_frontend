// lib/core/shared/environment.dart

enum Environment {
  LOCAL,
  STAGING,
  PRODUCTION,
}

class AppEnvironment {
  static const Environment current = Environment.LOCAL;
 
  static String get baseUrl {
    switch (current) {
      case Environment.LOCAL:
        return 'http://10.56.245.198:8000'; 
      case Environment.STAGING:
        return 'https://staging.securechat.mr';
      case Environment.PRODUCTION:
        return 'https://api.securechat.mr';
    }
  }

  static String get wsUrl {
    switch (current) {
      case Environment.LOCAL:
        return 'ws://10.56.245.198:8000'; // ⚠️ Pas de /ws/chat/ ici 
      case Environment.STAGING:
        return 'wss://staging.securechat.mr';
      case Environment.PRODUCTION:
        return 'wss://api.securechat.mr';
    }
  }


  static String get name {
    switch (current) {
      case Environment.LOCAL:
        return 'LOCAL';
      case Environment.STAGING:
        return 'STAGING';
      case Environment.PRODUCTION:
        return 'PRODUCTION';
    }
  }

  static bool get enableLogs => current != Environment.PRODUCTION;
  static bool get isDebugMode => current == Environment.LOCAL;
  static bool get isProduction => current == Environment.PRODUCTION;

  static int get apiTimeout {
    switch (current) {
      case Environment.LOCAL:
        return 60;
      default:
        return 30;
    }
  }

  static const String wsPath = '/ws/chat/';

  static String get fullWsUrl => '$wsUrl$wsPath';
}