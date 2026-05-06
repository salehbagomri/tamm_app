import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../shared/providers/notification_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

/// يُستخدم في AppBar لعرض عدد الإشعارات غير المقروءة
class TammNotificationBell extends ConsumerWidget {
  final VoidCallback onTap;
  const TammNotificationBell({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);

    return IconButton(
      onPressed: onTap,
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
                  '$count',
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
