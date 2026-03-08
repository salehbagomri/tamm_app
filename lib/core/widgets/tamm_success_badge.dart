import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// شارة "تمّ ✓" — تُستخدم في شاشات التأكيد
class TammSuccessBadge extends StatelessWidget {
  final String message;
  const TammSuccessBadge({super.key, this.message = 'تمّ ✓'});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.success, width: 3),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 56,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          style: GoogleFonts.harmattan(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
