import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/manager_providers.dart';

class ManagerTechnicianDetailScreen extends ConsumerWidget {
  final String technicianId;
  const ManagerTechnicianDetailScreen({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(technicianDetailProvider(technicianId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                    tech,
                    profile,
                    totalCompleted,
                    currentPending,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'سجل المهام (${assignments.length})',
                    style: GoogleFonts.harmattan(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (assignments.isEmpty)
                    const TammEmptyState(
                      icon: Icons.assignment,
                      message: 'لا توجد مهام مسندة لهذا الفني حتى الآن.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assignments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        return _buildAssignmentCard(assignments[i]);
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const TammLoading(),
          error: (e, _) =>
              TammEmptyState(icon: Icons.error_outline, message: 'حدث خطأ: $e'),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic> tech,
    Map<String, dynamic>? profile,
    int totalCompleted,
    int currentPending,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
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
            backgroundColor: AppColors.blueDark,
            child: Text(
              profile?['full_name']?.toString().isNotEmpty == true
                  ? profile!['full_name'][0]
                  : '?',
              style: GoogleFonts.harmattan(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile?['full_name'] ?? 'بدون اسم',
            style: GoogleFonts.harmattan(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            tech['specialization'] ?? '',
            style: GoogleFonts.harmattan(
              fontSize: 16,
              color: AppColors.textSecond,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tech['status'] == 'available'
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: AppSpacing.radiusFull,
            ),
            child: Text(
              tech['status'] == 'available'
                  ? 'الفني متاح حالياً'
                  : 'الفني مشغول بمهمة',
              style: GoogleFonts.harmattan(
                fontSize: 14,
                color: tech['status'] == 'available'
                    ? AppColors.success
                    : AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'المهام المكتملة',
                  totalCompleted.toString(),
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  'قيد التنفيذ',
                  currentPending.toString(),
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.radius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.harmattan(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.harmattan(
              fontSize: 14,
              color: AppColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final order = assignment['orders'] as Map<String, dynamic>?;
    final date = DateTime.tryParse(assignment['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('yyyy/MM/dd').format(date) : '';

    final st = assignment['status'];
    Color statusColor = AppColors.textFaint;
    String statusLabel = 'قيد الانتظار';

    if (st == 'started') {
      statusColor = AppColors.bluePrimary;
      statusLabel = 'جاري العمل';
    } else if (st == 'completed') {
      statusColor = AppColors.success;
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
                style: GoogleFonts.harmattan(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.harmattan(
                  fontSize: 12,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order?['address'] ?? 'بدون عنوان',
            style: GoogleFonts.harmattan(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusLabel,
                style: GoogleFonts.harmattan(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (assignment['notes'] != null)
                const Icon(
                  Icons.comment,
                  size: 16,
                  color: AppColors.bluePrimary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
