import 'package:app1/config/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'package:app1/data/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void dispose() {
    AppDatabase.instance.close();
    super.dispose();
  }

  ThemeData get theme => AppTheme.themeData;

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Food App',
      initialRoute: '/',
      routes: AppRoutes.getRoutes(),
      theme: theme,
    );
  }
}
