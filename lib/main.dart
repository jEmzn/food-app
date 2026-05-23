import 'package:app1/config/app_theme.dart';
import 'package:app1/screens/main_screen.dart';
import 'package:app1/screens/auth/onboarding_screen.dart';
import 'package:app1/screens/welcome_screen.dart';
import 'package:app1/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  ThemeData get theme => AppTheme.themeData;

  @override
  Widget build(BuildContext context) {
    // Drop the '/' entry from routes — `home` takes that slot, and
    // MaterialApp asserts when both are set.
    final routes = Map<String, WidgetBuilder>.from(AppRoutes.getRoutes())
      ..remove(AppRoutes.initialRoute);
    return MaterialApp(
      title: 'Food App',
      home: const _Bootstrap(),
      routes: routes,
      theme: theme,
    );
  }
}

/// Decides the first screen on cold start. Signed-in users with missing or
/// incomplete body metrics are routed to onboarding instead of the main app.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  Future<Widget> _resolveStart() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return const WelcomeScreen();
    }
    try {
      final metrics = await AuthService.fetchBodyMetrics();
      if (AuthService.bodyMetricsNeedOnboarding(metrics)) {
        return const OnboardingScreen();
      }
    } catch (_) {
      // Network/auth failure: fall through to MainScreen — home screen
      // shows a graceful empty state when metrics aren't available.
    }
    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveStart(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
