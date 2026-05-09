import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class BuyInstallSheet extends StatelessWidget {
  const BuyInstallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Container(
                padding: AppSpacing.iconCirclePadding,
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.radius,
                ),
                child: Icon(
                  Icons.handyman_outlined,
                  color: context.colors.bluePrimary,
                  size: 28,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل تريد إضافة خدمة تركيب؟',
                      style: AppTextStyles.sectionTitle(
                        context.colors.textPrimary,
                      ),
                    ),
                    Text(
                      'متوفر فنيين للتركيب الفوري بإحترافية عالية',
                      style: AppTextStyles.bodySmall(context.colors.textSecond),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapXl,
          TammButton(
            label: 'نعم، أريد التركيب',
            icon: Icons.check_circle_outline,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          AppSpacing.gapSm2,
          TammButton(
            type: TammButtonType.secondary,
            label: 'لا، شراء فقط',
            icon: Icons.shopping_bag_outlined,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppSpacing.gapSm,
        ],
      ),
    );
  }
}
