import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../shared/providers/order_providers.dart';
import '../data/quote_repository.dart';
import '../widgets/quote_offer_card.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class QuoteResponseScreen extends ConsumerStatefulWidget {
  final String orderId;

  const QuoteResponseScreen({super.key, required this.orderId});

  @override
  ConsumerState<QuoteResponseScreen> createState() =>
      _QuoteResponseScreenState();
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
            title: Text(
              'تم قبول العرض',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            content: Text(
              'تم تأكيد طلبك بنجاح. سنتواصل معك لترتيب موعد التنفيذ قريباً.',
              style: AppTextStyles.body(context.colors.textSecond),
            ),
            actions: [
              TammButton(
                label: 'حسناً',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pushReplacement(
                    '/customer/order/${widget.orderId}',
                  ); // Go back to order details showing confirmed status
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'حدث خطأ في قبول العرض',
              style: AppTextStyles.bodySmall(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
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
            AppSpacing.gapMd,
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
            child: Text(
              'تأكيد الرفض',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      setState(() => _isSaving = true);
      try {
        final repo = ref.read(quoteRepositoryProvider);
        await repo.rejectQuote(
          widget.orderId,
          reason: reasonController.text.trim(),
        );

        ref.invalidate(orderDetailProvider(widget.orderId));
        ref.invalidate(myOrdersProvider);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                'تم إرسال الرفض',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              content: Text(
                'تم إرسال رفضك للمدير. سيتم مراجعته وإرسال عرض جديد قريباً.',
                style: AppTextStyles.body(context.colors.textSecond),
              ),
              actions: [
                TammButton(
                  label: 'حسناً',
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    context.pushReplacement(
                      '/customer/order/${widget.orderId}',
                    );
                  },
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is AppException ? e.message : 'حدث خطأ في رفض العرض',
                style: AppTextStyles.bodySmall(context.colors.textPrimary),
              ),
              backgroundColor: context.colors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
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
      backgroundColor: context.colors.bgPrimary,
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
                      AppSpacing.gapXl,

                      Text(
                        'تفاصيل طلبك الأصلي',
                        style: AppTextStyles.cardTitle(
                          context.colors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapSm2,

                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: context.colors.bgSurface,
                          borderRadius: AppSpacing.radiusLg,
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Text(
                          order.notes ?? 'لا توجد ملاحظات من طرفك.',
                          style: AppTextStyles.body(context.colors.textPrimary),
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
                    color: context.colors.bgSurface,
                    border: Border(
                      top: BorderSide(color: context.colors.border),
                    ),
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
                      AppSpacing.gapSm2,
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
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل العرض',
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}
