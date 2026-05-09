import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/manager_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الفنيين',
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: techsAsync.when(
                  data: (techs) {
                    if (techs.isEmpty) {
                      return const TammEmptyState(
                        icon: Icons.engineering,
                        message: 'لا يوجد فنيون',
                      );
                    }
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
                                  backgroundColor: context.colors.blueDark,
                                  child: Text(
                                    p?['full_name']?.toString().isNotEmpty ==
                                            true
                                        ? p!['full_name'][0]
                                        : '?',
                                    style: AppTextStyles.body(
                                      context.colors.textPrimary,
                                    ),
                                  ),
                                ),
                                AppSpacing.hGapSm2,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p?['full_name'] ?? '',
                                        style: AppTextStyles.body(
                                          context.colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        t['specialization'] ?? '',
                                        style: AppTextStyles.bodySmall(
                                          context.colors.textSecond,
                                        ),
                                      ),
                                      Text(
                                        t['phone'] ?? '',
                                        style: AppTextStyles.body(
                                          context.colors.textPrimary,
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
                                        ? context.colors.success.withValues(
                                            alpha: 0.15,
                                          )
                                        : context.colors.warning.withValues(
                                            alpha: 0.15,
                                          ),
                                    borderRadius: AppSpacing.radiusFull,
                                  ),
                                  child: Text(
                                    t['status'] == 'available'
                                        ? 'متاح'
                                        : 'مشغول',
                                    style: AppTextStyles.body(
                                      context.colors.textPrimary,
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
                  error: (e, _) => ErrorStateWidget(
                    message: e is AppException
                        ? e.message
                        : 'حدث خطأ في تحميل الفنيين',
                    onRetry: () => ref.invalidate(techniciansProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.colors.bluePrimary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'إضافة فني',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        onPressed: () async {
          await context.push('/manager/add-technician');
          ref.invalidate(techniciansProvider);
        },
      ),
    );
  }
}
