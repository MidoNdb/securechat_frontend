// lib/data/api/api_interceptors.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../services/secure_storage_service.dart';
import '../../core/shared/environment.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final storage = Get.find<SecureStorageService>();
      // getAccessToken() retourne depuis le cache mémoire si disponible
      // Pas d'accès au KeyStore Android à chaque requête
      final token = await storage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final storage = Get.find<SecureStorageService>();
        await storage.clearAuth();
        Get.offAllNamed('/login');
      } catch (_) {}
    }

    handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppEnvironment.enableLogs) {
      final sanitized = options.data != null ? _sanitizeData(options.data) : '';
      debugPrint('[API] ${options.method} ${options.path} $sanitized');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppEnvironment.enableLogs) {
      debugPrint('[API] ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppEnvironment.enableLogs) {
      debugPrint('[API] ERROR ${err.response?.statusCode ?? "NO_STATUS"} ${err.requestOptions.path}');
    }
    handler.next(err);
  }

  dynamic _sanitizeData(dynamic data) {
    if (data is! Map<String, dynamic>) return '';

    final sanitized = Map<String, dynamic>.from(data);
    const sensitiveKeys = [
      'password', 'public_key', 'private_key',
      'encrypted_private_key', 'token', 'refresh_token',
      'access_token', 'encrypted_content', 'signature',
      'nonce', 'auth_tag',
    ];

    sanitized.forEach((key, value) {
      if (sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
        sanitized[key] = value is String && value.length > 20
            ? '${value.substring(0, 8)}...[${value.length}]'
            : '***';
      }
    });

    return sanitized;
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 déjà géré par AuthInterceptor
    if (err.response?.statusCode == 401) {
      handler.next(err);
      return;
    }

    String title;
    String message;

    if (err.response != null) {
      switch (err.response!.statusCode) {
        case 400:
          title = 'Données invalides';
          message = _extractMessage(err.response!.data) ?? 'Vérifiez les informations';
          break;
        case 403:
          title = 'Accès refusé';
          message = 'Permissions insuffisantes';
          break;
        case 404:
          title = 'Introuvable';
          message = 'Ressource non trouvée';
          break;
        case 500:
          title = 'Erreur serveur';
          message = 'Réessayez plus tard';
          break;
        default:
          title = 'Erreur ${err.response!.statusCode}';
          message = _extractMessage(err.response!.data) ?? 'Erreur inattendue';
      }
    } else {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
          title = 'Délai dépassé';
          message = 'Connexion trop lente';
          break;
        case DioExceptionType.connectionError:
          title = 'Pas de connexion';
          message = 'Vérifiez votre connexion Internet';
          break;
        default:
          title = 'Erreur réseau';
          message = 'Impossible de contacter le serveur';
      }
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
      colorText: Get.theme.colorScheme.error,
      icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.error),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );

    handler.next(err);
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map<String, dynamic>) {
        return data['error']?['message'] ??
            data['message'] ??
            data['detail'] ??
            data['msg'];
      }
      if (data is String) return data;
    } catch (_) {}
    return null;
  }
}





