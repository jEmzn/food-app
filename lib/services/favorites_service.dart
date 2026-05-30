import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app1/config/api_config.dart';
import 'package:app1/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Wraps the /favorites endpoints. Like [MealsService], every call needs a
/// Firebase ID token which we fetch via [AuthService.getToken] and send as a
/// `Authorization: Bearer <token>` header.
class FavoritesService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// POST /favorites — mark a food (by its catalog id) as one of the user's
  /// favorites.
  ///
  /// Request body: `{ "foodCatalogId": "<uuid>" }`.
  ///
  /// The backend ties the favorite to the authenticated user, so we don't
  /// send a user id ourselves. Throws on any non-2xx response so the caller
  /// can show a SnackBar with the message.
  ///
  /// Returns the newly-created favorite row (including its `id`), so the
  /// caller can immediately delete it again via [removeFavorite].
  static Future<Map<String, dynamic>> addFavorite(String foodCatalogId) async {
    final token = await AuthService.getToken();
    final body = jsonEncode({'foodCatalogId': foodCatalogId});
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/favorites'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }

    // 200/201 are both reasonable success codes for a create endpoint.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'เพิ่มอาหารโปรดไม่สำเร็จ (${response.statusCode}): ${response.body}',
      );
    }
    // The route responds with the created row, e.g.
    // { "id": "...", "user_id": "...", "food_catalog_id": "..." }.
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  /// GET /favorites — the authenticated user's favorite foods.
  ///
  /// Each row now includes `id` (the favorite row's own id, needed for delete)
  /// and `food_catalog_id` (so we can tell which catalog foods are already
  /// favorited), alongside the food's display fields. We keep the rows untyped
  /// because callers only read a couple of fields.
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final token = await AuthService.getToken();
    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$_baseUrl/favorites'),
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
        'โหลดอาหารโปรดไม่สำเร็จ (${response.statusCode}): ${response.body}',
      );
    }
    if (response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// DELETE /favorites/dl/:id — remove a favorite by the favorite row's id
  /// (NOT the food's catalog id). Get that id from [getFavorites].
  static Future<void> removeFavorite(String favoriteId) async {
    final token = await AuthService.getToken();
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/favorites/dl/$favoriteId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'ลบอาหารโปรดไม่สำเร็จ (${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
  }
}
