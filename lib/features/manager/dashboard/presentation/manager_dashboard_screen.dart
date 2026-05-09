import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/widgets/tamm_notification_bell.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});
  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  RealtimeChannel? _dashboardChannel;

  @override
  void initState() {
    super.initState();
    _dashboardChannel = Supabase.instance.client
        .channel('public:dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(allOrdersProvider(null));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          callback: (_) {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(allOrdersProvider(null));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_dashboardChannel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ordersAsync = ref.watch(allOrdersProvider(null));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(allOrdersProvider(null));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'لوحة التحكم',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TammNotificationBell(),
                          IconButton(
                            onPressed: () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) context.go('/customer/home');
                            },
                            icon: Icon(
                              Icons.logout,
                              color: context.colors.error,
                            ),
                            tooltip: 'تسجيل الخروج',
                          ),
                        ],
                      ),
                    ],
                  ),
                  statsAsync.when(
                    data: (stats) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'معلق',
                                  value: '${stats['pending'] ?? 0}',
                                  color: context.colors.warning,
                                  icon: Icons.pending_actions,
                                ),
                              ),
                              AppSpacing.hGapSm2,
                              Expanded(
                                child: _StatCard(
                                  label: 'عروض تحتاج إجراء',
                                  value: '${stats['quotes_need_action'] ?? 0}',
                                  color: context.colors.error,
                                  icon: Icons.request_quote,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapSm2,
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'جاري التنفيذ',
                                  value: '${stats['in_progress'] ?? 0}',
                                  color: context.colors.blueLight,
                                  icon: Icons.engineering,
                                ),
                              ),
                              AppSpacing.hGapSm2,
                              Expanded(
                                child: _StatCard(
                                  label: 'مكتمل اليوم',
                                  value: '${stats['completed'] ?? 0}',
                                  color: context.colors.success,
                                  icon: Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const TammLoading(),
                    error: (e, _) => ErrorStateWidget(
                      message: e is AppException
                          ? e.message
                          : 'حدث خطأ في تحميل الإحصائيات',
                      onRetry: () => ref.invalidate(dashboardStatsProvider),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'آخر الطلبات',
                        style: AppTextStyles.sectionTitle(
                          context.colors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/manager/orders'),
                        child: Text(
                          'عرض الكل',
                          style: AppTextStyles.body(context.colors.blueLight),
                        ),
                      ),
                    ],
                  ),
                  ordersAsync.when(
                    data: (orders) => Column(
                      children: orders
                          .take(5)
                          .map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TammCard(
                                onTap: () {
                                  if (o.orderType == 'quote_request') {
                                    context.push('/manager/quote/${o.id}');
                                  } else {
                                    context.push('/manager/order/${o.id}');
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.orderTypeLabel,
                                            style: AppTextStyles.body(
                                              context.colors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '#${o.orderNumber} • ${o.statusLabel}',
                                            style: AppTextStyles.body(
                                              context.colors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      o.orderType == 'quote_request' &&
                                              o.totalAmount == 0
                                          ? o.statusLabel
                                          : '${o.totalAmount.toInt()} ر.س',
                                      style: AppTextStyles.body(
                                        context.colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    loading: () => const TammLoading(),
                    error: (e, _) => ErrorStateWidget(
                      message: e is AppException
                          ? e.message
                          : 'حدث خطأ في تحميل الطلبات',
                      onRetry: () => ref.invalidate(allOrdersProvider(null)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          AppSpacing.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
