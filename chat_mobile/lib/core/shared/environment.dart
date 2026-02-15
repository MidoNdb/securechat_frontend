// lib/core/shared/environment.dart

enum Environment {
  LOCAL,
  STAGING,
  PRODUCTION,
}

class AppEnvironment {
  static const Environment current = Environment.PRODUCTION; // Changez cette valeur pour switcher d'environnement
 
  static String get baseUrl {
    switch (current) {
      case Environment.LOCAL:
        return 'http://172.16.182.17:8000'; //10.0.2.2 pour émulateur Android,-- 10.79.164.64
      case Environment.STAGING:
        return 'https://securechabackend-production.up.railway.app';
      case Environment.PRODUCTION:
        return 'https://securechabackend-production.up.railway.app';
    }
  }

  static String get wsUrl {
    switch (current) {
      case Environment.LOCAL:
        return 'ws://172.16.182.17:8000'; //  Pas de /ws/chat/ ici 
      case Environment.STAGING:
        return 'wss://securechabackend-production.up.railway.app';
      case Environment.PRODUCTION:
        return 'wss://securechabackend-production.up.railway.app';
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