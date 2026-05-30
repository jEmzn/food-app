import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WeekCalendarStrip: the green weekly calendar card used on the Stats
/// "History" tab.
///
/// It's a *controlled* widget: it doesn't own the selected date itself. The
/// parent passes in [selectedDate] and gets told about taps via [onDaySelected].
/// That keeps the strip and the meal list below it in sync — the parent holds
/// one source of truth for "which day are we looking at".
///
/// Features:
///   - Shows the Sun..Sat week that *contains* [selectedDate] (so picking an
///     older week actually shows that week, not always the current one).
///   - Each weekday pill is tappable to select that day.
///   - Future days are disabled (you can't have logged meals in the future).
///   - A calendar icon opens a full date picker to jump to any week/month.
class WeekCalendarStrip extends StatelessWidget {
  /// The currently-selected day. Its week is the one rendered, and its pill is
  /// highlighted.
  final DateTime selectedDate;

  /// Called with the tapped (or picked) day. The parent should store it and
  /// pass it back in via [selectedDate] to move the highlight.
  final ValueChanged<DateTime> onDaySelected;

  const WeekCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDaySelected,
  });

  // Thai month names, index 0 = January.
  static const _months = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  // Thai weekday abbreviations, Sun..Sat.
  static const _days = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];

  // Strip a DateTime down to a date-only value (midnight), so comparisons
  // ignore the time-of-day part.
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // The seven dates of [selectedDate]'s week, Sunday → Saturday.
  // DateTime.weekday is Mon=1..Sun=7, so `weekday % 7` gives Sun=0..Sat=6 —
  // i.e. how far [selectedDate] sits past its week's Sunday.
  List<DateTime> _weekDates() {
    final sel = _dateOnly(selectedDate);
    final sunday = sel.subtract(Duration(days: sel.weekday % 7));
    return List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  // Open the native date picker so the user can jump to any week/month.
  // We cap [lastDate] at today because meals can't exist in the future.
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDaySelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _weekDates();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: month + year of the selected day, plus a button that opens
          // the full date picker to jump to another week/month.
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_months[selectedDate.month - 1]} ${selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              // Tappable calendar icon — the "pick another week/month" entry.
              IconButton(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                tooltip: 'เลือกวันที่',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          // The week's seven pills, Sun..Sat.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) => _buildDayPill(dates[i], i)),
          ),
        ],
      ),
    );
  }

  // One weekday pill for [date]; [index] is its 0..6 slot in the Sun..Sat row.
  Widget _buildDayPill(DateTime date, int index) {
    final today = _dateOnly(DateTime.now());
    final isSelected = _dateOnly(date) == _dateOnly(selectedDate);
    final isToday = _dateOnly(date) == today;
    // Future days can't have meals, so they're shown faded and don't respond
    // to taps.
    final isFuture = _dateOnly(date).isAfter(today);

    return Opacity(
      opacity: isFuture ? 0.4 : 1.0,
      child: GestureDetector(
        // Passing null disables the tap entirely for future days.
        onTap: isFuture ? null : () => onDaySelected(date),
        child: Container(
          height: 64,
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          decoration: BoxDecoration(
            // Selected day fills dark green so it stands out against the green
            // card; everything else is white.
            color: isSelected ? AppTheme.primaryDarkColor : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            border: Border.all(
              // Today (when not the selected day) keeps a dark-green outline so
              // the user can still find "now" at a glance.
              color: isSelected
                  ? AppTheme.primaryDarkColor
                  : (isToday
                      ? AppTheme.primaryDarkColor
                      : const Color.fromARGB(255, 212, 212, 212)),
              width: isToday && !isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _days[index],
                style: GoogleFonts.mali(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  // Invert inside the highlighted pill: a white circle on the
                  // dark fill keeps the day number readable.
                  color: isSelected ? Colors.white : AppTheme.primarySoftColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: Text(
                  date.day.toString(),
                  style: GoogleFonts.mali(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color:
                        isSelected ? AppTheme.primaryDarkColor : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
