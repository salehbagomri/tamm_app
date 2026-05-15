import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class BuyInstallBanner extends StatelessWidget {
  const BuyInstallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/customer/store'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.blueDark, context.colors.blueMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: [
            BoxShadow(
              color: context.colors.bluePrimary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.handyman_outlined,
                        color: context.colors.blueSky,
                        size: AppSpacing.iconSm,
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        'اشترِ وركّب في طلب واحد',
                        style: AppTextStyles.cardTitle(Colors.white),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'اختر مكيفك وحدد موعد التركيب والفني يصل إليك في نفس اليوم.',
                    style: AppTextStyles.bodySmall(
                      context.colors.textPrimary,
                    ).copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            Container(
              padding: AppSpacing.cardPaddingSm,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
