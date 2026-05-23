import 'package:app1/config/app_theme.dart';
import 'package:app1/widgets/meal_history_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HistoryScreen: standalone route that wraps [MealHistoryView] with a Scaffold
/// and AppBar. Reached from Profile → History and from the Home Daily Target
/// card's "View today's meals" link.
///
/// The actual list/date-picker/delete logic lives in MealHistoryView so it can
/// also be embedded inside StatsScreen's "History" tab without duplicating code.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('ประวัติ', style: GoogleFonts.mali()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const MealHistoryView(),
    );
  }
}
