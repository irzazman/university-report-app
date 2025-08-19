import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart';
import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'notification_service.dart';

// Make sure to import this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    // Use debug provider for development
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), // For web
    androidProvider: AndroidProvider.debug, // For development
    // In production, use:
    // androidProvider: AndroidProvider.playIntegrity,
  );

  // Initialize notification service
  await NotificationService().initialize();

  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ms')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => MaterialApp(
        title: 'UTeM Reporter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0070F0), // Primary blue from design
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF0070F0),
            secondary: const Color(0xFF62BDD9),
            surface: Colors.white,
            background: const Color(0xFFF8FAFC),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x1A000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0070F0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0070F0),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: Color(0xFF0070F0)),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const WelcomePage(), // Replace StreamBuilder with WelcomePage
      ),
    );
  }
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  Timer? _sessionTimer;
  final int _sessionTimeoutMinutes = 30; // Set session timeout to 30 minutes

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  void startSession(BuildContext context) {
    // Cancel existing timer if any
    _sessionTimer?.cancel();

    // Start a new timer
    _sessionTimer = Timer(Duration(minutes: _sessionTimeoutMinutes), () {
      // Session timeout - log out user
      _handleSessionTimeout(context);
    });
  }

  void refreshSession(BuildContext context) {
    startSession(context); // Reset the timer
  }

  Future<void> _handleSessionTimeout(BuildContext context) async {
    // Show session timeout alert
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Timeout'),
          content: const Text('Your session has expired. Please log in again.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                // Sign out
                await FirebaseAuth.instance.signOut();

                // Navigate to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void endSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
}
