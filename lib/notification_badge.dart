import 'package:flutter/material.dart';
import 'notification_service.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final double size;
  final Color? color;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.icon = Icons.notifications,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final NotificationService notificationService = NotificationService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: size,
                color: color ?? theme.colorScheme.onSurface,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;

  const NotificationIconButton({
    super.key,
    this.onPressed,
    this.icon = Icons.notifications_outlined,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: NotificationBadge(
        icon: icon,
        size: size,
        onTap: onPressed,
      ),
    );
  }
}