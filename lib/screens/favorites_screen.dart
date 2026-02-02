import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/categories_bar.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 50.0,
          bottom: 80.0,
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
            SizedBox(height: 24),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       'Your Favorites',
            //       style: GoogleFonts.poppins(
            //         fontSize: 18,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //     Text(
            //       'See All',
            //       style: GoogleFonts.poppins(
            //         fontSize: 14,
            //         fontWeight: FontWeight.w500,
            //         color: Colors.grey,
            //       ),
            //     ),
            //   ],
            // ),
            // SizedBox(height: 16),
            GridView.count(
              padding: EdgeInsets.all(0),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.95,
              crossAxisCount: 2,
              shrinkWrap: true,
              children: [
                _buildFavoriteItem('assets/images/food_image.png', 'Salad'),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Berry Bowl',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Berry Bowl',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Berry Bowl',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Berry Bowl',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Quinoa Salad',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Grilled Chicken',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Grilled Chicken',
                ),
                _buildFavoriteItem(
                  'assets/images/food_image.png',
                  'Grilled Chicken',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(String imagePath, String title) {
    return Container(
      padding: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        image: imagePath.isNotEmpty
            ? DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover)
            : null,
        color: AppTheme.backgroundColor,
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
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
            onTap: () {
              // Handle item tap
            },
            child: Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF303030),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overflow: TextOverflow.ellipsis,
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '160 kcal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      // minimumSize: Size(50, 50),
                      padding: EdgeInsets.all(0),
                      shape: CircleBorder(),
                      backgroundColor: AppTheme.backgroundColor,
                      elevation: 0,
                    ),
                    child: Text(
                      '+',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF303030),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
