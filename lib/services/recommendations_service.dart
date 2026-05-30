import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app1/config/api_config.dart';
import 'package:app1/models/food.dart';
import 'package:app1/services/auth_service.dart';
import 'package:app1/services/cache/request_cache.dart';
import 'package:http/http.dart' as http;

/// Wraps the GET /recommendations endpoint. Like the other services, every
/// call needs a Firebase ID token, fetched via AuthService.getToken() and
/// attached as a Bearer header.
///
/// The backend returns foods that best fit the user's REMAINING calories/macros
/// for the day (daily target − what they've already logged). When it can't
/// recommend anything (no body metrics yet, or the user is already over their
/// budget) it returns an empty list — so the caller can simply hide the
/// "recommended" section.
class RecommendationsService {
    static const String _baseUrl = ApiConfig.baseUrl;

    /// GET /recommendations?date=YYYY-MM-DD
    ///
    /// We pass the device's local [date] so the backend's "consumed today"
    /// matches what the rest of the app shows (MealsService uses the same local
    /// date). Defaults to now if not given.
    ///
    /// Returns the recommended foods (possibly empty). Throws on network/HTTP
    /// errors so the caller can decide how to react — HomeScreen just keeps the
    /// list empty, which hides the section.
    ///
    /// Cached in-memory for 5 minutes per date (key `recs:<YYYY-MM-DD>`). The
    /// cache is invalidated by MealsService.addMeal / deleteMeal, because
    /// logging or removing a meal changes the remaining-budget math. Pass
    /// [forceRefresh] (pull-to-refresh) to bypass a fresh cache entry.
    static Future<List<Food>> getRecommendations({
        DateTime? date,
        bool forceRefresh = false,
    }) {
        final iso = _isoDate(date ?? DateTime.now());
        return RequestCache.instance.getOrFetch<List<Food>>(
            'recs:$iso',
            ttl: const Duration(minutes: 5),
            forceRefresh: forceRefresh,
            fetch: () => _fetchRecommendations(iso),
        );
    }

    static Future<List<Food>> _fetchRecommendations(String iso) async {
        final token = await AuthService.getToken();
        final uri = Uri.parse('$_baseUrl/recommendations')
            .replace(queryParameters: {'date': iso});

        final http.Response response;
        try {
            response = await http
                .get(uri, headers: {'Authorization': 'Bearer $token'})
                .timeout(const Duration(seconds: 10));
        } on TimeoutException {
            throw Exception('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
        } on SocketException {
            throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
        }

        if (response.statusCode != 200) {
            throw Exception(
                'โหลดอาหารแนะนำไม่สำเร็จ (${response.statusCode}): ${response.body}',
            );
        }
        if (response.body.isEmpty) return [];

        final decoded = jsonDecode(response.body);
        if (decoded is! List) return [];

        // Each row is a food_catalog-shaped object; Food.fromCatalogJson handles
        // the string-encoded numerics and the null image_url fallback.
        return decoded
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .map(Food.fromCatalogJson)
            .toList();
    }

    // Backend expects YYYY-MM-DD with zero-padded month/day.
    static String _isoDate(DateTime d) {
        final yyyy = d.year.toString().padLeft(4, '0');
        final mm = d.month.toString().padLeft(2, '0');
        final dd = d.day.toString().padLeft(2, '0');
        return '$yyyy-$mm-$dd';
    }
}
