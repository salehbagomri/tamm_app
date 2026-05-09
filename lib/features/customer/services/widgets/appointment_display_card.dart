import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_spacing.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class AppointmentDisplayCard extends StatelessWidget {
  final DateTime date;
  final String period;
  final String? hour;

  const AppointmentDisplayCard({
    super.key,
    required this.date,
    required this.period,
    this.hour,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE d MMMM', 'ar').format(date);

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.bluePrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: AppSpacing.iconCirclePadding,
            decoration: BoxDecoration(
              color: context.colors.bluePrimary.withValues(alpha: 0.1),
              borderRadius: AppSpacing.radiusSm,
            ),
            child: Icon(
              Icons.calendar_today,
              color: context.colors.bluePrimary,
              size: 24,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موعدك المختار',
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName — $period ${hour != null ? '— $hour' : ''}',
                  style: AppTextStyles.body(
                    context.colors.textPrimary,
                  ).copyWith(fontWeight: AppTextStyles.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
