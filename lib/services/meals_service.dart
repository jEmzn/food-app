import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app1/config/api_config.dart';
import 'package:app1/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Wraps the /meals endpoints. All calls require a Firebase ID token,
/// which we fetch via AuthService.getToken() and attach as Bearer.
class MealsService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// GET /meals/:date — `date` must be YYYY-MM-DD.
  /// Returns the raw list as decoded JSON. We keep it untyped because the
  /// backend response shape may evolve and the History screen only needs
  /// a few common fields.
  static Future<List<Map<String, dynamic>>> getMealsForDate(
    DateTime date,
  ) async {
    final token = await AuthService.getToken();
    final iso = _isoDate(date);
    final response = await http
        .get(
          Uri.parse('$_baseUrl/meals/$iso'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load meals (${response.statusCode}): ${response.body}',
      );
    }
    if (response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    // Normalise each entry to a Map<String, dynamic> for safer access in UI.
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
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
    required List<Map<String, dynamic>> mealItems,
  }) async {
    final token = await AuthService.getToken();
    final body = jsonEncode({
      'date': _isoDate(date),
      'meal_type': mealType,
      'mealItems': mealItems,
    });
    try {
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
        throw Exception(
          'Failed to add meal (${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Server timed out. Please try again.');
    } on SocketException {
      throw Exception('No connection to server.');
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
          'Failed to delete meal (${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Server timed out. Please try again.');
    } on SocketException {
      throw Exception('No connection to server.');
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
