import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class AppointmentPicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime date, String period, String? hour) onDateSelected;

  const AppointmentPicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<AppointmentPicker> createState() => _AppointmentPickerState();
}

class _AppointmentPickerState extends State<AppointmentPicker> {
  late List<DateTime> _days;
  DateTime? _selectedDate;
  String? _selectedPeriod;
  String? _selectedHour;

  final List<String> _periods = ['صباحاً', 'ظهراً', 'مساءً'];
  final Map<String, String> _periodTimes = {
    'صباحاً': '٨ص — ١٢م',
    'ظهراً': '١٢م — ٤م',
    'مساءً': '٤م — ٨م',
  };

  @override
  void initState() {
    super.initState();
    // 7 days starting from tomorrow
    final now = DateTime.now();
    _days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i + 1)),
    );

    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
    }
  }

  void _notifyChange() {
    if (_selectedDate != null && _selectedPeriod != null) {
      widget.onDateSelected(_selectedDate!, _selectedPeriod!, _selectedHour);
    }
  }

  List<String> _getHoursForPeriod(String period) {
    if (period == 'صباحاً') return ['٠٨:٠٠', '٠٩:٠٠', '١٠:٠٠', '١١:٠٠'];
    if (period == 'ظهراً') return ['١٢:٠٠', '٠١:٠٠', '٠٢:٠٠', '٠٣:٠٠'];
    if (period == 'مساءً') return ['٠٤:٠٠', '٠٥:٠٠', '٠٦:٠٠', '٠٧:٠٠'];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Days Selection
        Text(
          'اختر اليوم',
          style: GoogleFonts.harmattan(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = _days[i];
              final isSelected = _selectedDate == day;
              final dayName = DateFormat('EEEE', 'ar').format(day);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                    // Reset lower selections when day changes if needed
                    _notifyChange();
                  });
                },
                child: Container(
                  width: 65,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.bluePrimary : AppColors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(
                      color: isSelected ? AppColors.bluePrimary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName.substring(0, dayName.length > 4 ? 4 : dayName.length),
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: isSelected ? Colors.white : AppColors.textSecond,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: GoogleFonts.harmattan(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 2. Period Selection (only if date is selected)
        if (_selectedDate != null) ...[
          const SizedBox(height: 24),
          Text(
            'اختر الفترة',
            style: GoogleFonts.harmattan(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                      _selectedHour = null; // Reset hour when period changes
                      _notifyChange();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      left: period == _periods.last ? 0 : 8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.bluePrimary : AppColors.bgSurface,
                      borderRadius: AppSpacing.radiusSm,
                      border: Border.all(
                        color: isSelected ? AppColors.bluePrimary : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          period,
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _periodTimes[period]!,
                          style: GoogleFonts.harmattan(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : AppColors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // 3. Hour Selection (optional, only if period is selected)
        if (_selectedPeriod != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'اختر الوقت ',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '(اختياري)',
                style: GoogleFonts.harmattan(
                  fontSize: 14,
                  color: AppColors.textSecond,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getHoursForPeriod(_selectedPeriod!).map((hour) {
              final isSelected = _selectedHour == hour;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedHour = isSelected ? null : hour; // Toggle off if clicked again
                    _notifyChange();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 48 - 24) / 4, // 4 columns with padding
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.bluePrimary : AppColors.bgSurface,
                    borderRadius: AppSpacing.radiusSm,
                    border: Border.all(
                      color: isSelected ? AppColors.bluePrimary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hour,
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
