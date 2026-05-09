import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/order.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class QuoteOfferCard extends StatelessWidget {
  final Order order;

  const QuoteOfferCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.quotePrice == null || order.quoteDetails == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.radiusXlValue),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.bluePrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: context.colors.bluePrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_offer,
                  color: context.colors.bluePrimary,
                ),
              ),
              AppSpacing.hGapSm2,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عرض السعر المقترح',
                      style: AppTextStyles.sectionTitle(
                        context.colors.textPrimary,
                      ),
                    ),
                    if (order.quoteSentAt != null)
                      Text(
                        'مُرسل: ${DateFormat('yyyy/MM/dd HH:mm').format(order.quoteSentAt!)}',
                        style: AppTextStyles.bodySmall(
                          context.colors.textSecond,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price
          _BuildInfoRow(
            icon: Icons.payments_outlined,
            title: 'السعر الإجمالي',
            value: '${order.quotePrice!.toInt()} ر.س',
            valueColor: context.colors.blueSky,
            isBold: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.colors.border),
          ),

          // Duration
          if (order.quoteDuration != null &&
              order.quoteDuration!.isNotEmpty) ...[
            _BuildInfoRow(
              icon: Icons.timer_outlined,
              title: 'مدة التنفيذ التقديرية',
              value: order.quoteDuration!,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.colors.border),
            ),
          ],

          // Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: context.colors.textSecond,
              ),
              AppSpacing.hGapSm2,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل العرض',
                      style: AppTextStyles.body(context.colors.textSecond),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      order.quoteDetails!,
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Attachment
          if (order.quoteAttachmentUrl != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.colors.border),
            ),
            InkWell(
              onTap: () async {
                final url = Uri.parse(order.quoteAttachmentUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: AppSpacing.radiusSm,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.05),
                  borderRadius: AppSpacing.radiusSm,
                  border: Border.all(
                    color: context.colors.bluePrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.bluePrimary.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.file_present,
                        color: context.colors.bluePrimary,
                        size: 20,
                      ),
                    ),
                    AppSpacing.hGapSm2,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرفق عرض السعر',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ).copyWith(fontWeight: AppTextStyles.bold),
                          ),
                          Text(
                            'اضغط لعرض الملف',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      color: context.colors.bluePrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuildInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _BuildInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.textSecond),
        AppSpacing.hGapSm2,
        Text(title, style: AppTextStyles.body(context.colors.textSecond)),
        const Spacer(),
        Text(value, style: AppTextStyles.body(context.colors.textPrimary)),
      ],
    );
  }
}
