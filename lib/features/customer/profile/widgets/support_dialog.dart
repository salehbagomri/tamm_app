import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

Future<void> showSupportDialog(
  BuildContext context, {
  String orderNumber = '',
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SupportSheet(orderNumber: orderNumber),
  );
}

class _SupportSheet extends StatelessWidget {
  final String orderNumber;
  const _SupportSheet({required this.orderNumber});

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: AppConstants.supportPhone);
    await launchUrl(uri);
  }

  Future<void> _whatsApp() async {
    final text = orderNumber.isNotEmpty
        ? 'مرحباً، أحتاج مساعدة بخصوص طلب رقم $orderNumber'
        : 'مرحباً، أحتاج مساعدة';
    final uri = Uri.parse(
      'https://wa.me/${AppConstants.supportWhatsApp}?text=${Uri.encodeComponent(text)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLgValue),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm2),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: AppSpacing.radiusFull,
            ),
          ),
          // Title
          Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.bluePrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.headset_mic_outlined,
                    color: context.colors.bluePrimary,
                    size: AppSpacing.iconMd,
                  ),
                ),
                AppSpacing.hGapSm2,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تواصل مع الدعم الفني',
                      style: AppTextStyles.cardTitle(context.colors.textPrimary),
                    ),
                    Text(
                      'فريقنا جاهز لمساعدتك',
                      style: AppTextStyles.bodySmall(context.colors.textSecond),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          // Call
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_outlined,
                color: context.colors.success,
                size: AppSpacing.iconSm,
              ),
            ),
            title: Text(
              'اتصال مباشر',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            subtitle: Text(
              AppConstants.supportPhone,
              style: AppTextStyles.bodySmall(context.colors.textSecond),
            ),
            onTap: () {
              Navigator.pop(context);
              _call();
            },
          ),
          // WhatsApp
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Color(0x1A25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_outlined,
                color: Color(0xFF25D366),
                size: AppSpacing.iconSm,
              ),
            ),
            title: Text(
              'واتساب',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            subtitle: Text(
              'تواصل عبر واتساب',
              style: AppTextStyles.bodySmall(context.colors.textSecond),
            ),
            onTap: () {
              Navigator.pop(context);
              _whatsApp();
            },
          ),
          const SafeArea(top: false, child: AppSpacing.gapSm),
        ],
      ),
    );
  }
}
