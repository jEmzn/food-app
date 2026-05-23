import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 50,
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.all(Radius.circular(100)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItem(context, 0, Icons.home_outlined, 'หน้าแรก'),
              _buildItem(context, 1, Icons.favorite_border, 'รายการโปรด'),
              _buildItem(context, 2, Icons.bar_chart_outlined, 'สถิติ'),
              _buildItem(context, 3, Icons.person_outline, 'โปรไฟล์'),
            ],
          ),
        ),
      ),
    );
  }

  // One nav destination: icon + text label stacked vertically. The whole
  // column is tappable. Active items use the brand accent; inactive ones
  // are grey so the current tab stands out.
  Widget _buildItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.subtleText;

    return InkWell(
      onTap: () => onItemTapped(index),
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXS,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
