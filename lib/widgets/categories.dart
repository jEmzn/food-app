import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categories',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SingleChildScrollView(
          padding: EdgeInsets.only(top: 15, left: 15),
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 30,
            children: [
              buildCategoriesItem(
                'assets/images/icons/meat_icon.png',
                'Fruits',
              ),
              buildCategoriesItem(
                'assets/images/icons/meat_icon.png',
                'Vegetables',
              ),
              buildCategoriesItem(
                'assets/images/icons/meat_icon.png',
                'Grains',
              ),
              buildCategoriesItem('assets/images/icons/meat_icon.png', 'Dairy'),
              buildCategoriesItem(
                'assets/images/icons/meat_icon.png',
                'Proteins',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget buildCategoriesItem(String imagePath, String title) {
  return Column(
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(38, 0, 0, 0),
              blurRadius: 15,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: CircleBorder(),
            elevation: 0,
            padding: EdgeInsets.all(0),
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: 32,
            height: 32,
          ),
        ),
      ),
      SizedBox(height: 8),
      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    ],
  );
}
