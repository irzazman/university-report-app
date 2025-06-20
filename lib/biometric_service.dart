import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'user_email';
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  // Check if biometrics are available on the device
  static Future<bool> isBiometricsAvailable() async {
    bool canCheckBiometrics = false;

    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } catch (e) {
      print("Error checking biometrics: $e");
    }

    return canCheckBiometrics;
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = [];

    try {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print("Error getting available biometrics: $e");
    }

    return availableBiometrics;
  }

  // Authenticate using biometrics
  static Future<bool> authenticate() async {
    bool authenticated = false;

    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access UTeM Reporter',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print("Error authenticating: $e");
    }

    return authenticated;
  }

  // Save user's preference for biometric login
  static Future<void> setBiometricEnabled(bool enabled, String email) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
    if (enabled) {
      await _secureStorage.write(key: _userEmailKey, value: email);
    } else {
      await _secureStorage.delete(key: _userEmailKey);
    }
  }

  // Check if biometric login is enabled
  static Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Get the saved user email (for biometric login)
  static Future<String?> getSavedEmail() async {
    return await _secureStorage.read(key: _userEmailKey);
  }
}
