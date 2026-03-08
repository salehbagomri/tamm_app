import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../shared/providers/technician_providers.dart';

class TechTasksScreen extends ConsumerStatefulWidget {
  const TechTasksScreen({super.key});

  @override
  ConsumerState<TechTasksScreen> createState() => _TechTasksScreenState();
}

class _TechTasksScreenState extends ConsumerState<TechTasksScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = Supabase.instance.client
        .channel('public:tech_assignments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          callback: (payload) {
            ref.invalidate(myAssignmentsProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(myAssignmentsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.todayTasks,
                style: GoogleFonts.harmattan(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty)
                      return const TammEmptyState(
                        icon: Icons.task_alt,
                        message: 'لا توجد مهام حالياً',
                      );
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(myAssignmentsProvider);
                        await ref.read(myAssignmentsProvider.future);
                      },
                      child: ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final a = tasks[i];
                          final order =
                              a['orders'] as Map<String, dynamic>? ?? {};
                          final customer =
                              order['profiles'] as Map<String, dynamic>?;
                          final isStarted = a['status'] == 'started';
                          return TammCard(
                            onTap: () =>
                                context.push('/technician/task/${a['id']}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isStarted
                                            ? AppColors.warning.withValues(
                                                alpha: 0.15,
                                              )
                                            : AppColors.bluePrimary.withValues(
                                                alpha: 0.15,
                                              ),
                                        borderRadius: AppSpacing.radiusFull,
                                      ),
                                      child: Text(
                                        isStarted ? 'جاري التنفيذ' : 'جديدة',
                                        style: GoogleFonts.harmattan(
                                          fontSize: 12,
                                          color: isStarted
                                              ? AppColors.warning
                                              : AppColors.bluePrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      order['order_number'] ?? '',
                                      style: GoogleFonts.harmattan(
                                        color: AppColors.textFaint,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  customer?['full_name'] ?? '',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.textSecond,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order['address'] ?? '',
                                        style: GoogleFonts.harmattan(
                                          fontSize: 14,
                                          color: AppColors.textSecond,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
