import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/order.dart';

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: AppColors.bluePrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.1),
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
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer, color: AppColors.bluePrimary),
              ),
              const SizedBox(width: 12),
              Text(
                'عرض السعر المقترح',
                style: GoogleFonts.harmattan(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
            valueColor: AppColors.blueSky,
            isBold: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          
          // Duration
          if (order.quoteDuration != null && order.quoteDuration!.isNotEmpty) ...[
            _BuildInfoRow(
              icon: Icons.timer_outlined,
              title: 'مدة التنفيذ التقديرية',
              value: order.quoteDuration!,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
          ],

          // Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_outlined, size: 20, color: AppColors.textSecond),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل العرض',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: AppColors.textSecond,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.quoteDetails!,
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _BuildInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecond),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.harmattan(
            fontSize: 16,
            color: AppColors.textSecond,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.harmattan(
            fontSize: isBold ? 22 : 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
