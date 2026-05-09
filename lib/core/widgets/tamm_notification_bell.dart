import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_spacing.dart';
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

    return Tooltip(
      message: 'الإشعارات',
      child: GestureDetector(
        onTap: () => context.push('/notifications'),
        child: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          backgroundColor: context.colors.error,
          child: Container(
            padding: AppSpacing.iconCirclePadding,
            decoration: BoxDecoration(
              color: context.colors.bluePrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: context.colors.blueSky,
              size: AppSpacing.iconMd,
            ),
          ),
        ),
      ),
    );
  }
}
