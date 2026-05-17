import 'dart:convert';
import 'package:app1/config/api_config.dart';
import 'package:app1/models/food.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// One candidate dish returned by `/recipes/suggest`. We keep this tiny
/// because the suggest endpoint is only meant to drive a disambiguation
/// picker — it does NOT contain nutrition data yet.
class FoodSuggestion {
  final String foodName; // Thai canonical name, e.g. "ต้มยำกุ้งน้ำข้น"
  final String nameEn;   // English label for accessibility / fallback UI

  const FoodSuggestion({required this.foodName, required this.nameEn});

  factory FoodSuggestion.fromJson(Map<String, dynamic> json) {
    return FoodSuggestion(
      foodName: (json['food_name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
    );
  }
}

/// Thrown when the backend signals an AI-related failure so the UI can
/// show a friendly message instead of a raw stack trace.
/// - 429: AI provider rate-limited us
/// - 502: AI returned malformed JSON the server couldn't parse
/// - 500: anything else server-side
class RecipeApiException implements Exception {
  final int statusCode;
  final String message;
  RecipeApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// Talks to the recipe / food endpoints. Both `/recipes/suggest` and
/// `/recipes/search` are protected — they require a Firebase ID token
/// attached as `Authorization: Bearer <token>`. See [_authedGet] for the
/// auto-refresh-on-401 logic.
class FoodApiService {
  // Use the shared ApiConfig base URL so we don't drift across services.
  String get _baseUrl => ApiConfig.baseUrl;

  /// GET helper that attaches the Firebase ID token and, on a 401, forces
  /// a token refresh and retries exactly once. Firebase normally auto-
  /// refreshes tokens that are close to expiring, but if our cached token
  /// just expired we'd still get a 401 on the first call — the retry
  /// covers that gap.
  ///
  /// Throws [RecipeApiException(401)] if no user is signed in, or if the
  /// retry also fails (e.g. account was disabled server-side).
  Future<http.Response> _authedGet(Uri uri) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw RecipeApiException(401, 'กรุณาเข้าสู่ระบบใหม่');
    }

    // First attempt: use whatever token Firebase has cached (fast path).
    var token = await user.getIdToken();
    var response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    // Retry once with a freshly-minted token if the server rejected ours.
    if (response.statusCode == 401) {
      token = await user.getIdToken(true); // force-refresh
      response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 401) {
        throw RecipeApiException(401, 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }
    }
    return response;
  }

  /// `GET /recipes/suggest?query=<text>`
  ///
  /// Returns up to ~5 specific Thai dish names that disambiguate a vague
  /// query like "ต้มยำ" into "ต้มยำกุ้งน้ำข้น", "ต้มยำไก่", etc. These are
  /// *candidates only* — they have no nutrition data. The user picks one,
  /// then we call [searchRecipe] with the chosen `food_name`.
  ///
  /// Returns an empty list when the backend has nothing to suggest. Throws
  /// [RecipeApiException] for known AI error codes so the caller can show
  /// a localized message.
  Future<List<FoodSuggestion>> suggestRecipes(String query) async {
    final uri = Uri.parse('$_baseUrl/recipes/suggest')
        .replace(queryParameters: {'query': query});
    final response = await _authedGet(uri);

    if (response.statusCode == 429) {
      throw RecipeApiException(429, 'ลองใหม่อีกครั้ง (AI กำลังถูกใช้งานหนัก)');
    }
    if (response.statusCode == 502) {
      throw RecipeApiException(502, 'AI ส่งข้อมูลผิดรูปแบบ ลองพิมพ์ใหม่');
    }
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw RecipeApiException(
        response.statusCode,
        'เกิดข้อผิดพลาด (${response.statusCode})',
      );
    }
    if (response.body.isEmpty) return const [];

    final decoded = json.decode(response.body);

    // TEMP DEBUG: print the raw shape so we can see what the backend
    // actually returns. Remove once parsing is verified.
    // ignore: avoid_print
    print('[suggestRecipes] raw response: ${response.body}');

    if (decoded is! Map) return const [];

    // Try top-level `suggestions` first (per spec), then fall back to
    // `data.suggestions` in case the backend wrapped it like /search does.
    dynamic list = decoded['suggestions'];
    if (list is! List) {
      final data = decoded['data'];
      if (data is Map) list = data['suggestions'];
    }
    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(FoodSuggestion.fromJson)
        .where((s) => s.foodName.isNotEmpty)
        .toList();
  }

  /// `GET /recipes/search?query=<text>`
  ///
  /// Returns one [Food] (the endpoint resolves a single best match — it's
  /// not an autocomplete that returns multiple suggestions). Returns null
  /// if the backend gives a 404 or empty body.
  ///
  /// The backend serialises numeric fields as strings ("250", "20"), so the
  /// JSON parsing happens inside [Food.fromCatalogJson] rather than here.
  /// Heads-up: AI-generated rows currently include an `image_url` pointing
  /// at `localhost:3000/static/...` — that won't load from a phone/emulator
  /// on the LAN. The Food model falls back to the bundled placeholder if
  /// the network image fails.
  Future<Food?> searchRecipe(String query) async {
    final uri = Uri.parse('$_baseUrl/recipes/search')
        .replace(queryParameters: {'query': query});
    final response = await _authedGet(uri);

    if (response.statusCode == 429) {
      throw RecipeApiException(429, 'ลองใหม่อีกครั้ง (AI กำลังถูกใช้งานหนัก)');
    }
    if (response.statusCode == 502) {
      throw RecipeApiException(502, 'AI ส่งข้อมูลผิดรูปแบบ ลองพิมพ์ใหม่');
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw RecipeApiException(
        response.statusCode,
        'เกิดข้อผิดพลาด (${response.statusCode})',
      );
    }
    if (response.body.isEmpty) return null;

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    if (data is! Map) return null;

    // jsonDecode gives us Map<dynamic, dynamic>; coerce so the factory's
    // typed access works without casts at every field.
    final typed = data.map((k, v) => MapEntry(k.toString(), v));
    return Food.fromCatalogJson(typed);
  }

}
