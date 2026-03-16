import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../customer/services/data/quote_repository.dart';
import 'manager_quotes_screen.dart';

class ManagerQuoteDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ManagerQuoteDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<ManagerQuoteDetailScreen> createState() => _ManagerQuoteDetailScreenState();
}

class _ManagerQuoteDetailScreenState extends ConsumerState<ManagerQuoteDetailScreen> {
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _durationController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _detailsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _priceController.text.trim().isNotEmpty && 
           _detailsController.text.trim().isNotEmpty &&
           double.tryParse(_priceController.text.trim()) != null;
  }

  Future<void> _sendQuote() async {
    if (!_isFormValid()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(quoteRepositoryProvider);
      final price = double.parse(_priceController.text.trim());
      
      await repo.sendQuote(
        orderId: widget.orderId,
        price: price,
        details: _detailsController.text.trim(),
        duration: _durationController.text.trim().isNotEmpty ? _durationController.text.trim() : null,
      );
      
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(managerQuotesProvider);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تم الإرسال بنجاح'),
            content: const Text('تم إرسال عرض السعر للعميل لانتظار قبوله أو رفضه.'),
            actions: [
              TammButton(
                label: 'العودة للطلبات',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Go back
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل العرض'),
      body: orderAsync.when(
        data: (order) => _buildBody(order),
        loading: () => const TammLoading(),
        error: (err, stack) => Center(child: Text('حدث خطأ: $err')),
      ),
    );
  }

  Widget _buildBody(Order order) {
    final isPending = order.quoteStatus == 'pending';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Customer Request Details
                Text(
                  'التفاصيل من العميل',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(title: 'رقم الطلب', value: order.orderNumber),
                      const SizedBox(height: 8),
                      _DetailRow(title: 'الحالة', value: order.statusLabel),
                      const Divider(height: 24, color: AppColors.border),
                      Text(
                        'وصف الاحتياج والملاحظات:',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecond,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.notes ?? 'لا يوجد وصف',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: AppColors.bluePrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.address,
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Manager Response Form or Display Sent Details
                Text(
                  isPending ? 'تقديم عرض السعر' : 'العرض المُرسل',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (isPending) ...[
                  // Edit Form for Pending
                  TammTextField(
                    label: 'السعر الإجمالي للخدمة',
                    hint: '500',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState((){}),
                  ),
                  const SizedBox(height: 16),
                  TammTextField(
                    label: 'تفاصيل العرض وما يشمله',
                    hint: 'يشمل التركيب والمواد الأساسية...',
                    controller: _detailsController,
                    maxLines: 4,
                    onChanged: (val) => setState((){}),
                  ),
                  const SizedBox(height: 16),
                  TammTextField(
                    label: 'مدة التنفيذ التقديرية (اختياري)',
                    hint: 'مثال: ساعتين، يومين عمل...',
                    controller: _durationController,
                  ),
                ] else ...[
                  // Read-only Display for Sent/Accepted/Rejected
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.bluePrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          title: 'السعر المُرسل', 
                          value: '${order.quotePrice?.toInt() ?? 0} ر.س',
                          isBoldValue: true,
                          valueColor: AppColors.blueSky,
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        _DetailRow(
                          title: 'مدة التنفيذ', 
                          value: order.quoteDuration ?? 'لم تحدد',
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        Text(
                          'تفاصيل العرض:',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecond,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.quoteDetails ?? '',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (order.quoteStatus == 'rejected' && order.rejectionReason != null) ...[
                          const Divider(height: 24, color: AppColors.border),
                          Text(
                            'سبب الرفض من العميل:',
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.rejectionReason!,
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. Sticky Button
        if (isPending)
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: TammButton(
              label: 'إرسال العرض للعميل',
              icon: Icons.send,
              isLoading: _isSubmitting,
              onPressed: _isFormValid() ? _sendQuote : null,
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isBoldValue;
  final Color? valueColor;

  const _DetailRow({
    required this.title,
    required this.value,
    this.isBoldValue = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.harmattan(
            fontSize: 16,
            color: AppColors.textSecond,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.harmattan(
            fontSize: isBoldValue ? 20 : 16,
            fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
