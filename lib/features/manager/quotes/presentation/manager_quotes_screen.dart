import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/order.dart';
import '../../../customer/services/data/quote_repository.dart';

final managerQuotesProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final repo = ref.watch(quoteRepositoryProvider);
  return repo.getQuoteRequests();
});

class ManagerQuotesScreen extends ConsumerWidget {
  const ManagerQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(managerQuotesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(
        title: 'طلبات عروض الأسعار',
      ),
      body: quotesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return const TammEmptyState(
              icon: Icons.request_quote_outlined,
              message: 'لا توجد طلبات عروض أسعار حالياً',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(managerQuotesProvider);
              await ref.read(managerQuotesProvider.future);
            },
            child: ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = quotes[index];
                return _QuoteRequestCard(order: order);
              },
            ),
          );
        },
        loading: () => const TammLoading(),
        error: (err, stack) => Center(child: Text('حدث خطأ: $err')),
      ),
    );
  }
}

class _QuoteRequestCard extends StatelessWidget {
  final Order order;

  const _QuoteRequestCard({required this.order});

  Color _getStatusColor(String? status) {
    if (status == 'pending') return AppColors.warning;
    if (status == 'sent') return AppColors.bluePrimary;
    if (status == 'accepted') return AppColors.success;
    if (status == 'rejected') return AppColors.error;
    return AppColors.textSecond;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.quoteStatus);

    return TammCard(
      onTap: () => context.push('/manager/quote/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم الطلب: ${order.orderNumber}',
                style: GoogleFonts.harmattan(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecond,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.radiusSm,
                ),
                child: Text(
                  order.statusLabel,
                  style: GoogleFonts.harmattan(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.textSecond),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.address,
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'منذ: ${_formatDate(order.createdAt)}',
            style: GoogleFonts.harmattan(
              fontSize: 14,
              color: AppColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
