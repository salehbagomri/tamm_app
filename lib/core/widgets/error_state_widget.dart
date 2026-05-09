import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../theme/tamm_colors.dart';
import '../widgets/tamm_button.dart';

/// يُعرض عند فشل تحميل بيانات الشاشة (أخطاء AsyncValue).
///
/// للأخطاء المؤقتة التي تحتاج تحرك فوري من المستخدم — على عكس
/// [TammEmptyState] التي تُعبّر عن غياب البيانات.
///
/// الاستخدام:
/// ```dart
/// error: (e, _) => ErrorStateWidget(
///   message: e is AppException ? e.message : 'حدث خطأ',
///   onRetry: () => ref.invalidate(myProvider),
/// ),
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// رسالة الخطأ المعروضة للمستخدم.
  final String message;

  /// إذا مُرِّرت، يظهر زر "إعادة المحاولة".
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppSpacing.iconXxl,
                color: context.colors.error,
              ),
              AppSpacing.gapMd,
              Text(
                message,
                style: AppTextStyles.cardTitle(context.colors.textSecond),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                AppSpacing.gapLg,
                TammButton(
                  label: 'إعادة المحاولة',
                  type: TammButtonType.secondary,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  width: 200,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
