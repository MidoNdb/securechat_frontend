// lib/main.dart

import 'package:chat_mobile/data/services/contact_service.dart';
import 'package:chat_mobile/data/services/file_service.dart';
import 'package:chat_mobile/data/services/image_message_service.dart';
import 'package:chat_mobile/data/services/voice_message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/initial_binding.dart';
import 'app/app_theme.dart';
import 'data/services/secure_storage_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/biometric_service.dart';
import 'data/services/crypto_service.dart';
import 'data/services/message_service.dart';
import 'data/services/websocket_service.dart';
import 'data/api/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initCriticalServices();

  final authService = Get.find<AuthService>();
  final isAuthenticated = await authService.isAuthenticated();

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

Future<void> initCriticalServices() async {
  await Get.putAsync(() async {
    final service = SecureStorageService();
    await service.init();
    return service;
  }, permanent: true);

  await Future.wait([
    Get.putAsync(() async {
      final service = DioClient();
      await service.init();
      return service;
    }, permanent: true),
    Get.putAsync(() async {
      return WebSocketService();
    }, permanent: true),
  ]);

  Get.put(CryptoService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(BiometricService(), permanent: true);
  Get.put(MessageService(), permanent: true);

  Get.lazyPut(() => FileService(), fenix: true);
  Get.lazyPut(() => ContactService(), fenix: true);
  Get.lazyPut(() => ImageMessageService(), fenix: true);
  Get.lazyPut(() => VoiceMessageService(), fenix: true);
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SecureChat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
    );
  }
}