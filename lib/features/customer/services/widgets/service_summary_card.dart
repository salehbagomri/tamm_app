import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/service_type.dart';

class ServiceSummaryCard extends StatelessWidget {
  final ServiceType service;
  final String locationText;
  final DateTime date;
  final String period;
  final String? hour;

  const ServiceSummaryCard({
    super.key,
    required this.service,
    required this.locationText,
    required this.date,
    required this.period,
    this.hour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.harmattan(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.miscellaneous_services,
            title: service.name,
            value: service.basePrice != null 
                ? '${service.basePrice!.toInt()} ر.س' 
                : 'يُحدد لاحقاً',
            valueColor: AppColors.blueSky,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.calendar_today,
            title: 'الموعد',
            value: '$period ${hour ?? ''}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.location_on,
            title: 'الموقع',
            value: locationText.isEmpty ? 'لم يحدد بعد' : locationText,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecond),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.harmattan(
            fontSize: 14,
            color: AppColors.textSecond,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.harmattan(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
