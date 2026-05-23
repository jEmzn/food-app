import 'package:app1/config/app_theme.dart';
import 'package:app1/models/food.dart';
import 'package:app1/screens/food_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodsCard extends StatelessWidget {
  const FoodsCard({super.key});

  // Mock list of recommended foods. Once the backend exposes a
  // /recommended endpoint we'll fetch real data here. Exposed as a static
  // field so HomeScreen can hide the "Recommended Foods" heading while this
  // is empty (avoids a bare header above an empty row).
  static final List<Food> recommended = <Food>[
    // Numbers are per the listed quantity+unit (e.g. "1 medium apple").
  ];

  @override
  Widget build(BuildContext context) {
    final foods = recommended;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingL,
        top: AppTheme.spacingM,
        bottom: AppTheme.spacingM,
      ),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final food in foods)
            buildFoodsCard(
              food.imageUrl,
              food.name,
              food.kcal.round().toString(),
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FoodDetailScreen(food: food),
                ),
              ),
            ),
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
  // Pick the right Image widget — assets and network URLs need different ones.
  final isNetwork =
      imagePath.startsWith('http://') || imagePath.startsWith('https://');
  final image = isNetwork
      ? Image.network(
          imagePath,
          height: 220,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(Food.placeholderImage, height: 220, width: 220),
        )
      : Image.asset(imagePath, height: 220, width: 220);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXS),
    decoration: const BoxDecoration(boxShadow: AppTheme.cardShadow),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceColor,
        minimumSize: const Size(60, 60),
        foregroundColor: AppTheme.onSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(AppTheme.spacingM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.mali(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXS),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.all(Radius.circular(30)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text('$kcal kcal'),
          ),
          image,
        ],
      ),
    ),
  );
}
