import 'package:app1/config/app_theme.dart';
import 'package:app1/models/food.dart';
import 'package:app1/services/favorites_service.dart';
import 'package:app1/services/meals_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Detail view for a single [Food]. Shows hero image, name, calories,
/// a serving-size selector (in grams), and macro breakdown. Macros and
/// kcal scale with the chosen serving relative to [Food.defaultServingG].
class FoodDetailScreen extends StatefulWidget {
  final Food food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

// Valid meal types accepted by the backend.
// NOTE: keep these English keys — they are sent to POST /meals as-is.
const List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

// Thai label for a raw meal-type key (display only — the key is still what we
// send to the backend).
String _mealTypeLabel(String type) {
  switch (type) {
    case 'breakfast':
      return 'มื้อเช้า';
    case 'lunch':
      return 'มื้อกลางวัน';
    case 'dinner':
      return 'มื้อเย็น';
    case 'snack':
      return 'ของว่าง';
    default:
      return type;
  }
}

// Pick a sensible default meal type from the current hour. Lets the user
// tap "Add" with one fewer interaction during typical meal windows.
String _defaultMealTypeForHour(int hour) {
  if (hour >= 4 && hour <= 10) return 'breakfast';
  if (hour >= 11 && hour <= 15) return 'lunch';
  if (hour >= 16 && hour <= 21) return 'dinner';
  return 'snack';
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  // Current serving amount (in the food's native unit). Starts at default.
  late double _quantity = widget.food.quantity;

  // Currently selected meal type — defaults to whatever fits "now".
  late String _selectedMealType =
      _defaultMealTypeForHour(DateTime.now().hour);

  // True while the POST /meals request is in flight. Disables the button
  // and shows a spinner so the user can't double-submit.
  bool _submitting = false;

  // True while a favorite add/remove request is in flight — disables the
  // heart button so a quick double-tap can't fire two conflicting requests.
  bool _favoriting = false;

  // Whether this food is currently one of the user's favorites. Loaded from
  // GET /favorites in initState, then flipped optimistically on each tap.
  bool _isFavorite = false;

  // The favorite row's own id (from GET /favorites). We need this to call
  // DELETE /favorites/dl/:id when un-favoriting. Null when not a favorite.
  String? _favoriteId;

  @override
  void initState() {
    super.initState();
    // Load the user's favorites once so the heart starts in the right state
    // (filled if this food is already a favorite). Fire-and-forget: if it
    // fails we just leave the heart empty rather than blocking the screen.
    _loadFavoriteState();
  }

  // Fetch the user's favorites and check whether THIS food is among them.
  // If so, remember the favorite row's id so we can delete it later.
  Future<void> _loadFavoriteState() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      // Find the row whose food_catalog_id matches this food, if any.
      final match = favorites.where(
        (f) => f['food_catalog_id']?.toString() == widget.food.id,
      );
      if (!mounted || match.isEmpty) return;
      setState(() {
        _isFavorite = true;
        _favoriteId = match.first['id']?.toString();
      });
    } catch (e) {
      // Non-fatal: the screen still works, the heart just stays empty.
      print('[loadFavoriteState] failed: $e'); // Debug log
    }
  }

  // Bulk units (g/ml) feel right with a 10-step; discrete units like
  // "medium" or "cup" feel right with a 0.5-step. Pick based on unit.
  bool get _isBulkUnit {
    final u = widget.food.unit.toLowerCase();
    return u == 'g' || u == 'ml';
  }
  double get _step => _isBulkUnit ? 10.0 : 0.5;

  // Hard floor/ceiling so the +/- buttons can't push to absurd values.
  double get _minQuantity => _isBulkUnit ? 10.0 : 0.5;
  double get _maxQuantity => _isBulkUnit ? 2000.0 : 20.0;

  // 1.0 means "exactly the default serving" — multiply kcal/macros by this.
  double get _scale {
    final base = widget.food.quantity;
    if (base <= 0) return 1; // guard: avoid div-by-zero on bad data
    return _quantity / base;
  }

  double get _kcal => widget.food.kcal * _scale;
  double get _carbs => widget.food.carbsG * _scale;
  double get _protein => widget.food.proteinG * _scale;
  double get _fat => widget.food.fatG * _scale;

  // Step the serving up/down, clamped to a sane range for the unit.
  void _changeServing(double delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(_minQuantity, _maxQuantity);
    });
  }

  // Show "100 g" but "1.5 medium" — drop trailing .0 only for whole numbers.
  String _formatQuantity() {
    final q = _quantity;
    final qStr = q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
    return '$qStr ${widget.food.unit}';
  }

  // Pick the right widget for asset paths vs network URLs.
  Widget _buildImage() {
    final url = widget.food.imageUrl;
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        // If the network image fails (offline, 404, etc.) fall back to the
        // bundled asset so the screen still looks complete. We use the local
        // asset here, not Food.placeholderImage — the latter is now a network
        // URL and wouldn't load when we're offline.
        errorBuilder: (_, __, ___) => Image.asset(
          Food.offlineFallbackAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(url, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: GoogleFonts.mali(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_kcal.round()} kcal',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: AppTheme.primaryHardColor,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          _buildServingSelector(),
                          const SizedBox(height: AppTheme.spacingL),
                          _buildMacrosCard(),
                          const SizedBox(height: AppTheme.spacingL),
                          _buildMealTypePicker(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildAddToMealButton(),
          ],
        ),
      ),
    );
  }

  // Big rounded image with a back button overlaid in the top-left corner.
  Widget _buildImageHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 320,
            child: _buildImage(),
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: AppTheme.shadowColor,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryHardColor,
                ),
              ),
            ),
          ),
        ),
        // Favorite (heart) button — mirrors the back button on the right.
        // Filled red heart once added; shows a small spinner while saving.
        Positioned(
          top: 12,
          right: 16,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: AppTheme.shadowColor,
            child: InkWell(
              customBorder: const CircleBorder(),
              // Disable the tap only while a request is in flight; otherwise
              // tapping toggles the favorite on/off.
              onTap: _favoriting ? null : _toggleFavorite,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _favoriting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.primaryHardColor),
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? Colors.red
                            : AppTheme.primaryHardColor,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Serving size row: minus button, current grams, plus button.
  Widget _buildServingSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Text('ปริมาณ', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          _circleButton(Icons.remove, () => _changeServing(-_step)),
          SizedBox(
            width: 100,
            child: Text(
              _formatQuantity(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _circleButton(Icons.add, () => _changeServing(_step)),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppTheme.primarySoftColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          // 12 padding + 20 icon = 44dp tap target (accessibility minimum).
          padding: const EdgeInsets.all(AppTheme.spacingS),
          child: Icon(icon, size: 20, color: AppTheme.primaryHardColor),
        ),
      ),
    );
  }

  // Card that lays out the three macros side-by-side, each with its own pill.
  // White (not green) so it doesn't compete with the green primary buttons —
  // dark text on white is also easier to read than white-on-green numbers.
  Widget _buildMacrosCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สารอาหารหลัก', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroTile('คาร์บ', _carbs),
              _macroTile('โปรตีน', _protein),
              _macroTile('ไขมัน', _fat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroTile(String label, double grams) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppTheme.primaryHardColor),
        ),
        const SizedBox(height: 6),
        Text(
          '${grams.round()} g',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  // Row of 4 chips: Breakfast / Lunch / Dinner / Snack. The user can override
  // the time-of-day default before tapping Add.
  Widget _buildMealTypePicker() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('มื้ออาหาร', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingS),
          // Wrap (not Row) so the chips wrap on small screens instead of
          // overflowing.
          Wrap(
            spacing: AppTheme.spacingXS,
            runSpacing: AppTheme.spacingXS,
            children: _mealTypes.map((type) {
              final selected = type == _selectedMealType;
              return ChoiceChip(
                label: Text(
                  // Show the Thai label; the raw key is still sent to the API.
                  _mealTypeLabel(type),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : AppTheme.primaryHardColor,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                backgroundColor: AppTheme.primarySoftColor,
                selectedColor: AppTheme.primaryColor,
                onSelected: (_) {
                  setState(() => _selectedMealType = type);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Toggle this food's favorite status. If it's not a favorite yet we POST
  // /favorites; if it already is, we DELETE it by the stored favorite id.
  Future<void> _toggleFavorite() async {
    if (_favoriting) return; // guard against double-tap while a call is running
    setState(() => _favoriting = true);

    try {
      if (_isFavorite) {
        // Un-favorite. We need the row id we stored when loading/adding.
        // (Guard: if for some reason we don't have it, just bail out.)
        final id = _favoriteId;
        if (id == null) return;
        await FavoritesService.removeFavorite(id);
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
          _favoriteId = null;
        });
        _showFavoriteSnack('นำ ${widget.food.name} ออกจากอาหารโปรดแล้ว');
      } else {
        // Add to favorites. The backend returns the new row (incl. its id),
        // which we keep so the user can immediately un-favorite it.
        final favorite = await FavoritesService.addFavorite(widget.food.id);
        if (!mounted) return;
        setState(() {
          _isFavorite = true;
          _favoriteId = favorite['id']?.toString();
        });
        _showFavoriteSnack('เพิ่ม ${widget.food.name} ลงในอาหารโปรดแล้ว');
      }
    } catch (e) {
      print('[toggleFavorite] failed: $e'); // Debug log
      if (!mounted) return;
      _showFavoriteSnack('ไม่สามารถอัปเดตอาหารโปรดได้ กรุณาลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _favoriting = false);
    }
  }

  // Small helper so the add/remove/error paths share one SnackBar style.
  void _showFavoriteSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // POST to /meals with one item (the current food at the chosen serving).
  // On success, pop back to the previous screen with `true` so HomeScreen
  // can refresh its daily totals.
  Future<void> _submitMeal() async {
    if (_submitting) return; // guard against double-tap
    setState(() => _submitting = true);


    try {
      await MealsService.addMeal(
        date: DateTime.now(),
        mealType: _selectedMealType,
        foodCatalogId: widget.food.id,
        foodName: widget.food.name,
        imageUrl: widget.food.imageUrl,
        quantity: _quantity,
        unit: widget.food.unit,
        calories: _kcal,
        proteinG: _protein,
        carbsG: _carbs,
        fatG: _fat,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เพิ่ม ${widget.food.name} ลงใน${_mealTypeLabel(_selectedMealType)}แล้ว',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      // Signal the caller (HomeScreen) to refresh today's totals.
      Navigator.of(context).pop(true);
    } catch (e) {
      print('[submitMeal] add meal failed: $e'); // Debug log
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเพิ่มมื้ออาหารได้ กรุณาลองใหม่อีกครั้ง')),
      );
    } finally {
      // Always re-enable the button, whether the add succeeded or failed.
      // On success the screen has popped, so guard with `mounted`.
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Sticky CTA pinned to the bottom of the screen.
  Widget _buildAddToMealButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingXS,
        AppTheme.spacingL,
        AppTheme.spacingL,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          // Disable while a request is in flight to prevent double-submit.
          onPressed: _submitting ? null : _submitMeal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primaryColor.withAlpha(150),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  'เพิ่มลงในมื้ออาหาร',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
