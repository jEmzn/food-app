import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/graph.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // static const Color primaryColor = Color(0xFFC4E145);
  // static const Color secondaryColor = Color.fromARGB(255, 196, 225, 69);
  static DateTime now = DateTime.now().toLocal();
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
                'Statistics',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildCalenderCard(),
            SizedBox(height: 24),
            GraphWidget(
              valueData: [0.1, 0.5, 0.3, 0.7, 0.2, 0.4, 1],
              labels: _days,
              kcal: 2800,
              weekday: now.weekday,
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildCalenderCard() {
    return Column(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today, ${now.day} ${_months[now.month - 1]} ${now.year}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    7,
                    (index) => _buildWeekdayStats(
                      now.weekday == index + 1 ? now.weekday : index + 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayStats(int index) {
    final int day = now.day - ((now.weekday % 7) - index);
    if (day < 1 || day > 31) {
      return SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 64,
        width: 42,
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(30)),
          border: Border.all(
            color: Color.fromARGB(255, 212, 212, 212),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _days[index - 1],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primarySoftColor,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(6),
              child: Text(
                day.toString(),
                style: GoogleFonts.inter(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
