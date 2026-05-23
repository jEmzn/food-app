import 'package:flutter/material.dart';
import 'package:app1/config/app_theme.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('หมวดหมู่', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppTheme.spacingM,
            left: AppTheme.spacingM,
          ),
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: AppTheme.spacingL,
            // Each category now gets its own Material icon so they're visually
            // distinct (previously all three reused meat_icon.png).
            children: [
              buildCategoriesItem(
                context,
                Icons.fastfood,
                'อาหารปรุงแต่งสำเร็จ',
              ),
              buildCategoriesItem(context, Icons.cake, 'อาหารหวาน'),
              buildCategoriesItem(context, Icons.local_drink, 'เครื่องดื่ม'),
            ],
          ),
        ),
      ],
    );
  }
}

Widget buildCategoriesItem(BuildContext context, IconData icon, String title) {
  return Column(
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          shape: BoxShape.circle,
          boxShadow: AppTheme.cardShadow,
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 32, color: AppTheme.primaryDarkColor),
        ),
      ),
      const SizedBox(height: AppTheme.spacingXS),
      Text(title, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}
