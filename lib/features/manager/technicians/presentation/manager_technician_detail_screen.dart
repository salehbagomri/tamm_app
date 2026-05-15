import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/manager_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ManagerTechnicianDetailScreen extends ConsumerWidget {
  final String technicianId;
  const ManagerTechnicianDetailScreen({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(technicianDetailProvider(technicianId));

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'ملف الفني'),
      body: SafeArea(
        child: asyncData.when(
          data: (tech) {
            final profile = tech['profiles'] as Map<String, dynamic>?;
            final assignments = (tech['assignments'] as List<dynamic>?) ?? [];

            final totalCompleted = assignments
                .where((a) => a['status'] == 'completed')
                .length;
            final currentPending = assignments
                .where((a) => a['status'] != 'completed')
                .length;

            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(
                    context,
                    tech,
                    profile,
                    totalCompleted,
                    currentPending,
                  ),
                  AppSpacing.gapLg,
                  Text(
                    'سجل المهام (${assignments.length})',
                    style: AppTextStyles.sectionTitle(
                      context.colors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapMd,
                  if (assignments.isEmpty)
                    const TammEmptyState(
                      icon: Icons.assignment_outlined,
                      message: 'لا توجد مهام مسندة لهذا الفني حتى الآن.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assignments.length,
                      separatorBuilder: (_, __) => AppSpacing.gapSm2,
                      itemBuilder: (_, i) {
                        return _buildAssignmentCard(context, assignments[i]);
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const TammLoading(),
          error: (e, _) => ErrorStateWidget(
            message: e is AppException
                ? e.message
                : 'حدث خطأ في تحميل بيانات الفني',
            onRetry: () =>
                ref.invalidate(technicianDetailProvider(technicianId)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> tech,
    Map<String, dynamic>? profile,
    int totalCompleted,
    int currentPending,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.radiusXlValue),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: context.colors.blueDark,
            child: Text(
              profile?['full_name']?.toString().isNotEmpty == true
                  ? profile!['full_name'][0]
                  : '?',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
          ),
          AppSpacing.gapSm2,
          Text(
            profile?['full_name'] ?? 'بدون اسم',
            style: AppTextStyles.body(context.colors.textPrimary),
          ),
          Text(
            tech['specialization'] ?? '',
            style: AppTextStyles.body(context.colors.textSecond),
          ),
          AppSpacing.gapSm,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tech['status'] == 'available'
                  ? context.colors.success.withValues(alpha: 0.15)
                  : context.colors.warning.withValues(alpha: 0.15),
              borderRadius: AppSpacing.radiusFull,
            ),
            child: Text(
              tech['status'] == 'available'
                  ? 'الفني متاح حالياً'
                  : 'الفني مشغول بمهمة',
              style: AppTextStyles.bodySmall(
                tech['status'] == 'available'
                    ? context.colors.success
                    : context.colors.warning,
              ).copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  'المهام المكتملة',
                  totalCompleted.toString(),
                  context.colors.success,
                ),
              ),
              AppSpacing.hGapSm2,
              Expanded(
                child: _buildStatBox(
                  context,
                  'قيد التنفيذ',
                  currentPending.toString(),
                  context.colors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.radius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.body(context.colors.textPrimary)),
          Text(
            label,
            style: AppTextStyles.bodySmall(context.colors.textSecond),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    Map<String, dynamic> assignment,
  ) {
    final order = assignment['orders'] as Map<String, dynamic>?;
    final date = DateTime.tryParse(assignment['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('yyyy/MM/dd').format(date) : '';

    final st = assignment['status'];
    Color statusColor = context.colors.textFaint;
    String statusLabel = 'قيد الانتظار';

    if (st == 'started') {
      statusColor = context.colors.bluePrimary;
      statusLabel = 'جاري العمل';
    } else if (st == 'completed') {
      statusColor = context.colors.success;
      statusLabel = 'مكتملة';
    }

    return TammCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم الطلب: #${order?['id'].toString().substring(0, 5) ?? '...'}',
                style: AppTextStyles.bodySmall(
                  context.colors.textPrimary,
                ).copyWith(fontWeight: AppTextStyles.bold),
              ),
              Text(
                dateStr,
                style: AppTextStyles.caption(context.colors.textFaint),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            order?['address'] ?? 'بدون عنوان',
            style: AppTextStyles.body(context.colors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusLabel,
                style: AppTextStyles.bodySmall(
                  statusColor,
                ).copyWith(fontWeight: AppTextStyles.bold),
              ),
              if (assignment['notes'] != null)
                Icon(
                  Icons.comment,
                  size: 16,
                  color: context.colors.bluePrimary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
