import 'package:app1/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

class CategoriesBar extends StatefulWidget {
  const CategoriesBar({super.key});

  @override
  State<CategoriesBar> createState() => _CategoriesBarState();
}

class _CategoriesBarState extends State<CategoriesBar> {
  int _selectedIndex = 0;

  final List<String> _categories = [
    'All',
    'Carbs',
    'Proteins',
    'Fats',
    'Vitamins',
    'Minerals',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: List.generate(_categories.length, (index) {
          return _buildCategoryItem(_categories[index], index);
        }),
      ),
    );
  }

  Widget _buildCategoryItem(String categoryName, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 203, 247, 48)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? buttonColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/icons/meat_icon.png',
              width: 16,
              height: 16,
            ),
            SizedBox(width: 4),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
