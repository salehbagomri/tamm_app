import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerOrdersScreen extends ConsumerStatefulWidget {
  const ManagerOrdersScreen({super.key});
  @override
  ConsumerState<ManagerOrdersScreen> createState() =>
      _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends ConsumerState<ManagerOrdersScreen> {
  String? _statusFilter;
  final _filters = const {
    null: 'الكل',
    'pending': 'معلق',
    'confirmed': 'مؤكد',
    'assigned': 'معيّن',
    'in_progress': 'جاري',
    'completed': 'مكتمل',
  };

  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    // استماع للتغييرات الفورية في جدول الطلبات (Realtime)
    _ordersChannel = Supabase.instance.client
        .channel('public:orders_manager')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            // تحديث الشاشة تلقائياً عند أي تغيير (إضافة، تعديل، حذف) بجدول الطلبات
            ref.invalidate(allOrdersProvider(null));
            ref.invalidate(allOrdersProvider(_statusFilter));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_ordersChannel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider(_statusFilter));
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'إدارة الطلبات',
                style: GoogleFonts.harmattan(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filters.entries.map((e) {
                  final sel = _statusFilter == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        e.value,
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: sel ? Colors.white : AppColors.textSecond,
                        ),
                      ),
                      selected: sel,
                      selectedColor: AppColors.bluePrimary,
                      backgroundColor: AppColors.bgSurface,
                      side: BorderSide(
                        color: sel ? AppColors.bluePrimary : AppColors.border,
                      ),
                      onSelected: (_) => setState(() => _statusFilter = e.key),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return const TammEmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'لا توجد طلبات',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(allOrdersProvider(null));
                      ref.invalidate(allOrdersProvider(_statusFilter));
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.pagePadding,
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final o = orders[i];
                        final customer = o.customerProfile;
                        return TammCard(
                          onTap: () => context.push('/manager/order/${o.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    o.orderNumber,
                                    style: GoogleFonts.harmattan(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bluePrimary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: AppSpacing.radiusFull,
                                    ),
                                    child: Text(
                                      o.statusLabel,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 12,
                                        color: AppColors.bluePrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (customer != null)
                                Text(
                                  customer['full_name'] ?? '',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 14,
                                    color: AppColors.textSecond,
                                  ),
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    o.address,
                                    style: GoogleFonts.harmattan(
                                      fontSize: 13,
                                      color: AppColors.textFaint,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${o.totalAmount.toInt()} ريال',
                                    style: GoogleFonts.harmattan(
                                      color: AppColors.blueSky,
                                      fontWeight: FontWeight.w700,
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
    );
  }
}
