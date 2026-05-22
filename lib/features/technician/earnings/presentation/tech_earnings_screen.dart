import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/technician_earning.dart';
import '../../../../shared/providers/technician_providers.dart';

class TechEarningsScreen extends ConsumerWidget {
  const TechEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(myEarningsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        elevation: 0,
        title: Text(
          'أرباحي وعمولاتي',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: earningsAsync.when(
            loading: () => const TammLoading(),
            error: (e, _) => ErrorStateWidget(
              message: e is AppException
                  ? e.message
                  : 'حدث خطأ في تحميل الأرباح',
              onRetry: () => ref.invalidate(myEarningsProvider),
            ),
            data: (earnings) {
              if (earnings.isEmpty) {
                return const TammEmptyState(
                  icon: Icons.payments_outlined,
                  message: 'لا توجد أرباح بعد',
                );
              }

              final totalEarned = earnings.fold<double>(
                0,
                (sum, e) => sum + e.commissionAmount,
              );
              final totalPending = earnings
                  .where((e) => !e.isPaid)
                  .fold<double>(0, (sum, e) => sum + e.commissionAmount);

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myEarningsProvider);
                  await ref.read(myEarningsProvider.future);
                },
                child: ListView(
                  children: [
                    _SummaryCard(
                      totalEarned: totalEarned,
                      totalPending: totalPending,
                    ),
                    AppSpacing.gapMd,
                    Text(
                      'سجل العمولات',
                      style: AppTextStyles.bodySmall(
                        context.colors.textSecond,
                      ),
                    ),
                    AppSpacing.gapSm2,
                    ...List.generate(earnings.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EarningCard(earning: earnings[i]),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── بطاقة الملخص ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double totalEarned;
  final double totalPending;

  const _SummaryCard({
    required this.totalEarned,
    required this.totalPending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'إجمالي العمولات',
              value: totalEarned,
              color: context.colors.bluePrimary,
              icon: Icons.payments_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: context.colors.border,
          ),
          Expanded(
            child: _SummaryCell(
              label: 'المستحق حالياً',
              value: totalPending,
              color: context.colors.warning,
              icon: Icons.schedule_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: AppSpacing.iconMd),
        AppSpacing.gapXs,
        Text(
          '${_format(value)} ر.س',
          style: AppTextStyles.sectionTitle(color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption(context.colors.textSecond),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _format(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

// ─── بطاقة سجل ربح واحد ──────────────────────────────────────────────────────

class _EarningCard extends StatelessWidget {
  final TechnicianEarning earning;

  const _EarningCard({required this.earning});

  @override
  Widget build(BuildContext context) {
    final paid = earning.isPaid;
    final statusColor = paid ? context.colors.success : context.colors.warning;
    final statusLabel = paid ? 'تم الاستلام' : 'مستحقة';
    final statusIcon =
        paid ? Icons.check_circle_outlined : Icons.schedule_outlined;

    return TammCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    AppSpacing.hGapXs,
                    Text(
                      statusLabel,
                      style: AppTextStyles.caption(statusColor).copyWith(
                        fontWeight: AppTextStyles.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (earning.orderNumber != null)
                Text(
                  '#${earning.orderNumber}',
                  style: AppTextStyles.caption(context.colors.textFaint),
                ),
            ],
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Icon(
                Icons.handyman_outlined,
                size: 16,
                color: context.colors.textSecond,
              ),
              AppSpacing.hGapXs,
              Text(
                earning.taskTypeLabel,
                style: AppTextStyles.body(context.colors.textPrimary).copyWith(
                  fontWeight: AppTextStyles.semiBold,
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              Text(
                'العمولة:',
                style: AppTextStyles.caption(context.colors.textSecond),
              ),
              AppSpacing.hGapXs,
              Text(
                '${_format(earning.commissionAmount)} ر.س',
                style: AppTextStyles.body(context.colors.bluePrimary).copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.event_outlined,
                size: 12,
                color: context.colors.textFaint,
              ),
              AppSpacing.hGapXs,
              Text(
                _formatDate(earning.createdAt),
                style: AppTextStyles.caption(context.colors.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
