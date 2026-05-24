import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class CartIconButton extends ConsumerStatefulWidget {
  const CartIconButton({super.key});

  @override
  ConsumerState<CartIconButton> createState() => _CartIconButtonState();
}

class _CartIconButtonState extends ConsumerState<CartIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(cartCountProvider, (prev, next) {
      if (next > (prev ?? 0)) _ctrl.forward(from: 0);
    });

    final count = ref.watch(cartCountProvider);

    return IconButton(
      tooltip: 'السلة',
      onPressed: () => context.push('/customer/cart'),
      icon: ScaleTransition(
        scale: _scale,
        child: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: context.colors.error,
          child: Icon(
            Icons.shopping_cart_outlined,
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
