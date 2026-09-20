import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/notifications_controller.dart';

class NotificationBadgeIcon extends ConsumerWidget {
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  const NotificationBadgeIcon({
    super.key,
    this.onTap,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          key: const Key('notification_badge_icon_button'),
          icon: Icon(
            unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
            size: size,
            color: color ?? AppColors.textPrimary,
          ),
          tooltip: unreadCount > 0
              ? 'Notifications ($unreadCount unread)'
              : 'Notifications',
          onPressed: () {
            if (onTap != null) {
              onTap!();
            } else {
              context.push('/notifications');
            }
          },
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
