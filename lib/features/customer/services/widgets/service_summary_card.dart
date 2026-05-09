import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/service_type.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ServiceSummaryCard extends StatelessWidget {
  final ServiceType service;
  final String locationText;
  final DateTime date;
  final String period;
  final String? hour;

  ServiceSummaryCard({
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, -5),
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
              color: context.colors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.miscellaneous_services,
            title: service.name,
            value: service.basePrice != null
                ? '${service.basePrice!.toInt()} ر.س'
                : 'يُحدد لاحقاً',
            valueColor: context.colors.blueSky,
          ),
          SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.calendar_today,
            title: 'الموعد',
            value: '$period ${hour ?? ''}',
          ),
          SizedBox(height: 8),
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
  final Color? valueColor;

  _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.colors.textSecond),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.harmattan(
            fontSize: 14,
            color: context.colors.textSecond,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.harmattan(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.colors.textPrimary,
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
