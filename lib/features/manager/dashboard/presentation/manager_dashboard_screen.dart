import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../shared/providers/order_providers.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

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
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
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
                      style: GoogleFonts.harmattan(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      tooltip: 'تسجيل الخروج',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                statsAsync.when(
                  data: (stats) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'معلق',
                                value: '${stats['pending']}',
                                color: AppColors.warning,
                                icon: Icons.pending_actions,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'جاري التنفيذ',
                                value: '${stats['in_progress']}',
                                color: AppColors.blueLight,
                                icon: Icons.engineering,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'مكتمل اليوم',
                                value: '${stats['completed']}',
                                color: AppColors.success,
                                icon: Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'الفنيون',
                                value: '${stats['technicians']}',
                                color: AppColors.blueSky,
                                icon: Icons.people,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const TammLoading(),
                  error: (e, _) => Text('$e'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'آخر الطلبات',
                      style: GoogleFonts.harmattan(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/manager/orders'),
                      child: Text(
                        'عرض الكل',
                        style: GoogleFonts.harmattan(
                          color: AppColors.blueLight,
                        ),
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
                                          style: GoogleFonts.harmattan(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '#${o.orderNumber} • ${o.statusLabel}',
                                          style: GoogleFonts.harmattan(
                                            fontSize: 13,
                                            color: AppColors.textSecond,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    o.orderType == 'quote_request' && o.totalAmount == 0
                                        ? o.statusLabel
                                        : '${o.totalAmount.toInt()} ر.س',
                                    style: GoogleFonts.harmattan(
                                      color: o.orderType == 'quote_request' && o.totalAmount == 0
                                          ? AppColors.warning
                                          : AppColors.blueSky,
                                      fontWeight: FontWeight.w700,
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
                  error: (e, _) => Text('$e'),
                ),
              ],
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
        color: AppColors.bgSurface,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.harmattan(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.harmattan(
                fontSize: 13,
                color: AppColors.textSecond,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
