import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../shared/providers/order_providers.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ordersAsync = ref.watch(allOrdersProvider(null));
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة التحكم',
                style: GoogleFonts.harmattan(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: 'معلق',
                      value: '${stats['pending']}',
                      color: AppColors.warning,
                      icon: Icons.pending_actions,
                    ),
                    _StatCard(
                      label: 'جاري التنفيذ',
                      value: '${stats['in_progress']}',
                      color: AppColors.blueLight,
                      icon: Icons.engineering,
                    ),
                    _StatCard(
                      label: 'مكتمل اليوم',
                      value: '${stats['completed']}',
                      color: AppColors.success,
                      icon: Icons.check_circle,
                    ),
                    _StatCard(
                      label: 'الفنيون',
                      value: '${stats['technicians']}',
                      color: AppColors.blueSky,
                      icon: Icons.people,
                    ),
                  ],
                ),
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
                      style: GoogleFonts.harmattan(color: AppColors.blueLight),
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
                            onTap: () => context.push('/manager/order/${o.id}'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.orderNumber,
                                      style: GoogleFonts.harmattan(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      o.statusLabel,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 14,
                                        color: AppColors.textSecond,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${o.totalAmount.toInt()} ريال',
                                  style: GoogleFonts.harmattan(
                                    color: AppColors.blueSky,
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
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.harmattan(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.harmattan(
              fontSize: 13,
              color: AppColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}
