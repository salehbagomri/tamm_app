import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class TammDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime date) onDateSelected;

  const TammDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<TammDatePicker> createState() => _TammDatePickerState();
}

class _TammDatePickerState extends State<TammDatePicker> {
  late DateTime _displayMonth;
  DateTime? _selectedDate;
  late final DateTime _today;

  static const _arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  // RTL column order: أح=Sun(0,right) … سب=Sat(6,left)
  static const _dayAbbr = ['أح', 'ان', 'ثل', 'أر', 'خم', 'جم', 'سب'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _displayMonth = DateTime(now.year, now.month);
    _selectedDate = widget.initialDate != null
        ? DateTime(
            widget.initialDate!.year,
            widget.initialDate!.month,
            widget.initialDate!.day,
          )
        : null;
  }

  bool _canGoPrev() =>
      _displayMonth.isAfter(DateTime(_today.year, _today.month));

  void _prevMonth() {
    if (!_canGoPrev()) return;
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  // DateTime.weekday: 1=Mon … 7=Sun  →  column: 0=Sun … 6=Sat
  int _col(DateTime d) => d.weekday % 7;

  int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final y = _displayMonth.year;
    final m = _displayMonth.month;
    final totalDays = _daysInMonth(y, m);
    final offset = _col(DateTime(y, m, 1));
    final rows = ((offset + totalDays) / 7).ceil();

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Month navigation header ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // In RTL this appears on the RIGHT → previous month
              IconButton(
                onPressed: _canGoPrev() ? _prevMonth : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.chevron_right,
                  color: _canGoPrev()
                      ? context.colors.textPrimary
                      : context.colors.border,
                ),
              ),
              Text(
                '${_arabicMonths[m - 1]} $y',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              // In RTL this appears on the LEFT → next month
              IconButton(
                onPressed: _nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.chevron_left,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,

          // ── Day-of-week headers ─────────────────────────
          Row(
            children: _dayAbbr
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: AppTextStyles.caption(
                          context.colors.textSecond,
                        ).copyWith(fontWeight: AppTextStyles.medium),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          AppSpacing.gapXs,

          // ── Calendar grid ───────────────────────────────
          ...List.generate(rows, (rowIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: List.generate(7, (colIdx) {
                  final dayNum = rowIdx * 7 + colIdx - offset + 1;

                  if (dayNum < 1 || dayNum > totalDays) {
                    return const Expanded(child: SizedBox(height: 36));
                  }

                  final date = DateTime(y, m, dayNum);
                  final isToday = date == _today;
                  final isPast = date.isBefore(_today);
                  final isTappable = date.isAfter(_today);
                  final isSelected =
                      _selectedDate != null && date == _selectedDate;

                  final Color textColor;
                  if (isSelected) {
                    textColor = context.colors.bgSurface;
                  } else if (isPast) {
                    textColor = context.colors.border;
                  } else if (isToday) {
                    textColor = context.colors.bluePrimary;
                  } else {
                    textColor = context.colors.textPrimary;
                  }

                  final BoxDecoration? decoration;
                  if (isSelected) {
                    decoration = BoxDecoration(
                      color: context.colors.bluePrimary,
                      shape: BoxShape.circle,
                    );
                  } else if (isToday) {
                    decoration = BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.bluePrimary,
                        width: 1.5,
                      ),
                    );
                  } else {
                    decoration = null;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: isTappable
                          ? () {
                              setState(() => _selectedDate = date);
                              widget.onDateSelected(date);
                            }
                          : null,
                      child: Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: decoration,
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: AppTextStyles.body(textColor).copyWith(
                              fontWeight: (isSelected || isToday)
                                  ? AppTextStyles.semiBold
                                  : AppTextStyles.regular,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}
