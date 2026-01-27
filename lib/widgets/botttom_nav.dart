import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  static const Color primaryColor = Color(0xFF73CA31);
  static const Color shadowColor = Color.fromARGB(38, 0, 0, 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50, left: 24, right: 24),
      child: Container(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(100)),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 15,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  onItemTapped(0);
                },
                icon: Icon(
                  Icons.home_outlined,
                  size: 28,
                  color: selectedIndex == 0 ? primaryColor : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () {
                  onItemTapped(1);
                },
                icon: Icon(
                  Icons.favorite_border,
                  size: 28,
                  color: selectedIndex == 1 ? primaryColor : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () {
                  onItemTapped(2);
                },
                icon: Icon(
                  Icons.calendar_today_outlined,
                  size: 28,
                  color: selectedIndex == 2 ? primaryColor : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () {
                  onItemTapped(3);
                },
                icon: Icon(
                  Icons.person_outline,
                  size: 28,
                  color: selectedIndex == 3 ? primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedScreenIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF73CA31),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF73CA31)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite, color: Color(0xFF73CA31)),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(
                Icons.calendar_today,
                color: Color(0xFF73CA31),
              ),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF73CA31)),
              label: 'Profile',
            ),
          ],
        ),
      ), */
