import 'package:app1/config/app_theme.dart';
import 'package:app1/models/food.dart';
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
const List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

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
        // If the network image fails (offline, 404, etc.) fall back to
        // the bundled placeholder so the screen still looks complete.
        errorBuilder: (_, __, ___) => Image.asset(
          Food.placeholderImage,
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
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_kcal.round()} kcal',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.primaryHardColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildServingSelector(),
                          const SizedBox(height: 24),
                          _buildMacrosCard(),
                          const SizedBox(height: 24),
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
      ],
    );
  }

  // Serving size row: minus button, current grams, plus button.
  Widget _buildServingSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Serving',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _circleButton(Icons.remove, () => _changeServing(-_step)),
          SizedBox(
            width: 100,
            child: Text(
              _formatQuantity(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppTheme.primaryHardColor),
        ),
      ),
    );
  }

  // Card that lays out the three macros side-by-side, each with its own pill.
  Widget _buildMacrosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(110),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macros',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroTile('Carbs', _carbs),
              _macroTile('Protein', _protein),
              _macroTile('Fat', _fat),
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
          style: GoogleFonts.inter(
            color: Colors.white.withAlpha(204),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${grams.round()} g',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Row of 4 chips: Breakfast / Lunch / Dinner / Snack. The user can override
  // the time-of-day default before tapping Add.
  Widget _buildMealTypePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Wrap (not Row) so the chips wrap on small screens instead of
          // overflowing.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mealTypes.map((type) {
              final selected = type == _selectedMealType;
              return ChoiceChip(
                label: Text(
                  // Capitalise: "breakfast" → "Breakfast".
                  type[0].toUpperCase() + type.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : AppTheme.primaryHardColor,
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

  // POST to /meals with one item (the current food at the chosen serving).
  // On success, pop back to the previous screen with `true` so HomeScreen
  // can refresh its daily totals.
  Future<void> _submitMeal() async {
    if (_submitting) return; // guard against double-tap
    setState(() => _submitting = true);

    final item = widget.food.toMealItemJson(
      quantity: _quantity,
      calories: _kcal,
      carbsG: _carbs,
      proteinG: _protein,
      fatG: _fat,
    );

    try {
      await MealsService.addMeal(
        date: DateTime.now(),
        mealType: _selectedMealType,
        mealItems: [item],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${widget.food.name} to $_selectedMealType',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      // Signal the caller (HomeScreen) to refresh today's totals.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Sticky CTA pinned to the bottom of the screen.
  Widget _buildAddToMealButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                  'Add to meal',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
