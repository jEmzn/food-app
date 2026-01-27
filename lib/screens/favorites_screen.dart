import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app1/widgets/botttom_nav.dart';
import 'package:app1/widgets/categories_bar.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 50.0,
        bottom: 24.0,
        left: 24.0,
        right: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Favorite Foods',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          CategoriesBar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Favorites',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Column(
            // mainAxisSpacing: 16,
            // crossAxisSpacing: 16,
            // childAspectRatio: 0.75,
            children: [
              _buildFavoriteItem(
                'assets/images/food_image.png',
                'Avocado Salad',
              ),
              _buildFavoriteItem('assets/images/food_image.png', 'Berry Bowl'),
              _buildFavoriteItem(
                'assets/images/food_image.png',
                'Quinoa Salad',
              ),
              _buildFavoriteItem(
                'assets/images/food_image.png',
                'Grilled Chicken',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(String imagePath, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(38, 0, 0, 0),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        child: Row(
          children: [
            Image.asset(imagePath, width: 120, height: 120),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}
