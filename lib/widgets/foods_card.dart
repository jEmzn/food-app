import 'package:app1/config/app_theme.dart';
import 'package:app1/models/food.dart';
import 'package:app1/screens/food_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodsCard extends StatelessWidget {
  // Recommended foods to show, supplied by the parent (HomeScreen fetches them
  // from GET /recommendations). HomeScreen only renders this widget when the
  // list is non-empty, so we don't need an empty-state here.
  final List<Food> foods;

  const FoodsCard({super.key, required this.foods});

  @override
  Widget build(BuildContext context) {
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
      ? CachedNetworkImage(
          imageUrl: imagePath,
          height: 220,
          width: 220,
          fit: BoxFit.cover,
          // The network image failed (offline, 404, …). Fall back to the
          // bundled asset — Food.placeholderImage is itself a network URL now,
          // so it wouldn't help if we're offline.
          errorWidget: (_, __, ___) =>
              Image.asset(Food.offlineFallbackAsset, height: 220, width: 220),
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
