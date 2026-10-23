import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/student_gate.dart';
import 'screens/setup_required_screen.dart';
import 'screens/splash_screen.dart';

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUT Clinic',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AppConfig.isConfigured
          ? const AppRoot()
          : const SetupRequiredScreen(),
    );
  }
}

/// Signed-out users see the Get Started page first; returning users go
/// straight in. The login screen has a back arrow to return to Get Started.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late bool _showSplash = Supabase.instance.client.auth.currentSession == null;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onContinue: () => setState(() => _showSplash = false));
    }
    return AuthGate(onBackToWelcome: () => setState(() => _showSplash = true));
  }
}

/// Shows the login screen when signed out, otherwise the student area.
/// FR4, FR7, NFR1.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.onBackToWelcome});

  /// Called when the student taps the back arrow on the login screen.
  final VoidCallback? onBackToWelcome;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return LoginScreen(onBack: onBackToWelcome);
        return StudentGate(key: ValueKey(session.user.id));
      },
    );
  }
}