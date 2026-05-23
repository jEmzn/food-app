import 'package:app1/config/app_theme.dart';
import 'package:app1/config/routes.dart';
import 'package:app1/models/body_metrics.dart';
import 'package:app1/screens/food_detail_screen.dart';
import 'package:app1/services/api_service.dart';
import 'package:app1/services/auth_service.dart';
import 'package:app1/services/meals_service.dart';
import 'package:app1/widgets/foods_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String profileImage = 'assets/images/test_profile.jpg';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BodyMetrics? _metrics;
  bool _loadingMetrics = true;

  // In-memory cache of suggestion results per query string. Avoids re-hitting
  // /recipes/suggest when the user backspaces and retypes the same word.
  // Cleared automatically when the screen is disposed (it's just a field).
  final Map<String, List<FoodSuggestion>> _suggestionCache = {};

  // Consumed kcal/macros today — populated from GET /meals/<today>.
  // Stay at 0 if the fetch fails so the UI still renders.
  int _consumedKcal = 0;
  double _consumedCarbsG = 0;
  double _consumedProteinG = 0;
  double _consumedFatG = 0;

  // When the meals fetch fails (network down, 401, bad shape) we keep the
  // error string here so the Daily Target card can show a small caption
  // instead of silently displaying zeros. Null = no error / not loaded yet.
  String? _mealsError;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _loadTodayMeals();
  }

  // Sum calories + macros across every meal logged today.
  //
  // Handles two backend response shapes defensively:
  //   1. Nested:  { id, meal_type, items: [{calories, proteinG, ...}, ...] }
  //   2. Flat:    { id, meal_type, calories, proteinG, ... }
  // addMeal() currently POSTs flat fields, so depending on how the backend
  // stores them the GET response may not include an items[] array at all.
  //
  // On failure we capture the error in [_mealsError] so the Daily Target card
  // can show a small caption — better than silently rendering zeros.
  Future<void> _loadTodayMeals() async {
    try {
      final meals = await MealsService.getMealsForDate(DateTime.now());

      // TEMP DEBUG: print the raw shape so we can confirm what the backend
      // returns. Remove before production cut (CLAUDE.md pre-commit checklist).
      // ignore: avoid_print
      print('[home] meals raw=$meals');

      final totals = _Totals();

      for (final meal in meals) {
        final m = meal.map((k, v) => MapEntry(k.toString(), v));
        final items = (m['items'] ?? m['mealItems']) as List?;
        if (items != null && items.isNotEmpty) {
          for (final raw in items.whereType<Map>()) {
            _addItem(raw.map((k, v) => MapEntry(k.toString(), v)), totals);
          }
        } else {
          // Flat meal — the meal row itself carries the nutrition fields.
          _addItem(m, totals);
        }
      }

      if (!mounted) return;
      setState(() {
        _consumedKcal = totals.kcal.round();
        _consumedCarbsG = totals.carbs;
        _consumedProteinG = totals.protein;
        _consumedFatG = totals.fat;
        _mealsError = null;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[home] _loadTodayMeals failed: $e');
      if (!mounted) return;
      setState(() => _mealsError = "โหลดมื้ออาหารวันนี้ไม่สำเร็จ");
    }
  }

  // Add one item's nutrition into the running totals. Tries a handful of
  // common key spellings (snake_case, camelCase, short forms) because the
  // backend has renamed fields before and we don't want a one-letter typo
  // to wipe the bar.
  void _addItem(Map<String, dynamic> m, _Totals t) {
    t.kcal += _asDouble(m['calories'] ?? m['kcal'] ?? m['total_calories']);
    t.carbs += _asDouble(m['carbs_g'] ?? m['carbsG'] ?? m['carbs']);
    t.protein += _asDouble(m['protein_g'] ?? m['proteinG'] ?? m['protein']);
    t.fat += _asDouble(m['fat_g'] ?? m['fatG'] ?? m['fat']);
  }

  // Coerce num/String/null into a double for totals math.
  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _loadMetrics() async {
    try {
      final metrics = await AuthService.fetchBodyMetrics();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _loadingMetrics = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMetrics = false);
  }

  // Adjust TDEE by goal: -500 for cut, +300 for muscle gain, else maintain.
  int get _targetKcal {
    final m = _metrics;
    if (m == null || m.tdee <= 0) return 0;
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

  // Standard 50/25/25 macro split (carbs/protein/fat) by calories,
  // converted to grams using 4/4/9 kcal per gram.
  double get _targetCarbsG => _targetKcal * 0.50 / 4;
  double get _targetProteinG => _targetKcal * 0.25 / 4;
  double get _targetFatG => _targetKcal * 0.25 / 9;

  String get _displayName {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    return 'คุณ';
  }

  // Use the signed-in user's profile photo when Firebase has one; otherwise
  // fall back to the bundled placeholder asset. Mirrors ProfileScreen so the
  // same avatar shows in both places.
  ImageProvider get _avatarImage {
    final url = FirebaseAuth.instance.currentUser?.photoURL;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return const AssetImage(HomeScreen.profileImage);
  }

  String _formatKcal(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // Pull-to-refresh handler. Reloads both the body metrics (target may have
  // changed in another tab) and today's meal totals.
  Future<void> _refresh() async {
    await Future.wait([_loadMetrics(), _loadTodayMeals()]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        // alwaysScrollable so the pull gesture works even when content
        // doesn't overflow the viewport (e.g. on tall tablets).
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
          Padding(
            padding: EdgeInsets.only(top: 60, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: _avatarImage,
                            fit: BoxFit.cover,
                          ),
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            _displayName,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      // SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: SearchAnchor(
                            viewHintText: 'ค้นหาอาหารของคุณ',
                            viewBackgroundColor: Colors.white,
                            builder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return SearchBar(
                                    controller: controller,
                                    constraints: BoxConstraints(minHeight: 50),
                                    backgroundColor:
                                        WidgetStatePropertyAll<Color>(
                                          Colors.white,
                                        ),
                                    elevation: WidgetStatePropertyAll<double>(
                                      0,
                                    ),
                                    leading: const Icon(Icons.search),
                                    hintText: 'อธิบายอาหารของคุณ',
                                    hintStyle: WidgetStatePropertyAll(
                                      GoogleFonts.mali(fontSize: 14),
                                    ),
                                    padding: WidgetStatePropertyAll<EdgeInsets>(
                                      EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    onTap: () {
                                      controller.openView();
                                    },
                                    onChanged: (_) {
                                      controller.openView();
                                    },
                                  );
                                },
                            suggestionsBuilder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) async {
                                  // Don't hit the API for empty queries — the
                                  // backend errors on blank input.
                                  final query = controller.text.trim();
                                  if (query.isEmpty) return const <Widget>[];

                                  // Debounce ~300ms: SearchAnchor invokes this
                                  // builder on every keystroke, so we wait a
                                  // beat and bail if the user typed more in
                                  // the meantime. Saves a lot of wasted AI
                                  // calls on slow cache-miss queries.
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 1000), 
                                  );
                                  if (controller.text.trim() != query) {
                                    return const <Widget>[];
                                  }

                                  // Step 1: get the list of specific dish
                                  // candidates from /recipes/suggest. We
                                  // cache per-query so repeat lookups are
                                  // instant.
                                  List<FoodSuggestion> suggestions;
                                  try {
                                    final cached = _suggestionCache[query];
                                    if (cached != null) {
                                      suggestions = cached;
                                    } else {
                                      suggestions = await FoodApiService()
                                          .suggestRecipes(query);
                                      _suggestionCache[query] = suggestions;
                                    }
                                  } on RecipeApiException catch (e) {
                                    return [ListTile(title: Text(e.message))];
                                  } catch (e) {
                                    return [
                                      ListTile(title: Text('ข้อผิดพลาด: $e')),
                                    ];
                                  }

                                  if (suggestions.isEmpty) {
                                    return [
                                      const ListTile(
                                        title: Text('ไม่พบเมนูที่ตรง'),
                                      ),
                                    ];
                                  }

                                  // Step 2: render each candidate as a tile.
                                  // Tapping fetches the full Food via
                                  // /recipes/search using the *canonical*
                                  // food_name (not the user's raw text) so
                                  // nutrition + image come from the same key.
                                  // Note: with 1 result the user still taps
                                  // once — that's effectively the same UX
                                  // as before for already-specific queries.
                                  return suggestions.map((s) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.restaurant,
                                        color: AppTheme.primaryHardColor,
                                      ),
                                      title: Text(s.foodName),
                                      subtitle: s.nameEn.isNotEmpty
                                          ? Text(s.nameEn)
                                          : null,
                                      onTap: () async {
                                        // Close the overlay first so the
                                        // back-stack ends up: Home → Detail.
                                        // controller.closeView(s.foodName);
                                        try {
                                          final food = await FoodApiService()
                                              .searchRecipe(s.foodName);
                                          print('Selected food: ${food?.name}'); // Debug log
                                          if (food == null || !context.mounted) {
                                            print('Food not found or context not mounted'); // Debug log
                                            print(context.mounted); // Debug log
                                            return;
                                          }
                                          // Await the route so we can refresh
                                          // today's totals when the user pops
                                          // back after adding a meal.
                                          final added = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => FoodDetailScreen(
                                                food: food,
                                              ),
                                            ),
                                          );
                                          if (added == true && mounted) {
                                            _loadTodayMeals();
                                          }
                                        } on RecipeApiException catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(e.message)),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text('ข้อผิดพลาด: $e')),
                                          );
                                        }
                                      },
                                    );
                                  }).toList();
                                },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDailySummary(),
                const SizedBox(height: AppTheme.spacingM),
                const Padding(
                  padding: EdgeInsets.only(left: AppTheme.spacingL),
                  child: CategoriesWidget(),
                ),
                // Only show the section once we actually have recommendations
                // — otherwise the heading floats above an empty row.
                if (FoodsCard.recommended.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                    ),
                    child: Text(
                      'อาหารแนะนำ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FoodsCard(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
      ),
    );
  }

  Widget _buildDailySummary() {
    // While body metrics are loading, render a spinner card so users don't
    // briefly see "0 / 0 kcal" (which looks identical to a real bug).
    if (_loadingMetrics) {
      return _summaryShell(
        child: const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final target = _targetKcal;

    // Metrics loaded but the user has no usable height/weight yet — prompt
    // them into onboarding/profile-edit instead of showing a 0 target.
    if (target <= 0) {
      return _summaryShell(child: _buildNoTargetPrompt());
    }

    final progress = (_consumedKcal / target).clamp(0.0, 1.0);
    final headerText =
        '${_formatKcal(_consumedKcal)} / ${_formatKcal(target)} kcal';

    return _summaryShell(child: _buildSummaryBody(headerText, progress));
  }

  // Shared rounded green card. Keeps the three branches above visually
  // consistent so the layout doesn't jump as state changes.
  Widget _summaryShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(110),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // The "happy path" card: header row + progress bar + macro trio. Pulled
  // out of _buildDailySummary so the loading and no-target branches can
  // reuse the same shell without duplicating the bar layout.
  Widget _buildSummaryBody(String headerText, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'เป้าหมายประจำวัน',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            Text(
              headerText,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 15,
            backgroundColor: Colors.black.withAlpha(51),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMacroItem('คาร์บ', _consumedCarbsG, _targetCarbsG),
            _buildMacroItem('โปรตีน', _consumedProteinG, _targetProteinG),
            _buildMacroItem('ไขมัน', _consumedFatG, _targetFatG),
          ],
        ),
        // Surface a quiet caption when the meals fetch failed so users know
        // why their consumed numbers might look stale. Pull-to-refresh on the
        // outer scroll view retries the request.
        if (_mealsError != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text(
            "โหลดมื้ออาหารวันนี้ไม่สำเร็จ — ดึงลงเพื่อรีเฟรช",
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.white.withAlpha(204)),
          ),
        ],
        // Quick link into HistoryScreen, which defaults to today. Lets users
        // see *which* foods they logged (not just the totals above) and delete
        // mistakes in one tap. We refresh totals on return so deletions in
        // History are reflected here without a manual pull-to-refresh.
        const SizedBox(height: AppTheme.spacingXS),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _openTodayMeals,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXS,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Text(
              "ดูมื้ออาหารวันนี้",
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: Colors.white, fontSize: 13),
            ),
            label: const Icon(Icons.arrow_forward, size: 16),
          ),
        ),
      ],
    );
  }

  // Open the History screen (which defaults to today) and refresh today's
  // totals when we come back, so any deletions there flow into the card above.
  Future<void> _openTodayMeals() async {
    await Navigator.of(context).pushNamed(AppRoutes.historyRoute);
    if (!mounted) return;
    _loadTodayMeals();
  }

  // Shown when the user is signed in but their BodyMetrics are missing
  // height/weight (so TDEE = 0). Tapping the button drops them into the
  // profile-info screen where they can fill the missing values.
  Widget _buildNoTargetPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เป้าหมายประจำวัน',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          'กรอกข้อมูลโปรไฟล์ให้ครบเพื่อดูเป้าหมายประจำวันของคุณ',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryDarkColor,
            ),
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.profileInfoRoute)
                .then((_) {
              // Body metrics may have changed — refresh both target and totals.
              _loadMetrics();
              _loadTodayMeals();
            }),
            child: const Text('กรอกข้อมูลโปรไฟล์'),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, double consumedG, double targetG) {
    final progress = targetG > 0 ? (consumedG / targetG).clamp(0.0, 1.0) : 0.0;
    final value = targetG > 0
        ? '${consumedG.round()} / ${targetG.round()}g'
        : '--';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Colors.white.withAlpha(204)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spacingXS),

        // Custom Small Bar
        Container(
          width: 70,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(51),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Mutable accumulator passed into _addItem so we can sum across all meals
// in a single pass without rebuilding records.
class _Totals {
  double kcal = 0;
  double carbs = 0;
  double protein = 0;
  double fat = 0;
}
