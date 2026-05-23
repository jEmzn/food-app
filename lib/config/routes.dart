import 'package:flutter/material.dart';
import 'package:app1/screens/welcome_screen.dart';
import 'package:app1/screens/auth/onboarding_screen.dart';
import 'package:app1/screens/main_screen.dart';
import 'package:app1/screens/profile/profile_info_screen.dart';
import 'package:app1/screens/profile/history_screen.dart';
import 'package:app1/screens/profile/rate_app_screen.dart';
import 'package:app1/screens/profile/settings_screen.dart';
import 'package:app1/screens/profile/help_support_screen.dart';
import 'package:app1/screens/profile/about_screen.dart';

class AppRoutes {
  static const String initialRoute = '/';
  static const String onboardRoute = '/auth/onboard';
  static const String mainRoute = '/main';

  // Profile-section routes
  static const String profileInfoRoute = '/profile/info';
  static const String historyRoute = '/profile/history';
  static const String rateAppRoute = '/profile/rate';
  static const String settingsRoute = '/profile/settings';
  static const String helpRoute = '/profile/help';
  static const String aboutRoute = '/profile/about';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      initialRoute: (context) => const WelcomeScreen(),
      onboardRoute: (context) => const OnboardingScreen(),
      mainRoute: (context) => const MainScreen(),
      profileInfoRoute: (context) => const ProfileInfoScreen(),
      historyRoute: (context) => const HistoryScreen(),
      rateAppRoute: (context) => const RateAppScreen(),
      settingsRoute: (context) => const SettingsScreen(),
      helpRoute: (context) => const HelpSupportScreen(),
      aboutRoute: (context) => const AboutScreen(),
    };
  }
}
