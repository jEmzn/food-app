import 'package:flutter/material.dart';
import 'package:app1/widgets/botttom_nav.dart';
import 'package:app1/screens/home_screen.dart';
import 'package:app1/screens/favorites_screen.dart';
import 'package:app1/screens/stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedScreenIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoriteScreen(),
    const StatsScreen(),
    Center(child: Text('Profile Screen')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body:
          _screens[_selectedScreenIndex < _screens.length
              ? _selectedScreenIndex
              : 0],
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedScreenIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
