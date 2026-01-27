import 'package:app1/widgets/foods_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/categories.dart';
import 'package:app1/widgets/botttom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const String profileImage = 'assets/images/test_profile.jpg';
  static const Color primaryColor = Color(0xFF73CA31);
  static const Color shadowColor = Color.fromARGB(38, 0, 0, 0);
  @override
  build(BuildContext context) {
    return Column(
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
                        color: primaryColor,
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
                              color: shadowColor,
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
                                  elevation: WidgetStatePropertyAll<double>(0),
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
                            color: shadowColor,
                            blurRadius: 15,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
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
    );
  }
}
