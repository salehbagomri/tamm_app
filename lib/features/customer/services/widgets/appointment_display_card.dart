import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.1),
              borderRadius: AppSpacing.radiusSm,
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.bluePrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موعدك المختار',
                  style: GoogleFonts.harmattan(
                    fontSize: 14,
                    color: AppColors.textSecond,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName — $period ${hour != null ? '— $hour' : ''}',
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
