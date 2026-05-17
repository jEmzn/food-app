import 'package:app1/config/app_theme.dart';
import 'package:app1/services/meals_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// History: shows the user's logged meals for a chosen date.
///
/// Reads:  GET /meals/:date
/// Writes: DELETE /meals/dl/:mealId
///
/// We don't know the exact response shape, so we read fields defensively
/// (`meal['food_name'] as String?` etc.) and fall back to '—' when missing.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
        title: const Text('Delete meal?'),
        content: const Text('This will remove the meal and all its items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Colors.red[600])),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  String get _formattedDate {
    final d = _selected;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('History', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.white,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_formattedDate, style: GoogleFonts.inter(fontSize: 16)),
                subtitle: const Text('Tap to change date'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
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
    final mealType = meal['meal_type']?.toString() ?? 'Meal';
    final items = (meal['items'] as List?) ?? const [];
    final totalCalories = _sumCalories(items);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealType,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text('${totalCalories.toStringAsFixed(0)} kcal',
                    style: GoogleFonts.inter(color: AppTheme.primaryDarkColor)),
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
                  style: GoogleFonts.inter(color: Colors.grey[800]),
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
            Icon(Icons.no_meals, size: 60, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text('No meals logged for this date',
                style: GoogleFonts.inter(color: Colors.grey[700])),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.red[700])),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
