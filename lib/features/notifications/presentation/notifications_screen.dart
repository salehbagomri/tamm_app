import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:tamm_app/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/tamm_loading.dart';
import '../../../core/widgets/tamm_empty_state.dart';
import '../../../core/theme/tamm_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../shared/providers/notification_providers.dart';
import '../../../shared/providers/auth_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgSurface,
        elevation: 0,
        title: Text(
          'الإشعارات',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(
                'تعيين الكل كمقروء',
                style: AppTextStyles.bodySmall(context.colors.bluePrimary),
              ),
            ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل الإشعارات',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const TammEmptyState(
              icon: Icons.notifications_none_outlined,
              message: 'لا توجد إشعارات بعد',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => AppSpacing.gapSm,
            itemBuilder: (context, index) {
              return _NotificationCard(notification: notifs[index]);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final Map<String, dynamic> notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification['is_read'] == true;
    final type = notification['notification_type'] as String?;
    final orderId = notification['order_id'] as String?;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;

    final iconData = _iconForType(type);
    final iconColor = _colorForType(context, type);

    return GestureDetector(
      onTap: () async {
        // Mark as read
        await ref
            .read(notificationsProvider.notifier)
            .markAsRead(notification['id'] as String);
        // Navigate
        if (orderId != null && context.mounted) {
          final route = _buildRoute(ref, type, orderId);
          if (route != null) context.push(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? context.colors.bgSurface
              : context.colors.bluePrimary.withValues(alpha: 0.06),
          borderRadius: AppSpacing.radius,
          border: Border.all(
            color: isRead
                ? context.colors.border
                : context.colors.bluePrimary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: AppSpacing.iconCirclePadding,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            AppSpacing.hGapSm2,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.body(context.colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        _relativeTime(createdAt),
                        style: AppTextStyles.caption(context.colors.textFaint),
                      ),
                    ],
                  ),
                  AppSpacing.gapXs,
                  Text(
                    body,
                    style: AppTextStyles.bodySmall(context.colors.textSecond),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.bluePrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _buildRoute(WidgetRef ref, String? type, String orderId) {
    // Determine user role
    final profileAsync = ref.read(userProfileProvider);
    final role = profileAsync.valueOrNull?.role ?? 'customer';

    if (type == 'new_assignment') {
      // orderId is actually assignment_id for technician
      return '/technician/task/$orderId';
    }

    switch (role) {
      case 'manager':
        if (type == 'quote_sent' || type == 'quote_responded') {
          return '/manager/quote/$orderId';
        }
        return '/manager/order/$orderId';
      case 'technician':
        return '/technician/task/$orderId';
      case 'customer':
      default:
        if (type == 'quote_sent') {
          return '/customer/quote-response/$orderId';
        }
        return '/customer/order/$orderId';
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'order_confirmed':
        return Icons.check_circle_outline;
      case 'assigned':
        return Icons.engineering_outlined;
      case 'on_the_way':
        return Icons.directions_car_outlined;
      case 'in_progress':
        return Icons.build_outlined;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'quote_sent':
        return Icons.request_quote_outlined;
      case 'quote_responded':
        return Icons.reply_outlined;
      case 'new_order':
        return Icons.shopping_bag_outlined;
      case 'new_assignment':
        return Icons.assignment_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(BuildContext context, String? type) {
    switch (type) {
      case 'order_confirmed':
      case 'completed':
      case 'new_assignment':
        return context.colors.success;
      case 'on_the_way':
      case 'quote_responded':
        return context.colors.warning;
      case 'assigned':
      case 'new_order':
      case 'quote_sent':
      case 'in_progress':
        return context.colors.bluePrimary;
      default:
        return context.colors.textSecond;
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('yyyy/MM/dd').format(date.toLocal());
  }
}
