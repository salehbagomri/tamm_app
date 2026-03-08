import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/manager_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class TechniciansScreen extends ConsumerStatefulWidget {
  const TechniciansScreen({super.key});
  @override
  ConsumerState<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends ConsumerState<TechniciansScreen> {
  RealtimeChannel? _techsChannel;

  @override
  void initState() {
    super.initState();
    _techsChannel = Supabase.instance.client
        .channel('public:technicians_manager')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'technicians',
          callback: (_) {
            ref.invalidate(techniciansProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_techsChannel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(techniciansProvider);
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: techs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final t = techs[i];
                          final p = t['profiles'] as Map<String, dynamic>?;
                          return TammCard(
                            onTap: () =>
                                context.push('/manager/technicians/${t['id']}'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.blueDark,
                                  child: Text(
                                    p?['full_name']?.toString().isNotEmpty ==
                                            true
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Text(
                                        t['phone'] ?? '',
                                        style: GoogleFonts.harmattan(
                                          fontSize: 13,
                                          color: AppColors.textFaint,
                                          letterSpacing: 1,
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
                                    t['status'] == 'available'
                                        ? 'متاح'
                                        : 'مشغول',
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
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.bluePrimary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'إضافة فني',
          style: GoogleFonts.harmattan(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          await context.push('/manager/add-technician');
          ref.invalidate(techniciansProvider);
        },
      ),
    );
  }
}
