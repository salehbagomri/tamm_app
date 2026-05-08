import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/notification_providers.dart';
import '../../shared/providers/auth_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

/// يُستخدم في AppBar لعرض عدد الإشعارات غير المقروءة.
/// لا يُعرض إذا كان المستخدم ضيفاً.
class TammNotificationBell extends ConsumerWidget {
  const TammNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);

    // لا تُعرض الجرس للضيف نهائياً
    if (isGuest) return const SizedBox.shrink();

    final count = ref.watch(unreadCountProvider);

    return IconButton(
      onPressed: () => context.push('/notifications'),
      tooltip: 'الإشعارات',
      icon: Stack(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: context.colors.textPrimary,
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
