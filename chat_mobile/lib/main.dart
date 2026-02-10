// lib/main.dart

import 'package:chat_mobile/data/services/contact_service.dart';
import 'package:chat_mobile/data/services/file_service.dart';
import 'package:chat_mobile/data/services/image_message_service.dart';
import 'package:chat_mobile/data/services/voice_message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screen_protector/screen_protector.dart'; // ✅ AJOUTÉ
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
import 'package:intl/date_symbol_data_local.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  
  // ✅ PROTECTION ANTI-CAPTURE (Android + iOS)
  try {
    await ScreenProtector.preventScreenshotOn();
    print('🔒 Protection anti-capture activée');
  } catch (e) {
    print('⚠️ Erreur protection écran: $e');
  }
  
  await initCriticalServices();
  
  final authService = Get.find<AuthService>();
  final isAuthenticated = await authService.isAuthenticated();
  
  runApp(MyApp(isAuthenticated: isAuthenticated));
}

Future<void> initCriticalServices() async {
  // 1. SecureStorage (doit être premier)
  await Get.putAsync(() async {
    final service = SecureStorageService();
    await service.init();
    return service;
  }, permanent: true);
  
  // 2. DioClient (API)
  await Get.putAsync(() async {
    final service = DioClient();
    await service.init();
    return service;
  }, permanent: true);
  
  await Get.putAsync(() async {
    final service = WebSocketService();
    return service;
  }, permanent: true);
  
  // 3. AuthService
  Get.put(AuthService(), permanent: true);
  Get.put(CryptoService(), permanent: true);
   
  // 4. BiometricService
  Get.put(BiometricService(), permanent: true);
  
  // 6. MessageService (dépend de Storage + DioClient + Crypto)
  Get.put(MessageService(), permanent: true);
  Get.put(FileService(), permanent: true);
  Get.put(ContactService(), permanent: true);
  Get.put(ImageMessageService(), permanent: true);
  Get.put(VoiceMessageService(), permanent: true);
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