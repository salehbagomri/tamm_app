import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class OrderTimeline extends StatefulWidget {
  final String currentStatus;
  const OrderTimeline({super.key, required this.currentStatus});

  @override
  State<OrderTimeline> createState() => _OrderTimelineState();
}

class _OrderTimelineState extends State<OrderTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  static const _stages = [
    (
      status: 'pending',
      icon: Icons.receipt_outlined,
      label: 'تم استلام الطلب',
    ),
    (
      status: 'confirmed',
      icon: Icons.check_circle_outline,
      label: 'تم التأكيد',
    ),
    (
      status: 'assigned',
      icon: Icons.engineering_outlined,
      label: 'تم تعيين الفني',
    ),
    (
      status: 'on_the_way',
      icon: Icons.directions_car_outlined,
      label: 'الفني في الطريق',
    ),
    (
      status: 'in_progress',
      icon: Icons.build_outlined,
      label: 'جاري التنفيذ',
    ),
    (
      status: 'completed',
      icon: Icons.done_all_outlined,
      label: 'مكتمل',
    ),
  ];

  static const _statusOrder = [
    'pending',
    'confirmed',
    'assigned',
    'on_the_way',
    'in_progress',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _currentIdx {
    final idx = _statusOrder.indexOf(widget.currentStatus);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentStatus == 'cancelled') {
      return _buildCancelledBadge(context);
    }

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مسار الطلب',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapMd,
          ...List.generate(
            _stages.length,
            (i) => _buildItem(context, i, _stages[i], i == _stages.length - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int idx,
    ({String status, IconData icon, String label}) stage,
    bool isLast,
  ) {
    final done = idx < _currentIdx;
    final current = idx == _currentIdx;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle + connector — right side in RTL (first child)
        Column(
          children: [
            _buildCircle(
              context,
              done: done,
              current: current,
              icon: stage.icon,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: AppSpacing.xl,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: done ? context.colors.success : context.colors.border,
                  borderRadius: AppSpacing.radiusFull,
                ),
              ),
          ],
        ),
        AppSpacing.hGapSm2,
        // Label — left side in RTL
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              stage.label,
              style: current
                  ? AppTextStyles.body(
                      context.colors.bluePrimary,
                    ).copyWith(fontWeight: AppTextStyles.semiBold)
                  : done
                      ? AppTextStyles.body(
                          context.colors.textPrimary,
                        ).copyWith(fontWeight: AppTextStyles.medium)
                      : AppTextStyles.body(context.colors.textFaint),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircle(
    BuildContext context, {
    required bool done,
    required bool current,
    required IconData icon,
  }) {
    if (current) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.colors.bluePrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.colors.bluePrimary.withValues(
                  alpha: _pulseCtrl.value * 0.45,
                ),
                blurRadius: _pulseCtrl.value * 14,
                spreadRadius: _pulseCtrl.value * 3,
              ),
            ],
          ),
          child: child,
        ),
        child: Icon(icon, size: 18, color: context.colors.bgSurface),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: done ? context.colors.bluePrimary : context.colors.bgSurface2,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? context.colors.bluePrimary : context.colors.border,
          width: 2,
        ),
      ),
      child: Icon(
        done ? Icons.check : icon,
        size: 18,
        color: done ? context.colors.bgSurface : context.colors.textFaint,
      ),
    );
  }

  Widget _buildCancelledBadge(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.08),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.error.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel_outlined,
              color: context.colors.error,
              size: AppSpacing.iconMd,
            ),
          ),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم إلغاء الطلب',
                  style: AppTextStyles.body(
                    context.colors.error,
                  ).copyWith(fontWeight: AppTextStyles.bold),
                ),
                Text(
                  'هذا الطلب تم إلغاؤه',
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
