import 'package:flutter/material.dart';
import 'session_manager.dart';

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
