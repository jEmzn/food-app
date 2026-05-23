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

  // Near-white neutral scaffold background. Keeps screens calm so the
  // yellow-green accent (primaryColor) actually stands out where it's used.
  static const Color backgroundColor = Color(0xFFF9FAFB);

  static const Color shadowColor = Color.fromARGB(38, 0, 0, 0);

  // ---------------------------------------------------------------------------
  // Semantic colors
  // ---------------------------------------------------------------------------
  // Instead of hardcoding `Colors.white` / `Colors.grey[700]` in every widget,
  // we name colors by their *role*. If the palette ever changes, we edit it
  // here once instead of hunting through 20 files.
  //   surfaceColor  = the background of cards/sheets that sit on the scaffold
  //   onSurfaceColor = primary text/icons drawn on top of a surface
  //   subtleText    = secondary/hint text (captions, units, helper labels)
  static const Color surfaceColor = Colors.white;
  static const Color onSurfaceColor = Color(0xFF1A1A1A);
  static const Color subtleText = Color(0xFF6B7280);

  // ---------------------------------------------------------------------------
  // Spacing scale
  // ---------------------------------------------------------------------------
  // A single ladder of spacing values. Using these instead of random numbers
  // (8/10/12/15/18/20...) keeps padding/margins consistent across screens, so
  // the layout reads as deliberate rather than slightly off.
  static const double spacingXS = 8;
  static const double spacingS = 12;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 40;

  // ---------------------------------------------------------------------------
  // Card shadow
  // ---------------------------------------------------------------------------
  // One soft, shared elevation shadow. Reusing this everywhere stops cards from
  // having slightly different blurs/offsets that make the UI feel inconsistent.
  // ~6% black, blur 12, nudged down 4px so cards appear to float on the page.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromARGB(15, 0, 0, 0),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Macro chart palette — a green family so the nutrition graph matches the
  // brand instead of clashing with generic amber/blue/red.
  //   carbs   = primary yellow-green
  //   protein = a deeper green (darkest, reads as "most substantial")
  //   fat     = a pale green tint (lightest)
  static const Color macroCarbsColor = Color(0xFFABD726);
  static const Color macroProteinColor = Color(0xFF5B8A2D);
  static const Color macroFatColor = Color(0xFFD4E89A);

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
        headlineLarge: GoogleFonts.mali(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        headlineMedium: GoogleFonts.mali(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        headlineSmall: GoogleFonts.mali(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        // Section headers (e.g. "Categories", "Recommended Foods"). These used
        // to be written inline as GoogleFonts.mali(20, w600) all over the
        // app; now they live here so the hierarchy is defined in one place.
        titleLarge: GoogleFonts.mali(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
        ),
        // Card titles / sub-section headers.
        titleMedium: GoogleFonts.mali(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
        ),
        // Emphasized small text: button labels, name lines, pill text.
        labelMedium: GoogleFonts.mali(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurfaceColor,
        ),
        // Captions, units, helper text — quieter than labelMedium.
        labelSmall: GoogleFonts.mali(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: subtleText,
        ),
        bodyMedium: GoogleFonts.mali(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        bodySmall: GoogleFonts.mali(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}
