import 'package:app1/config/app_theme.dart';
import 'package:app1/config/routes.dart';
import 'package:app1/services/meals_service.dart';
import 'package:flutter/material.dart';

/// MealHistoryView: embeddable list of the user's logged meals for a chosen date.
///
/// This is the body that used to live inside HistoryScreen. We pulled it out
/// so it can be reused in two places:
///   - Standalone route (Scaffold + AppBar wrapper in HistoryScreen)
///   - Inside StatsScreen's "History" tab (no Scaffold needed)
///
/// Reads:  GET /meals/:date
/// Writes: DELETE /meals/dl/:mealId
///
/// Backend response shape is loose, so fields are read defensively
/// (`meal['food_name'] as String?` etc.) and fall back to '—' when missing.
class MealHistoryView extends StatefulWidget {
  const MealHistoryView({super.key});
  @override
  State<MealHistoryView> createState() => _MealHistoryViewState();
}

// Thai label for a raw backend meal-type key (display only).
String _mealTypeLabel(String type) {
  switch (type.toLowerCase()) {
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

class _MealHistoryViewState extends State<MealHistoryView> {
  DateTime _selected = DateTime.now();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = MealsService.getMealsForDate(_selected);
  }

  void _reload() {
    setState(() {
      _future = MealsService.getMealsForDate(_selected);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selected = picked);
      _reload();
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบมื้ออาหาร?'),
        content: const Text('การกระทำนี้จะลบมื้ออาหารนี้พร้อมรายการทั้งหมด'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบ', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MealsService.deleteMeal(mealId);
      if (!mounted) return;
      _reload();
    } catch (e) {
      print('[mealHistory] delete failed: $e'); // Debug log
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถลบมื้ออาหารได้ กรุณาลองใหม่อีกครั้ง')),
      );
    }
  }

  // Human-readable label for the selected date: "Today" / "Yesterday" for the
  // two most common cases, otherwise a friendly "May 21, 2025". We compare on
  // calendar day (not raw difference) so a date earlier today still reads
  // "Today" regardless of the current clock time.
  String get _formattedDate {
    final d = _selected;
    final now = DateTime.now();
    final selectedDay = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = today.difference(selectedDay).inDays;

    if (dayDiff == 0) return 'วันนี้';
    if (dayDiff == 1) return 'เมื่อวาน';

    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Card(
            color: AppTheme.surfaceColor,
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _formattedDate,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: const Text('แตะเพื่อเปลี่ยนวันที่'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _pickDate,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Error(message: '${snapshot.error}', onRetry: _reload);
              }
              final meals = snapshot.data ?? [];
              if (meals.isEmpty) {
                return const _EmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                  ),
                  itemCount: meals.length,
                  itemBuilder: (_, i) => _MealCard(
                    meal: meals[i],
                    onDelete: _deleteMeal,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final void Function(String mealId) onDelete;
  const _MealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Safe extraction — backend shape may vary.
    final mealId = (meal['id'] ?? meal['meal_id'])?.toString();
    final mealType = _mealTypeLabel(meal['meal_type']?.toString() ?? 'มื้ออาหาร');
    final items = (meal['items'] as List?) ?? const [];
    final totalCalories = _sumCalories(items);

    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryDarkColor,
                  ),
                ),
                if (mealId != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: () => onDelete(mealId),
                  ),
              ],
            ),
            ...items.whereType<Map>().map((it) {
              final m = it.map((k, v) => MapEntry(k.toString(), v));
              final name = m['food_name']?.toString() ?? '—';
              final qty = m['quantity']?.toString() ?? '';
              final unit = m['unit']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $name  ${qty.isEmpty ? '' : '$qty $unit'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.subtleText,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Try a few common keys for calories per item.
  double _sumCalories(List items) {
    double sum = 0;
    for (final raw in items) {
      if (raw is! Map) continue;
      final v = raw['calories'] ?? raw['kcal'] ?? raw['total_calories'];
      if (v is num) sum += v.toDouble();
      if (v is String) sum += double.tryParse(v) ?? 0;
    }
    return sum;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_meals, size: 60, color: AppTheme.subtleText),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'ไม่มีมื้ออาหารที่บันทึกไว้ในวันนี้',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.subtleText,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            // Turn the dead-end empty state into a next step: send the user to
            // the Home tab to browse/search a food to log. Resetting to the
            // main route works whether this view is shown as a pushed route
            // (HistoryScreen) or inside the Stats "History" tab.
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.mainRoute,
                (_) => false,
              ),
              icon: const Icon(Icons.add),
              label: const Text('บันทึกมื้ออาหาร'),
            ),
          ],
        ),
      );
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Error({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ElevatedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
            ],
          ),
        ),
      );
}
