import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamm_app/core/constants/app_spacing.dart';
import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class BetaDisclaimerDialog extends StatefulWidget {
  const BetaDisclaimerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final showDisclaimer = prefs.getBool('show_beta_disclaimer') ?? true;

    if (!showDisclaimer) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false, // Force acknowledgment
      builder: (context) => const BetaDisclaimerDialog(),
    );
  }

  @override
  State<BetaDisclaimerDialog> createState() => _BetaDisclaimerDialogState();
}

class _BetaDisclaimerDialogState extends State<BetaDisclaimerDialog> {
  bool _dontShowAgain = false;
  bool _isSaving = false;

  Future<void> _onAccept() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_dontShowAgain) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('show_beta_disclaimer', false);
      }
    } catch (e) {
      debugPrint('Error saving disclaimer preference: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back button pop
      child: Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(
                  color: context.colors.warning.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.warning.withValues(alpha: 0.1),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              padding: AppSpacing.dialogPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Glowing Lab Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.colors.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.warning.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.science_rounded,
                        color: context.colors.warning,
                        size: 36,
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,

                  // 2. Title
                  Text(
                    'النسخة التجريبية لـ "تمّ"',
                    style: AppTextStyles.h3(context.colors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapSm,

                  // 3. Subtitle / Alert description
                  Text(
                    'مرحلة الفحص والتحقق الفني',
                    style: AppTextStyles.label(context.colors.warning),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapMd,

                  // 4. Detailed disclaimer content box
                  Container(
                    padding: AppSpacing.cardPaddingSm,
                    decoration: BoxDecoration(
                      color: context.colors.bgPrimary,
                      borderRadius: AppSpacing.radius,
                      border: Border.all(color: context.colors.border),
                    ),
                    child: const Column(
                      children: [
                        _DisclaimerItem(
                          icon: Icons.info_outline_rounded,
                          text:
                              'التطبيق حالياً في مرحلته التجريبية للتحقق من كفاءة التشغيل وسهولة الاستخدام.',
                        ),
                        AppSpacing.gapSm,
                        _DisclaimerItem(
                          icon: Icons.money_off_rounded,
                          text:
                              'جميع الأسعار، المنتجات، تفاصيل الخدمات، والحجوزات المعروضة هي بيانات وهمية ومخصصة للتجربة فقط.',
                        ),
                        AppSpacing.gapSm,
                        _DisclaimerItem(
                          icon: Icons.credit_card_off_rounded,
                          text:
                              'بيانات الحسابات البنكية غير حقيقية، ولن يتم إجراء أو مطالبة بأي معاملات مالية فعلية.',
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,

                  // 5. Checkbox (Don't show again)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _dontShowAgain = !_dontShowAgain;
                      });
                    },
                    borderRadius: AppSpacing.radiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _dontShowAgain,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _dontShowAgain = val;
                                  });
                                }
                              },
                              activeColor: context.colors.bluePrimary,
                              checkColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppSpacing.radiusXs,
                              ),
                              side: BorderSide(
                                color: context.colors.border,
                                width: 1.5,
                              ),
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              'لا تعرض هذه الرسالة مرة أخرى',
                              style: AppTextStyles.body(
                                context.colors.textSecond,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,

                  // 6. Action Button
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.bluePrimary,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.radius,
                        ),
                        elevation: 2,
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'موافق وفهمت',
                              style: AppTextStyles.button(Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DisclaimerItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: context.colors.textSecond,
          size: AppSpacing.iconSm,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall(context.colors.textPrimary).copyWith(
              height: AppTextStyles.lineHeightNormal,
            ),
          ),
        ),
      ],
    );
  }
}
