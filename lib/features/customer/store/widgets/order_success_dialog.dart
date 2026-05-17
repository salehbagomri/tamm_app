import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class OrderSuccessDialog extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final String paymentType;

  const OrderSuccessDialog({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.paymentType,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String orderNumber,
    required String paymentType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderSuccessDialog(
        orderId: orderId,
        orderNumber: orderNumber,
        paymentType: paymentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsTransferProof =
        paymentType == 'bank' || paymentType == 'wallet';

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: AppSpacing.radiusFull,
              ),
            ),
            AppSpacing.gapLg,
            const _SuccessIcon(),
            AppSpacing.gapMd,
            Text(
              'شكراً لك على الشراء! 🎉',
              style: AppTextStyles.h2(context.colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm2,
            _OrderNumberRow(orderNumber: orderNumber),
            AppSpacing.gapSm2,
            Text(
              'يمكنك متابعة حالة طلبك من خلال صفحة طلباتي',
              style: AppTextStyles.bodySmall(context.colors.textSecond),
              textAlign: TextAlign.center,
            ),
            if (needsTransferProof) ...[
              AppSpacing.gapMd,
              const _PaymentNote(),
            ],
            AppSpacing.gapLg,
            TammButton(
              label: 'مواصلة التسوق 🛍',
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.go('/customer/store');
              },
            ),
            AppSpacing.gapSm2,
            TammButton(
              type: TammButtonType.secondary,
              label: 'عرض الطلب ←',
              onPressed: () {
                final router = GoRouter.of(context);
                final id = orderId;
                Navigator.of(context).pop();
                router.go('/customer/order/$id');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatefulWidget {
  const _SuccessIcon();

  @override
  State<_SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<_SuccessIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 6,
              right: 6,
              child: _Dot(color: context.colors.blueLight),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: _Dot(color: context.colors.blueSky),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: _Dot(color: context.colors.blueSky),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: _Dot(color: context.colors.blueLight),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colors.bluePrimary,
                    context.colors.blueLight,
                  ],
                ),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: context.colors.bgSurface,
                size: AppSpacing.iconXl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _OrderNumberRow extends StatelessWidget {
  final String orderNumber;
  const _OrderNumberRow({required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm2,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface2,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'رقم طلبك: ',
            style: AppTextStyles.body(context.colors.textSecond),
          ),
          Text(
            orderNumber,
            style: AppTextStyles.body(
              context.colors.bluePrimary,
            ).copyWith(fontWeight: AppTextStyles.bold),
          ),
          AppSpacing.hGapSm,
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: orderNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رقم الطلب'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Icon(
              Icons.copy_outlined,
              size: AppSpacing.iconXs,
              color: context.colors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentNote extends StatelessWidget {
  const _PaymentNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingSm,
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.10),
        borderRadius: AppSpacing.radius,
        border: Border.all(
          color: context.colors.warning.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outlined,
            color: context.colors.warning,
            size: AppSpacing.iconSm,
          ),
          AppSpacing.hGapSm2,
          Expanded(
            child: Text(
              'يرجى إرفاق صورة من سند التحويل في صفحة تفاصيل الطلب',
              style: AppTextStyles.caption(context.colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
