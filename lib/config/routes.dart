import 'package:flutter/material.dart';
import 'package:app1/screens/welcome_screen.dart';
import 'package:app1/screens/home_screen.dart';
import 'package:app1/screens/auth/onboarding_screen.dart';
import 'package:app1/screens/favorites_screen.dart';
import 'package:app1/screens/main_screen.dart';

class AppRoutes {
  static const String initialRoute = '/';
  // static const String homeRoute = '/home';
  static const String onboardRoute = '/auth/onboard';
  // static const String favoriteRoute = '/favorites';
  static const String mainRoute = '/main';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      initialRoute: (context) => const WelcomeScreen(),
      // homeRoute: (context) => const HomeScreen(),
      onboardRoute: (context) => const OnboardingScreen(),
      // favoriteRoute: (context) => const FavoriteScreen()
      mainRoute: (context) => const MainScreen(),
    };
  }
}
