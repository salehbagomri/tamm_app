import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'حدث خطأ غير متوقع',
              style: AppTextStyles.bodySmall(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        title: Text(
          'تعيين فني',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        content: Consumer(
          builder: (context, ref, child) {
            final techsAsync = ref.watch(techniciansProvider);
            return techsAsync.when(
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
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                      subtitle: Text(
                        t['specialization'] ?? '',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: t['status'] == 'available'
                              ? context.colors.success.withValues(alpha: 0.15)
                              : context.colors.warning.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.radiusFull,
                        ),
                        child: Text(
                          t['status'] == 'available' ? 'متاح' : 'مشغول',
                          style: AppTextStyles.caption(
                            t['status'] == 'available'
                                ? context.colors.success
                                : context.colors.warning,
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
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              loading: () => const TammLoading(),
              error: (e, _) => ErrorStateWidget(
                message: e is AppException
                    ? e.message
                    : 'حدث خطأ في تحميل الفنيين',
                onRetry: () => ref.invalidate(techniciansProvider),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
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
                          style: AppTextStyles.sectionTitle(
                            context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          o.statusLabel,
                          style: AppTextStyles.body(context.colors.bluePrimary),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'العنوان: ${o.address}',
                      style: AppTextStyles.body(context.colors.textSecond),
                    ),
                    if (o.preferredDate != null)
                      Text(
                        'الموعد: ${o.preferredDate!.day}/${o.preferredDate!.month}',
                        style: AppTextStyles.body(context.colors.textSecond),
                      ),
                    if (o.notes != null && o.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'ملاحظات العميل: ${o.notes}',
                          style: AppTextStyles.body(context.colors.textSecond),
                        ),
                      ),
                    if (o.technicianNotes != null &&
                        o.technicianNotes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'تقرير الفني (${o.technicianName ?? 'غير معروف'}): ${o.technicianNotes}',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ),
                    Text(
                      'المجموع: ${o.totalAmount.toInt()} ر.س',
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              if (o.status == 'pending') ...[
                TammButton(
                  label: 'تأكيد الطلب',
                  isLoading: _loading,
                  onPressed: () => _updateStatus('confirmed'),
                ),
                AppSpacing.gapSm,
              ],
              if (o.status == 'confirmed') ...[
                TammButton(
                  label: 'تعيين فني',
                  icon: Icons.engineering,
                  onPressed: _showAssignDialog,
                ),
                AppSpacing.gapSm,
              ],
              if (o.status != 'completed' && o.status != 'cancelled') ...[
                TammButton(
                  label: 'إلغاء الطلب',
                  type: TammButtonType.secondary,
                  isLoading: _loading,
                  onPressed: () => _updateStatus('cancelled'),
                ),
              ],
            ],
          ),
        ),
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل الطلب',
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}
