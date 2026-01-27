import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodsCard extends StatelessWidget {
  const FoodsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return
    // color: Colors,
    SingleChildScrollView(
      padding: EdgeInsets.only(left: 24, top: 15, bottom: 15),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildFoodsCard('assets/images/food_image.png', 'Apple', '95', () {}),

          buildFoodsCard(
            'assets/images/food_image.png',
            'Banana',
            '105',
            () {},
          ),
          // SizedBox(width: 15),
          buildFoodsCard('assets/images/food_image.png', 'Orange', '62', () {}),
          buildFoodsCard('assets/images/food_image.png', 'Orange', '62', () {}),
        ],
      ),
    );
  }
}

Widget buildFoodsCard(
  String imagePath,
  String title,
  String kcal,
  VoidCallback onPressed,
) {
  return Container(
    padding: const EdgeInsets.only(left: 10, right: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Color.fromARGB(20, 0, 0, 0),
          blurRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size(60, 60),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.all(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Container(
            // color: Colors.white,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(38, 0, 0, 0),
                  blurRadius: 15,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Text('$kcal kcal'),
          ),
          Image.asset(imagePath, height: 220, width: 220),
        ],
      ),
    ),
  );
}
