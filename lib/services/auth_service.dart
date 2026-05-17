import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app1/config/api_config.dart';
import 'package:app1/models/body_metrics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
        return jsonDecode(response.body) as Map<String, dynamic>;
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
  static Future<BodyMetrics?> fetchBodyMetrics() async {
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
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
