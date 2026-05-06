import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/order.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class QuoteOfferCard extends StatelessWidget {
  final Order order;

  QuoteOfferCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.quotePrice == null || order.quoteDetails == null) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.bluePrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: context.colors.bluePrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_offer, color: context.colors.bluePrimary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عرض السعر المقترح',
                      style: GoogleFonts.harmattan(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    if (order.quoteSentAt != null)
                      Text(
                        'مُرسل: ${DateFormat('yyyy/MM/dd HH:mm').format(order.quoteSentAt!)}',
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: context.colors.textSecond,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Price
          _BuildInfoRow(
            icon: Icons.payments_outlined,
            title: 'السعر الإجمالي',
            value: '${order.quotePrice!.toInt()} ر.س',
            valueColor: context.colors.blueSky,
            isBold: true,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.colors.border),
          ),
          
          // Duration
          if (order.quoteDuration != null && order.quoteDuration!.isNotEmpty) ...[
            _BuildInfoRow(
              icon: Icons.timer_outlined,
              title: 'مدة التنفيذ التقديرية',
              value: order.quoteDuration!,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.colors.border),
            ),
          ],

          // Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description_outlined, size: 20, color: context.colors.textSecond),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل العرض',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: context.colors.textSecond,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      order.quoteDetails!,
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Attachment
          if (order.quoteAttachmentUrl != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
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
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.05),
                  borderRadius: AppSpacing.radiusSm,
                  border: Border.all(color: context.colors.bluePrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.bluePrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.file_present, color: context.colors.bluePrimary, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرفق عرض السعر',
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          Text(
                            'اضغط لعرض الملف',
                            style: GoogleFonts.harmattan(
                              fontSize: 13,
                              color: context.colors.bluePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, color: context.colors.bluePrimary, size: 20),
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

  _BuildInfoRow({
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
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.harmattan(
            fontSize: 16,
            color: context.colors.textSecond,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: GoogleFonts.harmattan(
            fontSize: isBold ? 22 : 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
