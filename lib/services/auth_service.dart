import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app1/config/api_config.dart';
import 'package:app1/models/body_metrics.dart';
import 'package:app1/services/cache/request_cache.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class AuthService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns a fresh Firebase ID token for the current user.
  /// Used by all protected API calls.
  static Future<String> getToken() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) throw Exception('No authenticated user');
    return token;
  }

  /// Creates a Firebase account, updates the display name, then registers
  /// the user in PostgreSQL via POST /auth/register.
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);

    final user = credential.user;
    if (user == null) throw Exception('Account created but user session is missing.');
    final token = await user.getIdToken();
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Server unreachable. Your account was created — please try signing in.');
    } on SocketException {
      throw Exception('No connection to server. Your account was created — please try signing in.');
    }

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Backend rejected the registration — roll back the Firebase account so the
    // user isn't stuck in a partial state and can retry cleanly.
    try {
      await user.delete();
    } catch (_) {}

    throw Exception(
      (jsonDecode(response.body) as Map<String, dynamic>)['error'] ??
          'Registration failed',
    );
  }

  /// Signs in with Firebase, then fetches the user's internal profile
  /// from GET /auth/me. If the backend is unreachable or returns an error,
  /// login still succeeds — Firebase auth is the source of truth.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    final fallback = <String, dynamic>{
      'id': user?.uid ?? '',
      'name': user?.displayName ?? '',
      'email': user?.email ?? email,
    };

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body) as Map<String, dynamic>;

        // Restore the avatar after a reinstall / new device: the backend keeps
        // photo_url, but a fresh Firebase session may have an empty photoURL.
        // If so, copy the stored URL back into Firebase so the existing
        // photoURL-based avatar widgets render it without extra plumbing.
        final storedPhoto = profile['photo_url'] as String?;
        if (storedPhoto != null &&
            storedPhoto.isNotEmpty &&
            (user?.photoURL == null || user!.photoURL!.isEmpty)) {
          try {
            await user?.updatePhotoURL(storedPhoto);
            await user?.reload();
          } catch (_) {
            // Non-fatal: login still succeeds even if the sync fails.
          }
        }

        return profile;
      }
      return fallback;
    } on TimeoutException {
      return fallback;
    } on SocketException {
      return fallback;
    }
  }

  /// Fetches the current user's latest body metrics from
  /// GET /users/body-metrics. Returns null if the user has no row yet
  /// (server returns 200 with body `null`). Throws on network/auth errors.
  ///
  /// Cached in-memory for 15 minutes (key `bodyMetrics`) since profile data
  /// rarely changes; [saveBodyMetrics] invalidates it. Pass [forceRefresh] to
  /// bypass a fresh cache entry.
  static Future<BodyMetrics?> fetchBodyMetrics({bool forceRefresh = false}) {
    return RequestCache.instance.getOrFetch<BodyMetrics?>(
      'bodyMetrics',
      ttl: const Duration(minutes: 15),
      forceRefresh: forceRefresh,
      fetch: _fetchBodyMetrics,
    );
  }

  static Future<BodyMetrics?> _fetchBodyMetrics() async {
    final token = await getToken();
    final url = '$_baseUrl/users/body-metrics';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    // ignore: avoid_print
    print('[fetchBodyMetrics] GET $url -> ${response.statusCode} '
        'body=${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load body metrics (${response.statusCode}): ${response.body}',
      );
    }
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded == null) return null;
    return BodyMetrics.fromMap(decoded as Map<String, dynamic>);
  }

  /// POSTs a new body-metrics row. Backend has no PATCH/PUT, so editing the
  /// user's body data means inserting a fresh record — GET /users/body-metrics
  /// returns the *most recent* row, so the new values become the source of truth.
  static Future<void> saveBodyMetrics(BodyMetrics metrics) async {
    final token = await getToken();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/body-metrics'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(metrics.toMap()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to save body metrics (${response.statusCode}): ${response.body}',
      );
    }
    // The newly inserted row is now the source of truth — drop the cached copy
    // so the next fetchBodyMetrics() reflects the change.
    RequestCache.instance.invalidate('bodyMetrics');
  }

  /// Uploads [image] as the user's profile picture via multipart
  /// POST /users/avatar. The backend stores the file and saves its public URL
  /// on the users row, returning `{ "photo_url": "..." }`.
  ///
  /// We then mirror that URL into Firebase Auth's photoURL. Every avatar widget
  /// in the app already reads `currentUser.photoURL`, so this single line makes
  /// the new picture appear everywhere without touching those screens.
  ///
  /// Returns the stored URL. Throws on a non-200 response so the UI can show a
  /// localized error message.
  static Future<String> uploadAvatar(File image) async {
    final token = await getToken();

    // Pick the MIME type from the file extension. Without an explicit
    // contentType, MultipartFile defaults to application/octet-stream for the
    // camera's temp file, which the backend's image-only filter rejects (400).
    // image_picker re-encodes to JPEG when imageQuality is set, so jpeg is the
    // safe fallback.
    final ext = image.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };

    // MultipartRequest sets the correct multipart/form-data boundary for us;
    // the field name "avatar" must match upload.single("avatar") on the server.
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/users/avatar'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'avatar',
        image.path,
        contentType: contentType,
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to upload avatar (${response.statusCode}): ${response.body}',
      );
    }

    final url =
        (jsonDecode(response.body) as Map<String, dynamic>)['photo_url']
            as String;

    // The backend reuses a deterministic filename (<uid>.jpg), so the URL is
    // identical on every upload. Flutter caches NetworkImage by URL, so without
    // this the avatar would never visibly change after the first upload. Append
    // a timestamp so each upload yields a unique URL that bypasses the cache.
    final bustedUrl =
        '$url?v=${DateTime.now().millisecondsSinceEpoch}';

    // Mirror into Firebase so photoURL-based display updates everywhere.
    final user = _auth.currentUser;
    await user?.updatePhotoURL(bustedUrl);
    await user?.reload();

    return bustedUrl;
  }

  /// Updates the Firebase display name. The backend reads name from the
  /// Firebase token claims via /auth/me, so no extra REST call is needed.
  static Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await user.updateDisplayName(name);
    await user.reload();
  }

  /// True when the user has no metrics row, or the row exists but is missing
  /// the essentials needed to compute TDEE (height/weight).
  static bool bodyMetricsNeedOnboarding(BodyMetrics? metrics) {
    if (metrics == null) return true;
    return metrics.heightCm <= 0 || metrics.weightKg <= 0;
  }

  /// Signs out of Firebase.
  static Future<void> logout() async {
    // Wipe the in-memory cache first so a subsequent login as a different user
    // can never see the previous user's cached meals/metrics/recommendations.
    RequestCache.instance.clear();
    await _auth.signOut();
  }

  /// Sends a password-reset email via Firebase Auth.
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Returns a user-readable message for common Firebase Auth error codes.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'มีบัญชีที่ใช้อีเมลนี้อยู่แล้ว';
      case 'invalid-email':
        return 'อีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'พยายามมากเกินไป กรุณาลองใหม่ภายหลัง';
      default:
        return e.message ?? 'การยืนยันตัวตนล้มเหลว';
    }
  }
}
