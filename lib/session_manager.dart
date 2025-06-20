import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';

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

class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserActivity(context),
      onPointerMove: (_) => _onUserActivity(context),
      onPointerUp: (_) => _onUserActivity(context),
      child: child,
    );
  }

  void _onUserActivity(BuildContext context) {
    // Refresh the session timer when user interacts with the app
    SessionManager().refreshSession(context);
  }
}
