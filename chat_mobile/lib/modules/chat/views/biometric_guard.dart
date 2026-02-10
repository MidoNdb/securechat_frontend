
import 'package:chat_mobile/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/biometric_service.dart';
import '../../../data/services/auth_service.dart';
import 'main_shell_view.dart';

class BiometricGuard extends StatefulWidget {
  const BiometricGuard({Key? key}) : super(key: key);

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard> with WidgetsBindingObserver {
  final BiometricService _biometric = Get.find<BiometricService>();
  final AuthService _auth = Get.find<AuthService>();
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  DateTime? _lastAuthenticationTime;
  DateTime? _lastPausedTime;  // ✅ NOUVEAU: Timestamp de la mise en pause
  bool _isAuthenticating = false;
  
  // ✅ Délai avant de redemander auth (en secondes)
  static const int _reAuthDelaySeconds = 60;  // 1 minute
  static const int _pauseThresholdSeconds = 3;  // 3 secondes de pause minimum

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticateUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('📱 Lifecycle: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
        // ✅ App mise en pause (arrière-plan)
        _lastPausedTime = DateTime.now();
        print('⏸️ App paused at: $_lastPausedTime');
        break;
        
      case AppLifecycleState.resumed:
        // ✅ App revenue au premier plan
        _handleAppResumed();
        break;
        
      default:
        break;
    }
  }

  void _handleAppResumed() {
    final now = DateTime.now();
    
    // 1. Vérifier si on a une authentification récente (< 60s)
    if (_lastAuthenticationTime != null) {
      final timeSinceAuth = now.difference(_lastAuthenticationTime!);
      
      if (timeSinceAuth.inSeconds < _reAuthDelaySeconds) {
        print('⏭️ Auth récente (${timeSinceAuth.inSeconds}s) - Ignorer');
        _lastPausedTime = null;  // Reset pause timestamp
        return;
      }
    }
    
    // 2. Vérifier si l'app a vraiment été en pause (pas juste navigation)
    if (_lastPausedTime != null) {
      final pauseDuration = now.difference(_lastPausedTime!);
      
      if (pauseDuration.inSeconds < _pauseThresholdSeconds) {
        print('⏭️ Pause courte (${pauseDuration.inSeconds}s) - Navigation interne, ignorer');
        _lastPausedTime = null;
        return;
      }
      
      print('🔐 App en pause pendant ${pauseDuration.inSeconds}s - Redemander auth');
    }
    
    // 3. Redemander authentification si pas déjà en cours
    if (!_isAuthenticating && !_isLoading) {
      print('🔐 App resumed - Redemander authentification');
      setState(() {
        _isAuthenticated = false;
        _isLoading = true;
      });
      _authenticateUser();
    }
    
    _lastPausedTime = null;  // Reset pause timestamp
  }

  Future<void> _authenticateUser() async {
    if (_isAuthenticating) {
      print('⏭️ Authentification déjà en cours - Ignorer');
      return;
    }
    
    setState(() => _isAuthenticating = true);
    
    final result = await _biometric.authenticateWithFallback();
    
    switch (result) {
      case BiometricResult.success:
        _lastAuthenticationTime = DateTime.now();
        
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
          _isAuthenticating = false;
        });
        
        print('✅ Authentification complète - MainShellView affiché');
        break;
        
      case BiometricResult.notAvailable:
        _lastAuthenticationTime = DateTime.now();
        
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
          _isAuthenticating = false;
        });
        
        _showBiometricNotAvailableDialog();
        break;
        
      case BiometricResult.notConfigured:
        setState(() {
          _isLoading = false;
          _isAuthenticating = false;
        });
        _showConfigureBiometricDialog();
        break;
        
      case BiometricResult.failed:
        setState(() {
          _isLoading = false;
          _isAuthenticating = false;
        });
        _showAuthenticationFailedDialog();
        break;
        
      case BiometricResult.error:
        _lastAuthenticationTime = DateTime.now();
        
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
          _isAuthenticating = false;
        });
        break;
    }
  }

  void _showBiometricNotAvailableDialog() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      Get.dialog(
        AlertDialog(
          title: const Text('Biométrie non disponible'),
          content: const Text(
            'Votre appareil ne supporte pas la biométrie.\n\n'
            'L\'application reste sécurisée par votre mot de passe.'
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    });
  }

  void _showConfigureBiometricDialog() {
    if (!mounted) return;
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Configurer la biométrie'),
          content: const Text(
            'Votre appareil supporte la biométrie mais elle n\'est pas configurée.\n\n'
            'Pour plus de sécurité, configurez votre empreinte digitale dans les paramètres Android.'
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Get.back();
                await _auth.logout();
                Get.offAllNamed(AppRoutes.LOGIN);
              },
              child: const Text('Se déconnecter'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _lastAuthenticationTime = DateTime.now();
                setState(() {
                  _isAuthenticated = true;
                  _isLoading = false;
                });
              },
              child: const Text('Continuer sans biométrie'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showAuthenticationFailedDialog() {
    if (!mounted) return;
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Authentification échouée'),
          content: const Text(
            'L\'authentification biométrique a échoué ou a été annulée.'
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Get.back();
                await _auth.logout();
                Get.offAllNamed(AppRoutes.LOGIN);
              },
              child: const Text('Se déconnecter'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                setState(() => _isLoading = true);
                _authenticateUser();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 80,
                color: Color(0xFF667eea),
              ),
              SizedBox(height: 30),
              Text(
                'Authentification biométrique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Scannez votre empreinte',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(
                color: Color(0xFF667eea),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'Accès refusé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await _auth.logout();
                  Get.offAllNamed(AppRoutes.LOGIN);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      );
    }
    
    return MainShellView();
  }
}

