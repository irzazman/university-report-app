import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userPasswordKey =
      'auth_user_password'; // Store password securely

  // Store the authentication credentials securely
  static Future<void> saveAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = FirebaseAuth.instance.currentUser?.email;

      // We need to save the email for future sign-in
      if (email != null) {
        await _storage.write(key: _userEmailKey, value: email);
      }

      // Set expiry time (30 days from now)
      final expiryTime = DateTime.now().add(const Duration(days: 30));
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.millisecondsSinceEpoch.toString(),
      );

      print("Auth token saved successfully");
    } catch (e) {
      print("Error saving auth token: $e");
      await clearToken();
    }
  }

  // Save password during first login (only when user enables biometric)
  static Future<void> savePassword(String password) async {
    try {
      await _storage.write(key: _userPasswordKey, value: password);
    } catch (e) {
      print("Error saving password: $e");
    }
  }

  // Sign in with saved credentials
  static Future<bool> signInWithToken() async {
    try {
      // Check if credentials exist
      final email = await _storage.read(key: _userEmailKey);
      final password = await _storage.read(key: _userPasswordKey);
      final expiryString = await _storage.read(key: _tokenExpiryKey);

      print("Found stored email: $email");

      if (email == null || password == null) {
        print(
          "Missing essential credentials: email=$email, password=${password != null}",
        );
        return false;
      }

      // If expiry is missing or expired, regenerate it
      if (expiryString == null ||
          DateTime.fromMillisecondsSinceEpoch(
            int.parse(expiryString),
          ).isBefore(DateTime.now())) {
        print("Regenerating expiry token");
        final newExpiryTime = DateTime.now().add(const Duration(days: 30));
        await _storage.write(
          key: _tokenExpiryKey,
          value: newExpiryTime.millisecondsSinceEpoch.toString(),
        );
      }

      // Sign in with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Successfully signed in with stored credentials");
      return true;
    } catch (e) {
      print("Error signing in with token: $e");
      return false;
    }
  }

  // Clear stored tokens
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    // Do NOT delete user email and password keys to preserve biometric login option
  }
}
