import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/manager_providers.dart';

class TechniciansScreen extends ConsumerWidget {
  const TechniciansScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techsAsync = ref.watch(techniciansProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الفنيين',
                style: GoogleFonts.harmattan(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: techsAsync.when(
                  data: (techs) {
                    if (techs.isEmpty)
                      return const TammEmptyState(
                        icon: Icons.engineering,
                        message: 'لا يوجد فنيون',
                      );
                    return ListView.separated(
                      itemCount: techs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final t = techs[i];
                        final p = t['profiles'] as Map<String, dynamic>?;
                        return TammCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.blueDark,
                                child: Text(
                                  p?['full_name']?.toString().isNotEmpty == true
                                      ? p!['full_name'][0]
                                      : '?',
                                  style: GoogleFonts.harmattan(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p?['full_name'] ?? '',
                                      style: GoogleFonts.harmattan(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      t['specialization'] ?? '',
                                      style: GoogleFonts.harmattan(
                                        fontSize: 14,
                                        color: AppColors.textSecond,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: t['status'] == 'available'
                                      ? AppColors.success.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.warning.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: AppSpacing.radiusFull,
                                ),
                                child: Text(
                                  t['status'] == 'available' ? 'متاح' : 'مشغول',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 12,
                                    color: t['status'] == 'available'
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const TammLoading(),
                  error: (e, _) =>
                      TammEmptyState(icon: Icons.error_outline, message: '$e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
