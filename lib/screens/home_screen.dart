import 'package:app1/config/app_theme.dart';
import 'package:app1/widgets/foods_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/categories.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const String profileImage = 'assets/images/test_profile.jpg';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 60, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Row(
                    children: [
                      // SizedBox(width: 24),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(profileImage),
                            fit: BoxFit.cover,
                          ),
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kitty Kit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: Size(60, 60),
                          shadowColor: const Color.fromARGB(90, 216, 216, 216),
                          elevation: 10,
                          foregroundColor: Colors.black,
                          shape: CircleBorder(),
                        ),
                        child: Icon(
                          Icons.notifications_none_outlined,
                          size: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      // SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.shadowColor,
                                blurRadius: 15,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: SearchAnchor(
                            builder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return SearchBar(
                                    controller: controller,
                                    constraints: BoxConstraints(minHeight: 50),
                                    backgroundColor:
                                        WidgetStatePropertyAll<Color>(
                                          Colors.white,
                                        ),
                                    elevation: WidgetStatePropertyAll<double>(
                                      0,
                                    ),
                                    leading: const Icon(Icons.search),
                                    hintText: 'Describe Your Food',
                                    hintStyle: WidgetStatePropertyAll(
                                      GoogleFonts.inter(fontSize: 14),
                                    ),
                                    padding: WidgetStatePropertyAll<EdgeInsets>(
                                      EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    onTap: () {
                                      controller.openView();
                                    },
                                    onChanged: (_) {
                                      controller.openView();
                                    },
                                  );
                                },
                            suggestionsBuilder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return [];
                                },
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor,
                              blurRadius: 15,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.backgroundColor,
                            textStyle: GoogleFonts.inter(fontSize: 14),
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                              bottom: 16,
                            ),
                          ),
                          child: Row(
                            spacing: 4,
                            children: [
                              Text('Assistant'),
                              Image.asset(
                                'assets/images/icons/icons_sparkle.png',
                                width: 16,
                                height: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDailySummary(),
                SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: CategoriesWidget(),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Text(
                    'Recommended Foods',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FoodsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method inside your HomeScreen class
  Widget _buildDailySummary() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor, // Using your static primaryColor
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(110),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Calories Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Target',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '1,250 / 2,000 kcal',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // 2. Main Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 1250 / 2000, // Eaten / Goal
              minHeight: 15,
              backgroundColor: Colors.black.withAlpha(51),
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(height: 24),

          // 3. Macros Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('Carbs', '42g', 0.5),
              _buildMacroItem('Protein', '85g', 0.8),
              _buildMacroItem('Fat', '12g', 0.3),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for the small macro columns
  Widget _buildMacroItem(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),

        // Custom Small Bar
        Container(
          width: 70,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(51),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
