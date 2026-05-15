import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../../../shared/models/service_type.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(top: BorderSide(color: context.colors.border)),
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
            style: AppTextStyles.body(
              context.colors.textPrimary,
            ).copyWith(fontWeight: AppTextStyles.bold),
          ),
          AppSpacing.gapSm2,
          _SummaryRow(
            icon: Icons.miscellaneous_services_outlined,
            title: service.name,
            value: service.basePrice != null
                ? '${service.basePrice!.toInt()} ر.س'
                : 'يُحدد لاحقاً',
            valueColor: context.colors.blueSky,
          ),
          AppSpacing.gapSm,
          _SummaryRow(
            icon: Icons.calendar_today_outlined,
            title: 'الموعد',
            value: '$period ${hour ?? ''}',
          ),
          AppSpacing.gapSm,
          _SummaryRow(
            icon: Icons.location_on_outlined,
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

  const _SummaryRow({
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
        AppSpacing.hGapSm,
        Text(title, style: AppTextStyles.bodySmall(context.colors.textSecond)),
        AppSpacing.hGapSm2,
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall(
              valueColor ?? context.colors.textPrimary,
            ).copyWith(fontWeight: AppTextStyles.bold),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
