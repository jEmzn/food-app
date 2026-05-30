import 'package:app1/config/app_theme.dart';
import 'package:app1/models/body_metrics.dart';
import 'package:app1/services/auth_service.dart';
import 'package:app1/services/meals_service.dart';
import 'package:app1/widgets/meal_history_view.dart';
import 'package:app1/widgets/week_calendar_strip.dart';
import 'package:flutter/material.dart';
import 'package:app1/widgets/graph.dart';

/// StatsScreen: bottom-nav tab with two sub-tabs:
///   - Overview: weekly calendar strip + kcal graph (existing widgets).
///   - History: list of meals the user has logged on a chosen date
///     (embeds the shared [MealHistoryView]).
///
/// We use TabBar + TabBarView instead of one long ScrollView so adding more
/// stats widgets later doesn't force the user to scroll past everything.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  // Held by the state so the TabBar and TabBarView stay in sync, and so we
  // can dispose it ourselves (DefaultTabController would also work, but doing
  // it manually keeps the door open for programmatically switching tabs later).
  late final TabController _tabController;

  // A getter (not a static field) so the date is recomputed on each build —
  // a static field would freeze at app-launch time and go stale past midnight.
  DateTime get _now => DateTime.now().toLocal();
  // Thai weekday abbreviations, Sun..Sat (also used as the graph's bar labels).
  static const _days = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];

  // Fallback daily calorie target used for the graph's reference line when the
  // user has no usable body metrics yet (so TDEE can't be computed).
  static const int _fallbackTargetKcal = 2000;

  // Weekly stats state. Populated by _loadWeek().
  bool _loadingWeek = true;
  String? _weekError;
  // Per-day totals (calories + macros) for the current week (Sun..Sat),
  // index-aligned with [_days]. Days in the future stay at zero.
  List<_DayTotals> _weekTotals = List<_DayTotals>.filled(7, const _DayTotals());
  // The daily target (TDEE adjusted by goal), drawn as the dashed line.
  int _targetKcal = _fallbackTargetKcal;

  // Which day the "History" tab is showing. Driven by the WeekCalendarStrip;
  // defaults to today.
  DateTime _historySelected = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWeek();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // The seven dates of the current week, Sunday → Saturday, as local
  // date-only values. DateTime.weekday is Mon=1..Sun=7, so `weekday % 7`
  // gives Sun=0..Sat=6 — the offset of "today" from this week's Sunday.
  List<DateTime> _weekDates() {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.subtract(Duration(days: now.weekday % 7));
    return List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  // Convert body metrics into a daily calorie target. Mirrors the Home
  // screen's logic: cut 500 to lose, add 300 to gain, else maintain.
  // Falls back to a sensible default when metrics are missing.
  int _targetFromMetrics(BodyMetrics? m) {
    if (m == null || m.tdee <= 0) return _fallbackTargetKcal;
    switch (m.goalType) {
      case GoalType.loseWeight:
        return (m.tdee - 500).round();
      case GoalType.gainMuscle:
        return (m.tdee + 300).round();
      case GoalType.maintainWeight:
      case GoalType.unknown:
        return m.tdee.round();
    }
  }

  // Sum calories and macros across every item in all of one day's meals.
  // The backend serialises numbers as either num or numeric String, so both
  // are coerced via _asDouble.
  _DayTotals _sumDay(List<Map<String, dynamic>> meals) {
    double kcal = 0, carbs = 0, protein = 0, fat = 0;
    for (final meal in meals) {
      final items = (meal['items'] as List?) ?? const [];
      for (final raw in items) {
        if (raw is! Map) continue;
        kcal += _asDouble(raw['calories']);
        carbs += _asDouble(raw['carbs_g']);
        protein += _asDouble(raw['protein_g']);
        fat += _asDouble(raw['fat_g']);
      }
    }
    return _DayTotals(kcal: kcal, carbsG: carbs, proteinG: protein, fatG: fat);
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // Load the target + this week's per-day calorie totals. Metrics and meals
  // are fetched independently so a missing metrics row still lets the graph
  // render (with the fallback target).
  Future<void> _loadWeek({bool forceRefresh = false}) async {
    setState(() {
      _loadingWeek = true;
      _weekError = null;
    });

    BodyMetrics? metrics;
    try {
      metrics = await AuthService.fetchBodyMetrics(forceRefresh: forceRefresh);
    } catch (_) {
      // Non-fatal: fall back to the default target below.
    }

    try {
      final dates = _weekDates();

      // TEMP DEBUG: confirm what the app thinks "today"/this week is and what
      // each day returns. Remove once the missing-meals bug is diagnosed.
      // ignore: avoid_print
      print('[stats] today=$_now weekday=${_now.weekday} '
          'queryDates=${dates.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').toList()}');

      // Fetch all seven days in parallel — much faster than awaiting each.
      final results = await Future.wait(
        dates.map((d) => MealsService.getMealsForDate(d, forceRefresh: forceRefresh)),
      );

      final totals = results.map(_sumDay).toList();
      // TEMP DEBUG: per-day calories the app computed.
      // ignore: avoid_print
      print('[stats] perDayKcal=${totals.map((t) => t.kcal).toList()}');

      if (!mounted) return;
      setState(() {
        _targetKcal = _targetFromMetrics(metrics);
        _weekTotals = totals;
        _loadingWeek = false;
      });
    } catch (e) {
      // TEMP DEBUG: surface the real error instead of only the friendly text.
      // ignore: avoid_print
      print('[stats] _loadWeek failed: $e');
      if (!mounted) return;
      setState(() {
        _weekError = "โหลดสถิติประจำสัปดาห์ไม่สำเร็จ";
        _loadingWeek = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingL),
          // Title row — kept as-is so the screen still feels like "Statistics"
          // even when the user is on the History tab.
          SizedBox(
            width: double.infinity,
            child: Text(
              'สถิติ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.onSurfaceColor,
            unselectedLabelColor: AppTheme.subtleText,
            labelStyle: Theme.of(context).textTheme.titleMedium,
            tabs: const [
              Tab(text: 'ภาพรวม'),
              Tab(text: 'ประวัติ'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The original Stats content (calendar card + weekly graph). Wrapped in a
  // SingleChildScrollView so adding more cards here later won't break layout.
  // Pull-to-refresh re-fetches the week (e.g. after logging a meal elsewhere).
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      // Pull-to-refresh bypasses the cache for the body metrics and all 7 days.
      onRefresh: () => _loadWeek(forceRefresh: true),
      child: SingleChildScrollView(
        // alwaysScrollable so the pull gesture works even when the content
        // doesn't overflow the viewport.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppTheme.spacingM,
          bottom: 80,
          left: AppTheme.spacingL,
          right: AppTheme.spacingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCalorieGraph(),
          ],
        ),
      ),
    );
  }

  // Render the weekly calorie graph from real data, or a loading/error state.
  Widget _buildCalorieGraph() {
    if (_loadingWeek) {
      return const SizedBox(
        height: 336,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_weekError != null) {
      return SizedBox(
        height: 336,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekError!,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.subtleText),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ElevatedButton(
                onPressed: () => _loadWeek(forceRefresh: true),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    // The graph expects each bar as a fraction of [kcal] (the reference line),
    // so divide each day's real total by the target. The widget grows its
    // gridlines automatically when a day exceeds the target (fraction > 1).
    final target = _targetKcal <= 0 ? _fallbackTargetKcal : _targetKcal;
    final values = _weekTotals.map((t) => t.kcal / target).toList();

    // Macro chart shows each macro's share of the day's calories, so convert
    // grams to calorie contributions (carbs/protein 4 kcal/g, fat 9 kcal/g).
    // The widget normalises these into stacked-bar shares.
    final macroData = _weekTotals
        .map((t) => [t.carbsG * 4, t.proteinG * 4, t.fatG * 9])
        .toList();

    return GraphWidget(
      valueData: values,
      labels: _days,
      kcal: target,
      macroData: macroData,
      // _days is Sun..Sat (index 0..6); the widget highlights the bar where
      // index + 1 == weekday, so map today's weekday into that 1-based slot.
      weekday: (_now.weekday % 7) + 1,
    );
  }

  // The "History" tab: the interactive weekly calendar strip on top driving
  // the meal list below. The strip and the list share one selected date
  // (_historySelected) so tapping a pill (or picking a date) reloads the list.
  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingM,
            AppTheme.spacingL,
            AppTheme.spacingS,
          ),
          child: WeekCalendarStrip(
            selectedDate: _historySelected,
            onDaySelected: (date) {
              setState(() => _historySelected = date);
            },
          ),
        ),
        // MealHistoryView handles its own scrolling; in controlled mode it
        // hides its built-in date Card and follows _historySelected instead.
        Expanded(
          child: MealHistoryView(
            selectedDate: _historySelected,
            showDateCard: false,
          ),
        ),
      ],
    );
  }
}

// One day's aggregated nutrition. Immutable so the default-filled week list
// can share a single const zero instance.
class _DayTotals {
  final double kcal;
  final double carbsG;
  final double proteinG;
  final double fatG;

  const _DayTotals({
    this.kcal = 0,
    this.carbsG = 0,
    this.proteinG = 0,
    this.fatG = 0,
  });
}
