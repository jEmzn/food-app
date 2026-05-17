import 'package:app1/config/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _loadTodayMeals();
  }

  // Sum calories + macros across every item in every meal logged today.
  // Defensive key fallbacks mirror history_screen.dart — backend field names
  // have shifted before and we don't want a tiny rename to wipe the totals.
  Future<void> _loadTodayMeals() async {
    try {
      final meals = await MealsService.getMealsForDate(DateTime.now());

      double kcal = 0;
      double carbs = 0;
      double protein = 0;
      double fat = 0;

      for (final meal in meals) {
        final items = (meal['items'] ?? meal['mealItems']) as List?;
        if (items == null) continue;
        for (final raw in items.whereType<Map>()) {
          final m = raw.map((k, v) => MapEntry(k.toString(), v));
          kcal += _asDouble(m['calories'] ?? m['kcal']);
          carbs += _asDouble(m['carbs_g'] ?? m['carbsG']);
          protein += _asDouble(m['protein_g'] ?? m['proteinG']);
          fat += _asDouble(m['fat_g'] ?? m['fatG']);
        }
      }

      if (!mounted) return;
      setState(() {
        _consumedKcal = kcal.round();
        _consumedCarbsG = carbs;
        _consumedProteinG = protein;
        _consumedFatG = fat;
      });
    } catch (_) {
      // Swallow — totals just stay at their previous values (or 0 on first load).
    }
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
    return 'there';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 60, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Row(
                    children: [
                      // SizedBox(width: 24),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(HomeScreen.profileImage),
                            fit: BoxFit.cover,
                          ),
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _displayName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: Size(60, 60),
                          shadowColor: const Color.fromARGB(90, 216, 216, 216),
                          elevation: 10,
                          foregroundColor: Colors.black,
                          shape: CircleBorder(),
                        ),
                        child: Icon(
                          Icons.notifications_none_outlined,
                          size: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      // SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.shadowColor,
                                blurRadius: 15,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: SearchAnchor(
                            viewHintText: 'Search Your Food',
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
                                    hintText: 'Describe Your Food',
                                    hintStyle: WidgetStatePropertyAll(
                                      GoogleFonts.inter(fontSize: 14),
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
                                      ListTile(title: Text('Error: $e')),
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
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      },
                                    );
                                  }).toList();
                                },
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor,
                              blurRadius: 15,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.backgroundColor,
                            textStyle: GoogleFonts.inter(fontSize: 14),
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                              bottom: 16,
                            ),
                          ),
                          child: Row(
                            spacing: 4,
                            children: [
                              Text('Assistant'),
                              Image.asset(
                                'assets/images/icons/icons_sparkle.png',
                                width: 16,
                                height: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDailySummary(),
                SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: CategoriesWidget(),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Text(
                    'Recommended Foods',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FoodsCard(),
              ],
            ),
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildDailySummary() {
    final target = _targetKcal;
    final progress = target > 0
        ? (_consumedKcal / target).clamp(0.0, 1.0)
        : 0.0;
    final headerText = _loadingMetrics
        ? 'Loading…'
        : target > 0
            ? '${_formatKcal(_consumedKcal)} / ${_formatKcal(target)} kcal'
            : 'Set your goal to see target';

    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(24),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Target',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                headerText,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 15,
              backgroundColor: Colors.black.withAlpha(51),
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem(
                'Carbs',
                _consumedCarbsG,
                _targetCarbsG,
              ),
              _buildMacroItem(
                'Protein',
                _consumedProteinG,
                _targetProteinG,
              ),
              _buildMacroItem(
                'Fat',
                _consumedFatG,
                _targetFatG,
              ),
            ],
          ),
        ],
      ),
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
          style: GoogleFonts.inter(
            color: Colors.white.withAlpha(204),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),

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
