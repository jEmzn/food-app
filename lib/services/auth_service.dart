import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://192.168.1.7:3000';
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

    final token = await credential.user?.getIdToken();
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
    }

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      (jsonDecode(response.body) as Map<String, dynamic>)['error'] ??
          'Registration failed',
    );
  }

  /// Signs in with Firebase, then fetches the user's internal profile
  /// from GET /auth/me.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      (jsonDecode(response.body) as Map<String, dynamic>)['error'] ??
          'Login failed',
    );
  }

  /// Signs out of Firebase.
  static Future<void> logout() async {
    await _auth.signOut();
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
