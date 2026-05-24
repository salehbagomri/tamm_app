import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/technician_providers.dart';

class TechHistoryScreen extends ConsumerWidget {
  const TechHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(completedAssignmentsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل المهام',
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: historyAsync.when(
                  loading: () => const TammLoading(),
                  error: (e, _) => ErrorStateWidget(
                    message: e is AppException
                        ? e.message
                        : 'حدث خطأ في تحميل السجل',
                    onRetry: () => ref.invalidate(completedAssignmentsProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const TammEmptyState(
                        icon: Icons.history_outlined,
                        message: 'لا توجد مهام مكتملة بعد',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(completedAssignmentsProvider);
                        await ref.read(completedAssignmentsProvider.future);
                      },
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _HistoryCard(assignment: items[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بطاقة مهمة مكتملة ───────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  const _HistoryCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final order = assignment['orders'] as Map<String, dynamic>? ?? {};
    final customer = order['profiles'] as Map<String, dynamic>?;
    final orderNumber = order['order_number']?.toString() ?? '';
    final customerName = customer?['full_name']?.toString() ?? 'غير معروف';
    final address = order['address']?.toString() ?? '';
    final orderType = order['order_type']?.toString() ?? 'service';
    final completedAt = assignment['completed_at'] as String?;
    final photoUrls = (assignment['photo_urls'] as List?)?.cast<String>() ?? [];

    final items = (order['order_items'] as List?) ?? const [];
    final hasInstall =
        (order['include_installation'] as bool? ?? false) ||
        items.any(
          (item) =>
              (item as Map<String, dynamic>)['include_installation'] == true,
        );

    final typeLabel = switch (orderType) {
      'product' => hasInstall ? 'توصيل وتركيب منتج' : 'توصيل منتج',
      'product_and_service' => 'منتج مع تركيب',
      'quote_request' => 'عرض سعر',
      'service' => 'خدمة',
      _ => 'مهمة',
    };

    return TammCard(
      onTap: () => context.push('/technician/task/${assignment['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // شارة مكتملة
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: context.colors.success.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.radiusFull,
                ),
                child: Text(
                  'مكتملة',
                  style: AppTextStyles.caption(
                    context.colors.success,
                  ).copyWith(fontWeight: AppTextStyles.semiBold),
                ),
              ),
              const Spacer(),
              Text(
                orderNumber,
                style: AppTextStyles.caption(context.colors.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            customerName,
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: context.colors.textSecond,
              ),
              AppSpacing.hGapXs,
              Expanded(
                child: Text(
                  address,
                  style: AppTextStyles.caption(context.colors.textSecond),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              // نوع الطلب
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.bgPrimary,
                  borderRadius: AppSpacing.radiusFull,
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  typeLabel,
                  style: AppTextStyles.caption(context.colors.textSecond),
                ),
              ),
              if (completedAt != null) ...[
                AppSpacing.hGapSm,
                Icon(
                  Icons.check_circle_outlined,
                  size: 12,
                  color: context.colors.success,
                ),
                AppSpacing.hGapXs,
                Text(
                  _formatDate(completedAt),
                  style: AppTextStyles.caption(context.colors.textFaint),
                ),
              ],
              const Spacer(),
              // مؤشر الصور
              if (photoUrls.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 13,
                      color: context.colors.bluePrimary,
                    ),
                    AppSpacing.hGapXs,
                    Text(
                      '${photoUrls.length}',
                      style: AppTextStyles.caption(context.colors.bluePrimary),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }
}
