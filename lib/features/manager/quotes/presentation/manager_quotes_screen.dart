import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/order.dart';
import '../../../customer/services/data/quote_repository.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

final managerQuotesProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final repo = ref.watch(quoteRepositoryProvider);
  return repo.getQuoteRequests();
});

class ManagerQuotesScreen extends ConsumerStatefulWidget {
  const ManagerQuotesScreen({super.key});

  @override
  ConsumerState<ManagerQuotesScreen> createState() => _ManagerQuotesScreenState();
}

class _ManagerQuotesScreenState extends ConsumerState<ManagerQuotesScreen> with SingleTickerProviderStateMixin {
  RealtimeChannel? _channel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // إعادة جلب البيانات فور فتح الشاشة (مهم عند العودة من شاشة التفاصيل)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(managerQuotesProvider);
    });

    // Realtime: تحديث تلقائي عند أي تغيير في طلبات العروض
    _channel = Supabase.instance.client
        .channel('public:quotes_list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            ref.invalidate(managerQuotesProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(managerQuotesProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: TammAppBar(
        title: 'طلبات عروض الأسعار',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: context.colors.bluePrimary,
          unselectedLabelColor: context.colors.textSecond,
          indicatorColor: context.colors.bluePrimary,
          labelStyle: GoogleFonts.harmattan(fontWeight: FontWeight.w700, fontSize: 16),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'معلقة'),
            Tab(text: 'مرسلة'),
            Tab(text: 'مقبولة'),
            Tab(text: 'مرفوضة'),
          ],
        ),
      ),
      body: quotesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return const TammEmptyState(
              icon: Icons.request_quote_outlined,
              message: 'لا توجد طلبات عروض أسعار حالياً',
            );
          }

          final pendingQuotes = quotes.where((q) => q.quoteStatus == 'pending').toList();
          final sentQuotes = quotes.where((q) => q.quoteStatus == 'sent').toList();
          final acceptedQuotes = quotes.where((q) => q.quoteStatus == 'accepted').toList();
          final rejectedQuotes = quotes.where((q) => q.quoteStatus == 'rejected').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(quotes),
              _buildList(pendingQuotes),
              _buildList(sentQuotes),
              _buildList(acceptedQuotes),
              _buildList(rejectedQuotes),
            ],
          );
        },
        loading: () => const TammLoading(),
        error: (err, stack) => Center(child: Text('حدث خطأ: $err')),
      ),
    );
  }

  Widget _buildList(List<Order> quotes) {
    if (quotes.isEmpty) {
       return const TammEmptyState(
         icon: Icons.playlist_remove,
         message: 'لا توجد طلبات في هذي القائمة',
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
          return _QuoteRequestCard(
            order: order,
            onTap: () async {
              await context.push('/manager/quote/${order.id}');
              // عند العودة من شاشة التفاصيل، أعد جلب البيانات
              ref.invalidate(managerQuotesProvider);
            },
          );
        },
      ),
    );
  }
}

class _QuoteRequestCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _QuoteRequestCard({required this.order, required this.onTap});

  Color _getStatusColor(BuildContext context, String? status) {
    if (status == 'pending') return context.colors.warning;
    if (status == 'sent') return context.colors.bluePrimary;
    if (status == 'accepted') return context.colors.success;
    if (status == 'rejected') return context.colors.error;
    return context.colors.textSecond;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, order.quoteStatus);
    final needsAction = order.quoteStatus == 'pending' || order.quoteStatus == 'rejected';

    return TammCard(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
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
                      color: context.colors.textSecond,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.radiusSm,
                    ),
                    child: Text(
                      order.quoteStatusLabel,
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
                  Icon(Icons.person, size: 16, color: context.colors.bluePrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerProfile?['full_name'] ?? 'عميل',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: context.colors.textSecond),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.address,
                      style: GoogleFonts.harmattan(
                        fontSize: 15,
                        color: context.colors.textPrimary,
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
                  color: context.colors.textSecond,
                ),
              ),
            ],
          ),
          if (needsAction)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high, size: 12, color: Colors.white),
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
