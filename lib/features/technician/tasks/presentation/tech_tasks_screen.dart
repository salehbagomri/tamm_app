import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../shared/providers/technician_providers.dart';
import '../../../../core/widgets/tamm_notification_bell.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.todayTasks,
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                  const TammNotificationBell(),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const TammEmptyState(
                        icon: Icons.task_alt,
                        message: 'لا توجد مهام حالياً',
                      );
                    }
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
                                            ? context.colors.warning.withValues(
                                                alpha: 0.15,
                                              )
                                            : context.colors.bluePrimary
                                                  .withValues(alpha: 0.15),
                                        borderRadius: AppSpacing.radiusFull,
                                      ),
                                      child: Text(
                                        isStarted ? 'جاري التنفيذ' : 'جديدة',
                                        style: AppTextStyles.body(
                                          context.colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      order['order_number'] ?? '',
                                      style: AppTextStyles.body(
                                        context.colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  customer?['full_name'] ?? '',
                                  style: AppTextStyles.cardTitle(
                                    context.colors.textPrimary,
                                  ),
                                ),
                                AppSpacing.gapXs,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: context.colors.textSecond,
                                    ),
                                    AppSpacing.hGapXs,
                                    Expanded(
                                      child: Text(
                                        order['address'] ?? '',
                                        style: AppTextStyles.bodySmall(
                                          context.colors.textSecond,
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
                  error: (e, _) => ErrorStateWidget(
                    message: e is AppException
                        ? e.message
                        : 'حدث خطأ في تحميل المهام',
                    onRetry: () => ref.invalidate(myAssignmentsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
