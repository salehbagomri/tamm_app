import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/review.dart';
import '../../../../shared/providers/review_providers.dart';

class ReviewCard extends ConsumerStatefulWidget {
  final String orderId;
  final String? technicianId;

  const ReviewCard({super.key, required this.orderId, this.technicianId});

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();
  Review? _localReview;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _selectedRating == 0) return;

    await ref
        .read(reviewSubmitProvider(widget.orderId).notifier)
        .submit(
          orderId: widget.orderId,
          customerId: userId,
          technicianId: widget.technicianId,
          rating: _selectedRating,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
        );

    if (!mounted) return;
    final submitState = ref.read(reviewSubmitProvider(widget.orderId));
    if (submitState.status == ReviewSubmitStatus.success) {
      setState(() {
        _localReview = Review(
          id: '',
          orderId: widget.orderId,
          customerId: userId,
          technicianId: widget.technicianId,
          rating: _selectedRating,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
          createdAt: DateTime.now(),
        );
      });
      ref.invalidate(orderReviewProvider(widget.orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(orderReviewProvider(widget.orderId));
    final submitState = ref.watch(reviewSubmitProvider(widget.orderId));
    final existingReview = _localReview ?? reviewAsync.valueOrNull;
    final isLoading = submitState.status == ReviewSubmitStatus.loading;

    return TammCard(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: existingReview != null
            ? _buildSuccessState(context, existingReview)
            : _buildFormState(context, isLoading, submitState.errorMessage),
      ),
    );
  }

  // ─── Form state ─────────────────────────────────────────────────────────────

  Widget _buildFormState(
    BuildContext context,
    bool isLoading,
    String? errorMessage,
  ) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_outline,
              color: context.colors.warning,
              size: AppSpacing.iconMd,
            ),
            AppSpacing.hGapSm,
            Text(
              'كيف كانت تجربتك؟',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
          ],
        ),
        AppSpacing.gapXs,
        Text(
          'ساعدنا بتقييم الخدمة لتحسين تجربتك',
          style: AppTextStyles.bodySmall(context.colors.textSecond),
        ),
        AppSpacing.gapMd,

        // Stars row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  star <= _selectedRating ? Icons.star : Icons.star_outline,
                  color: star <= _selectedRating
                      ? context.colors.warning
                      : context.colors.textFaint,
                  size: 32,
                ),
              ),
            );
          }),
        ),

        // Comment field — animates open when a star is selected
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _selectedRating > 0
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: TammTextField(
                    label: 'تعليقك',
                    hint: 'أخبرنا عن تجربتك (اختياري)',
                    controller: _commentCtrl,
                    maxLines: 3,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        if (errorMessage != null) ...[
          AppSpacing.gapSm,
          Text(
            errorMessage,
            style: AppTextStyles.bodySmall(context.colors.error),
          ),
        ],

        AppSpacing.gapMd,
        TammButton(
          label: 'إرسال التقييم',
          icon: Icons.send_outlined,
          onPressed: _selectedRating > 0 && !isLoading ? _submit : null,
          isLoading: isLoading,
        ),
      ],
    );
  }

  // ─── Success state ───────────────────────────────────────────────────────────

  Widget _buildSuccessState(BuildContext context, Review review) {
    return Column(
      key: const ValueKey('success'),
      children: [
        Icon(
          Icons.check_circle_outlined,
          color: context.colors.success,
          size: AppSpacing.iconXl,
        ),
        AppSpacing.gapSm,
        Text(
          'شكراً على تقييمك! 🌟',
          style: AppTextStyles.cardTitle(context.colors.success),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapSm,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs / 2,
              ),
              child: Icon(
                i < review.rating ? Icons.star : Icons.star_outline,
                color: i < review.rating
                    ? context.colors.warning
                    : context.colors.textFaint,
                size: 24,
              ),
            ),
          ),
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text(
            review.comment!,
            style: AppTextStyles.body(context.colors.textSecond),
            textAlign: TextAlign.center,
          ),
        ],
        AppSpacing.gapXs,
        Text(
          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
          style: AppTextStyles.caption(context.colors.textFaint),
        ),
      ],
    );
  }
}
