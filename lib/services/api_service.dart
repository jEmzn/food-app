import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

/// Talks to the recipe / food endpoints: `/recipes/suggest` and
/// `/recipes/search` (DB-only) and `/recipes/ai-search` (explicit AI). All
/// are protected — they require a Firebase ID token attached as
/// `Authorization: Bearer <token>`. See [_authedGet] for the
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

    try {
      // First attempt: use whatever token Firebase has cached (fast path).
      var token = await user.getIdToken();
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      // Retry once with a freshly-minted token if the server rejected ours.
      if (response.statusCode == 401) {
        token = await user.getIdToken(true); // force-refresh
        response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
        if (response.statusCode == 401) {
          throw RecipeApiException(401, 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
        }
      }
      return response;
    } on TimeoutException {
      throw RecipeApiException(408, 'เซิร์ฟเวอร์ตอบสนองช้า ลองใหม่อีกครั้ง');
    } on SocketException {
      throw RecipeApiException(503, 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
  }

  /// `GET /recipes/suggest?query=<text>`
  ///
  /// DATABASE-ONLY autocomplete. Returns up to ~5 dish names already stored
  /// in the food catalog whose name contains [query]. This used to call the
  /// AI to disambiguate vague queries; that behavior was removed — these are
  /// now plain DB matches with real, already-saved nutrition behind them.
  ///
  /// The user picks one, then we call [searchRecipe] (also DB-only) to load
  /// it. For foods that aren't in the DB yet, the UI offers an explicit
  /// "search with AI" action ([aiSearchRecipe]).
  ///
  /// Returns an empty list when nothing matches. Throws [RecipeApiException]
  /// for non-200 responses so the caller can show a localized message.
  Future<List<FoodSuggestion>> suggestRecipes(String query) async {
    final uri = Uri.parse('$_baseUrl/recipes/suggest')
        .replace(queryParameters: {'query': query});
    final response = await _authedGet(uri);

    // DB-only endpoint — no AI rate-limit / bad-JSON codes to handle here.
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw RecipeApiException(
        response.statusCode,
        'เกิดข้อผิดพลาด (${response.statusCode})',
      );
    }
    if (response.body.isEmpty) return const [];

    final decoded = json.decode(response.body);
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

  /// `GET /recipes/search?query=<text>` — DATABASE-ONLY lookup.
  ///
  /// Resolves a single dish by exact (case-insensitive) name from the food
  /// catalog. There is NO AI fallback: if the dish isn't in the DB the
  /// backend replies 404, and this method returns null. A null result means
  /// "not in the database yet" — the caller should then offer the user an
  /// explicit AI search via [aiSearchRecipe].
  ///
  /// The backend serialises numeric fields as strings ("250", "20"), so the
  /// JSON parsing happens inside [Food.fromCatalogJson] rather than here.
  Future<Food?> searchRecipe(String query) async {
    final uri = Uri.parse('$_baseUrl/recipes/search')
        .replace(queryParameters: {'query': query});
    final response = await _authedGet(uri);

    // 404 = not found in DB. Caller decides whether to offer AI search.
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw RecipeApiException(
        response.statusCode,
        'เกิดข้อผิดพลาด (${response.statusCode})',
      );
    }
    if (response.body.isEmpty) return null;

    return _parseFoodResponse(response.body);
  }

  /// `GET /recipes/ai-search?query=<text>` — EXPLICIT AI search.
  ///
  /// This is the ONLY method that triggers the (paid) AI nutrition lookup,
  /// and it should only be called from a deliberate user action — e.g. the
  /// "ค้นหาด้วย AI" button — never automatically as a fallback.
  ///
  /// The backend returns AI-estimated nutrition + an image but does NOT save
  /// it to the database. So the returned [Food] is transient: it exists only
  /// for this session unless the user later chooses to log/save it.
  ///
  /// Returns null on an empty body. Throws [RecipeApiException] for the AI
  /// error codes (429 busy, 502 bad response) so the UI can localize them.
  Future<Food?> aiSearchRecipe(String query) async {
    final uri = Uri.parse('$_baseUrl/recipes/ai-search')
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

    return _parseFoodResponse(response.body);
  }

  /// Shared parser for the `{ data: {...} }` envelope returned by both
  /// `/recipes/search` and `/recipes/ai-search`. Returns null if the shape
  /// isn't what we expect.
  Food? _parseFoodResponse(String body) {
    final decoded = json.decode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    if (data is! Map) return null;

    // jsonDecode gives us Map<dynamic, dynamic>; coerce so the factory's
    // typed access works without casts at every field.
    final typed = data.map((k, v) => MapEntry(k.toString(), v));
    return Food.fromCatalogJson(typed);
  }
}
