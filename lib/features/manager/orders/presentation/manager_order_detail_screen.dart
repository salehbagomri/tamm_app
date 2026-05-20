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
import '../../../../shared/models/order.dart';
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
                        try {
                          await ref
                              .read(assignmentRepositoryProvider)
                              .assignTechnician(
                                orderId: widget.orderId,
                                technicianId: t['id'],
                              );
                          ref.invalidate(orderDetailProvider(widget.orderId));
                          ref.invalidate(allOrdersProvider(null));
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e is AppException
                                      ? e.message
                                      : 'فشل تعيين الفني، حاول مجدداً',
                                  style: AppTextStyles.bodySmall(
                                    context.colors.textPrimary,
                                  ),
                                ),
                                backgroundColor: context.colors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
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
              if (o.orderType != 'quote_request') ...[
                _PaymentSection(order: o),
                AppSpacing.gapMd,
              ],
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
                  icon: Icons.engineering_outlined,
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

class _PaymentSection extends ConsumerWidget {
  final Order order;
  const _PaymentSection({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCash = order.paymentType == 'cash';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        Container(
          width: double.infinity,
          padding: AppSpacing.cardPaddingSm,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: AppSpacing.radius,
            border: Border.all(color: context.colors.border),
          ),
          child: isCash
              ? Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: context.colors.bluePrimary,
                      size: AppSpacing.iconMd,
                    ),
                    AppSpacing.hGapSm2,
                    Text(
                      'كاش عند الاستلام',
                      style: AppTextStyles.body(context.colors.textPrimary)
                          .copyWith(fontWeight: AppTextStyles.semiBold),
                    ),
                  ],
                )
              : order.paymentMethodId != null
                  ? _MethodDisplay(
                      methodId: order.paymentMethodId!,
                      type: order.paymentType,
                    )
                  : Row(
                      children: [
                        Icon(
                          order.paymentType == 'bank'
                              ? Icons.account_balance_outlined
                              : Icons.account_balance_wallet_outlined,
                          color: context.colors.bluePrimary,
                          size: AppSpacing.iconMd,
                        ),
                        AppSpacing.hGapSm2,
                        Text(
                          order.paymentType == 'bank'
                              ? 'تحويل بنكي'
                              : 'محفظة إلكترونية',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _MethodDisplay extends ConsumerWidget {
  final String methodId;
  final String type;
  const _MethodDisplay({required this.methodId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodAsync = ref.watch(paymentMethodByIdProvider(methodId));
    final fallbackLabel =
        type == 'bank' ? 'تحويل بنكي' : 'محفظة إلكترونية';
    final fallbackIcon = type == 'bank'
        ? Icons.account_balance_outlined
        : Icons.account_balance_wallet_outlined;

    return methodAsync.when(
      data: (method) => Row(
        children: [
          Icon(fallbackIcon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method?['name'] as String? ?? fallbackLabel,
                  style: AppTextStyles.body(context.colors.textPrimary)
                      .copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                if (method?['account_number'] != null)
                  Text(
                    method!['account_number'] as String,
                    style: AppTextStyles.caption(context.colors.textSecond),
                  ),
                if (method?['account_name'] != null)
                  Text(
                    method!['account_name'] as String,
                    style: AppTextStyles.caption(context.colors.textSecond),
                  ),
              ],
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Icon(fallbackIcon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Icon(fallbackIcon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          Text(fallbackLabel, style: AppTextStyles.body(context.colors.textPrimary)),
        ],
      ),
    );
  }
}
