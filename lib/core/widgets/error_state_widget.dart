import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
///   message: ErrorMapper.from(e).message,
///   onRetry: () => ref.invalidate(myProvider),
/// ),
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// رسالة الخطأ المعروضة للمستخدم.
  final String message;

  /// إذا مُرِّرت، يظهر زر "إعادة المحاولة".
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: context.colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  color: context.colors.textSecond,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
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
