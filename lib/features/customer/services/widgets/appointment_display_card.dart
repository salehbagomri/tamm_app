import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(10),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موعدك المختار',
                  style: GoogleFonts.harmattan(
                    fontSize: 14,
                    color: context.colors.textSecond,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName — $period ${hour != null ? '— $hour' : ''}',
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
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
