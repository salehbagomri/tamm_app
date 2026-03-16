import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/providers/order_providers.dart';
import '../data/quote_repository.dart';
import '../widgets/quote_offer_card.dart';

class QuoteResponseScreen extends ConsumerStatefulWidget {
  final String orderId;

  const QuoteResponseScreen({super.key, required this.orderId});

  @override
  ConsumerState<QuoteResponseScreen> createState() => _QuoteResponseScreenState();
}

class _QuoteResponseScreenState extends ConsumerState<QuoteResponseScreen> {
  bool _isSaving = false;

  Future<void> _acceptQuote() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(quoteRepositoryProvider);
      await repo.acceptQuote(widget.orderId);
      
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تم قبول العرض'),
            content: const Text('تم تأكيد طلبك بنجاح. سنتواصل معك لترتيب موعد التنفيذ قريباً.'),
            actions: [
              TammButton(
                label: 'حسناً',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pushReplacement('/customer/order/${widget.orderId}'); // Go back to order details showing confirmed status
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _rejectQuote() async {
    final reasonController = TextEditingController();
    
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض العرض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من رغبتك في رفض هذا العرض؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'أخبرنا بالسبب (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الرفض', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      setState(() => _isSaving = true);
      try {
        final repo = ref.read(quoteRepositoryProvider);
        await repo.rejectQuote(widget.orderId, reason: reasonController.text.trim());
        
        ref.invalidate(orderDetailProvider(widget.orderId));
        ref.invalidate(myOrdersProvider);
        
        if (mounted) {
          context.pushReplacement('/customer/order/${widget.orderId}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'رد على عرض السعر'),
      body: orderAsync.when(
        data: (order) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuoteOfferCard(order: order),
                      const SizedBox(height: 32),
                      
                      Text(
                         'تفاصيل طلبك الأصلي',
                         style: GoogleFonts.harmattan(
                           fontSize: 18,
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
                        child: Text(
                          order.notes ?? 'لا توجد ملاحظات من طرفك.',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            color: AppColors.textSecond,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (order.quoteStatus == 'sent')
                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Column(
                    children: [
                      TammButton(
                        label: 'قبول العرض ✓',
                        isLoading: _isSaving,
                        onPressed: _acceptQuote,
                      ),
                      const SizedBox(height: 12),
                      TammButton(
                        label: 'رفض العرض',
                        type: TammButtonType.secondary,
                        isLoading: _isSaving,
                        onPressed: _rejectQuote,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const TammLoading(),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}
