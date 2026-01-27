import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'config/routes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      initialRoute: '/',
      routes: AppRoutes.getRoutes(),
    );
  }
}
