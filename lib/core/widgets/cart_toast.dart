import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class CartToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, {required String productName}) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _CartToastWidget(
        productName: productName,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
        onViewCart: () {
          entry.remove();
          if (_current == entry) _current = null;
          context.push('/customer/cart');
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

class _CartToastWidget extends StatefulWidget {
  final String productName;
  final VoidCallback onDismiss;
  final VoidCallback onViewCart;

  const _CartToastWidget({
    required this.productName,
    required this.onDismiss,
    required this.onViewCart,
  });

  @override
  State<_CartToastWidget> createState() => _CartToastWidgetState();
}

class _CartToastWidgetState extends State<_CartToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: MediaQuery.of(context).size.height * 0.18,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: _ToastCard(
              productName: widget.productName,
              onViewCart: widget.onViewCart,
              onDismiss: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  final String productName;
  final VoidCallback onViewCart;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.productName,
    required this.onViewCart,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.success.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: context.colors.success,
              size: AppSpacing.iconMd,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تمت الإضافة للسلة',
                  style: AppTextStyles.label(context.colors.textPrimary),
                ),
                Text(
                  productName,
                  style: AppTextStyles.caption(context.colors.textSecond),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          TextButton(
            onPressed: onViewCart,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm2,
                vertical: AppSpacing.xs,
              ),
              backgroundColor: context.colors.bluePrimary.withValues(
                alpha: 0.08,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppSpacing.radius,
              ),
            ),
            child: Text(
              'عرض السلة',
              style: AppTextStyles.caption(context.colors.bluePrimary),
            ),
          ),
        ],
      ),
    );
  }
}
