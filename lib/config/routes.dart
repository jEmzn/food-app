import 'package:flutter/material.dart';
import 'package:app1/screens/welcome_screen.dart';
import 'package:app1/screens/home_screen.dart';

class AppRoutes {
  static const String initialRoute = '/';
  static const String homeRoute = '/home';
  
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      initialRoute: (context) => const WelcomeScreen(),
      homeRoute: (context) => const HomeScreen(), 

    };
  }
}