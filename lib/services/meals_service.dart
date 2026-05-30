import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app1/config/api_config.dart';
import 'package:app1/services/auth_service.dart';
import 'package:app1/services/cache/request_cache.dart';
import 'package:http/http.dart' as http;

/// Wraps the /meals endpoints. All calls require a Firebase ID token,
/// which we fetch via AuthService.getToken() and attach as Bearer.
class MealsService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// GET /meals/:date — `date` must be YYYY-MM-DD.
  /// Returns the raw list as decoded JSON. We keep it untyped because the
  /// backend response shape may evolve and the History screen only needs
  /// a few common fields.
  ///
  /// Cached in-memory for 5 minutes per date (key `meals:<YYYY-MM-DD>`) so
  /// switching tabs / re-rendering doesn't re-hit the backend. Pass
  /// [forceRefresh] (pull-to-refresh) to bypass a fresh cache entry. The cache
  /// is invalidated automatically by [addMeal] / [deleteMeal].
  static Future<List<Map<String, dynamic>>> getMealsForDate(
    DateTime date, {
    bool forceRefresh = false,
  }) {
    final iso = _isoDate(date);
    return RequestCache.instance.getOrFetch<List<Map<String, dynamic>>>(
      'meals:$iso',
      ttl: const Duration(minutes: 5),
      forceRefresh: forceRefresh,
      fetch: () => _fetchMealsForDate(iso),
    );
  }

  /// The real network call behind [getMealsForDate]. Takes the already-computed
  /// ISO date string.
  static Future<List<Map<String, dynamic>>> _fetchMealsForDate(
    String iso,
  ) async {
    final token = await AuthService.getToken();
    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$_baseUrl/meals/$iso'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'โหลดมื้ออาหารไม่สำเร็จ (${response.statusCode}): ${response.body}',
      );
    }
    if (response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    // Backend returns a FLAT list — each row is a join of `meals` × `meal_items`,
    // so the same meal_id can appear multiple times (once per food item).
    // The History UI expects one entry per meal with an `items` list, so we
    // group the rows by meal_id here.
    final Map<String, Map<String, dynamic>> byMealId = {};
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final row = raw.map((k, v) => MapEntry(k.toString(), v));
      final mealId = row['meal_id']?.toString();
      if (mealId == null) continue;

      // Build the item portion (the per-food fields from meal_items).
      final item = <String, dynamic>{
        'meal_item_id': row['meal_item_id'],
        'food_catalog_id': row['food_catalog_id'],
        'food_name': row['food_name'],
        'image_url': row['image_url'],
        'quantity': row['quantity'],
        'unit': row['unit'],
        'calories': row['calories'],
        'protein_g': row['protein_g'],
        'carbs_g': row['carbs_g'],
        'fat_g': row['fat_g'],
      };

      final existing = byMealId[mealId];
      if (existing == null) {
        byMealId[mealId] = {
          'meal_id': mealId,
          'id': mealId, // some UIs read either key
          'user_id': row['user_id'],
          'date': row['date'],
          'meal_type': row['meal_type'],
          'meal_created_at': row['meal_created_at'],
          'items': [item],
        };
      } else {
        (existing['items'] as List).add(item);
      }
    }
    return byMealId.values.toList();
  }

  /// POST /meals — log a meal with one or more food items for the given date.
  ///
  /// Request body shape:
  ///   { date: "YYYY-MM-DD", meal_type: "breakfast"|"lunch"|"dinner"|"snack",
  ///     mealItems: [ { foodCatalogId, foodName, imageUrl, quantity, unit,
  ///                    calories, protein_g, carbs_g, fat_g }, ... ] }
  ///
  /// Throws on non-2xx so the caller can surface a SnackBar with the message.
  static Future<void> addMeal({
    required DateTime date,
    required String mealType,
    // required List<Map<String, dynamic>> mealItems,
    required String foodCatalogId,
    required String foodName,
    required String imageUrl,
    required double quantity,
    required String unit,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final token = await AuthService.getToken();
    final body = jsonEncode({
      'date': _isoDate(date),
      'mealType': mealType,
      'foodCatalogId': foodCatalogId,
      'foodName': foodName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
    });
    try {
      print('Adding meal with body: $body'); // Debug log 
      final response = await http
          .post(
            Uri.parse('$_baseUrl/meals'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      // 200/201 are both reasonable success codes for a create endpoint.
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to add meal: ${response.statusCode} ${response.body}'); // Debug log
        throw Exception(
          'เพิ่มมื้ออาหารไม่สำเร็จ (${response.statusCode}): ${response.body}',
        );
      }
      // Success: this day's meals AND its recommendations are now stale.
      final iso = _isoDate(date);
      RequestCache.instance.invalidate('meals:$iso');
      RequestCache.instance.invalidate('recs:$iso');
    } on TimeoutException {
      throw Exception('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
  }

  /// DELETE /meals/dl/:mealId — removes a meal and all its items.
  static Future<void> deleteMeal(String mealId) async {
    final token = await AuthService.getToken();
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/meals/dl/$mealId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'ลบมื้ออาหารไม่สำเร็จ (${response.statusCode}): ${response.body}',
        );
      }
      // We only get the meal id here, not its date, so we can't compute a
      // single cache key. Clearing all meal/recommendation entries is cheap and
      // guarantees the deleted meal won't linger in any cached date.
      RequestCache.instance.invalidatePrefix('meals:');
      RequestCache.instance.invalidatePrefix('recs:');
    } on TimeoutException {
      throw Exception('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
  }

  // Backend expects YYYY-MM-DD with zero-padded month/day.
  static String _isoDate(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
