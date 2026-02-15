// lib/app/routes/app_pages.dart

import 'package:chat_mobile/app/routes/app_routes.dart';
import 'package:chat_mobile/data/models/conversation.dart';
import 'package:chat_mobile/modules/auth/auth_binding.dart';
import 'package:chat_mobile/modules/auth/views/login_view.dart';
import 'package:chat_mobile/modules/auth/views/register_view.dart';
import 'package:chat_mobile/modules/chat/calls_binding.dart';
import 'package:chat_mobile/modules/chat/controllers/chat_controller.dart';
import 'package:chat_mobile/modules/chat/views/biometric_guard.dart';
import 'package:chat_mobile/modules/chat/views/calls_view.dart';
import 'package:chat_mobile/modules/chat/views/chat_view.dart';
import 'package:chat_mobile/modules/chat/views/contacts_view.dart';
import 'package:chat_mobile/modules/chat/views/main_shell_view.dart';
import 'package:chat_mobile/modules/chat/views/profile_view.dart';
import 'package:chat_mobile/modules/chat/views/settings_view.dart';
import 'package:chat_mobile/modules/splash/splash_binding.dart';
import 'package:chat_mobile/modules/splash/splash_view.dart';
import 'package:get/get.dart';
import '../../modules/chat/chat_binding.dart';

class AppPages {
  static const INITIAL = AppRoutes.MAIN_SHELL;
  static final routes = [
     GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.MAIN_SHELL,
      page: () => const MainShellView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.INITIAL,
      page: () => const BiometricGuard(), // Wrapper avec biométrie
      binding: ChatBinding(),
      //  Supprimer BiometricMiddleware si tu l'avais
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.noTransition, // Pas d'animation pour le login
    ),
    
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    
   
   GetPage(
      name: AppRoutes.CONTACTS,
      page: () => ContactsView(),
      binding: ChatBinding(),
    ),
     GetPage(
      name: AppRoutes.CALLS,
      page: () => const CallsView(),
      binding: CallsBinding(), // Binding dédié pour les appels
    ),
    

    GetPage(
      name: AppRoutes.CHAT,
      page: () => ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(name: AppRoutes.CALLS, page: () => CallsView(), binding: ChatBinding()),
    GetPage(name: AppRoutes.SETTINGS, page: () => SettingsView(), binding: ChatBinding()),
    GetPage(name: AppRoutes.PROFILE, page: () => ProfileView(), binding: ChatBinding())
    // Ajouter les autres routes ici
  ];
}


