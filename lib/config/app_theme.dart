import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/*
  App Theme 
  Colors used throughout the app
    Color Palattes => https://www.figma.com/color-palettes/limelight/
                      https://www.figma.com/color-palettes/lavender-citrine-twilight/
                      https://www.figma.com/color-palettes/fern/
  




 */

class AppTheme {
  AppTheme._();

  // static const Color primaryColor = Color(0xFFC4E145);
  // static const Color primaryColor = Color(0xFFC4F500);
  static const Color primaryColor = Color(0xFFABD726);
  static const Color primarySoftColor = Color(0xFFE7FF9E);
  static const Color primaryHardColor = Color(0xFF535C39);
  // static const Color secondaryColor = Color(0xFFCCFF00);

  static const Color secondaryColor = Color(0xFF7E8C54);
  static const Color secondarySoftColor = Color(0xFFE5EAF3);

  static const Color primaryDarkColor = Color(0xFF2C6500);

  static const Color backgroundColor = Color.fromARGB(255, 243, 255, 192);

  static const Color shadowColor = Color.fromARGB(38, 0, 0, 0);

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}
