import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/providers/manager_providers.dart';

class ManagerOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ManagerOrderDetailScreen({super.key, required this.orderId});
  @override
  ConsumerState<ManagerOrderDetailScreen> createState() =>
      _ManagerOrderDetailScreenState();
}

class _ManagerOrderDetailScreenState
    extends ConsumerState<ManagerOrderDetailScreen> {
  bool _loading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(widget.orderId, status);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(allOrdersProvider(null));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAssignDialog() {
    final techsAsync = ref.read(techniciansProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'تعيين فني',
          style: GoogleFonts.harmattan(color: AppColors.textPrimary),
        ),
        content: techsAsync.when(
          data: (techs) => SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: techs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final t = techs[i];
                final p = t['profiles'] as Map<String, dynamic>?;
                return ListTile(
                  title: Text(
                    p?['full_name'] ?? '',
                    style: GoogleFonts.harmattan(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    t['specialization'] ?? '',
                    style: GoogleFonts.harmattan(
                      color: AppColors.textSecond,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t['status'] == 'available'
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Text(
                      t['status'] == 'available' ? 'متاح' : 'مشغول',
                      style: GoogleFonts.harmattan(
                        fontSize: 12,
                        color: t['status'] == 'available'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                  onTap: () async {
                    await ref
                        .read(assignmentRepositoryProvider)
                        .assignTechnician(
                          orderId: widget.orderId,
                          technicianId: t['id'],
                        );
                    ref.invalidate(orderDetailProvider(widget.orderId));
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          loading: () => const TammLoading(),
          error: (e, _) => Text('$e'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل الطلب'),
      body: orderAsync.when(
        data: (o) => SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TammCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          o.orderNumber,
                          style: GoogleFonts.harmattan(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          o.statusLabel,
                          style: GoogleFonts.harmattan(
                            color: AppColors.bluePrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'العنوان: ${o.address}',
                      style: GoogleFonts.harmattan(color: AppColors.textSecond),
                    ),
                    if (o.preferredDate != null)
                      Text(
                        'الموعد: ${o.preferredDate!.day}/${o.preferredDate!.month}',
                        style: GoogleFonts.harmattan(
                          color: AppColors.textSecond,
                        ),
                      ),
                    Text(
                      'المجموع: ${o.totalAmount.toInt()} ريال',
                      style: GoogleFonts.harmattan(
                        color: AppColors.blueSky,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (o.status == 'pending') ...[
                TammButton(
                  label: 'تأكيد الطلب',
                  isLoading: _loading,
                  onPressed: () => _updateStatus('confirmed'),
                ),
                const SizedBox(height: 8),
              ],
              if (o.status == 'confirmed') ...[
                TammButton(
                  label: 'تعيين فني',
                  icon: Icons.engineering,
                  onPressed: _showAssignDialog,
                ),
                const SizedBox(height: 8),
              ],
              if (o.status != 'completed' && o.status != 'cancelled') ...[
                TammButton(
                  label: 'إلغاء الطلب',
                  isOutlined: true,
                  isLoading: _loading,
                  onPressed: () => _updateStatus('cancelled'),
                ),
              ],
            ],
          ),
        ),
        loading: () => const TammLoading(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
