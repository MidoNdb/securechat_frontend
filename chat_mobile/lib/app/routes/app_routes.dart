abstract class AppRoutes {
 
  static const String SPLASH = '/splash';
  static const String ONBOARDING = '/onboarding';
  static const String LOGIN = '/login';
  static const String REGISTER = '/register';
  static const String RESTORE = '/restore';
  static const String VERIFY_SMS = '/verify-sms';
  static const String FORGOT_PASSWORD = '/forgot-password';
  static const String RESET_PASSWORD = '/reset-password';

  static const String INITIAL = '/';
  static const String MAIN_SHELL = '/main'; 
  
  static const String CHAT = '/chat'; 
  static const String NEW_CONVERSATION = '/new-conversation';

  static const String CONTACTS = '/contacts';
  static const String CONTACT_DETAIL = '/contact-detail';
  static const String ADD_CONTACT = '/add-contact';
  static const String SCAN_QR = '/scan-qr';
  static const String MY_QR = '/my-qr';
  static const String BLOCKED_CONTACTS = '/blocked-contacts';

  static const String CALLS = '/calls';
  static const String CALL_SCREEN = '/call-screen';
  static const String CALL_HISTORY = '/call-history';

  // ========================================
  // GROUPS
  // ========================================
  static const String CREATE_GROUP = '/create-group';
  static const String GROUP_DETAIL = '/group-detail';
  static const String GROUP_SETTINGS = '/group-settings';
  static const String GROUP_MEMBERS = '/group-members';
  static const String ADD_GROUP_MEMBERS = '/add-group-members';

  // ========================================
  // MEDIA
  // ========================================
  static const String MEDIA_VIEWER = '/media-viewer';
  static const String IMAGE_PICKER = '/image-picker';
  static const String CAMERA = '/camera';
  static const String VIDEO_PLAYER = '/video-player';

  // ========================================
  // PROFILE & SETTINGS
  // ========================================
  static const String PROFILE = '/profile';
  static const String PROFILE_EDIT = '/edit-profile';
  static const String SETTINGS = '/settings';
  static const String PRIVACY_SETTINGS = '/privacy-settings';
  static const String NOTIFICATION_SETTINGS = '/notification-settings';
  static const String CHAT_SETTINGS = '/chat-settings';
  static const String STORAGE_SETTINGS = '/storage-settings';
  static const String SECURITY_SETTINGS = '/security-settings';
  static const String CHANGE_PASSWORD = '/change-password';
  static const String LANGUAGE_SETTINGS = '/language-settings';
  static const String THEME_SETTINGS = '/theme-settings';

  // ========================================
  // SECURITY
  // ========================================
  static const String SAFETY_NUMBER = '/safety-number';
  static const String VERIFY_SAFETY_NUMBER = '/verify-safety-number';

  // ========================================
  // OTHERS
  // ========================================
  static const String ABOUT = '/about';
  static const String HELP = '/help';
  static const String TERMS = '/terms';
  static const String PRIVACY_POLICY = '/privacy-policy';
}