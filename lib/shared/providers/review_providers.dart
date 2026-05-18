import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../features/customer/profile/data/review_repository.dart';
import '../models/review.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

final orderReviewProvider =
    FutureProvider.autoDispose.family<Review?, String>((ref, orderId) async {
      return ref.read(reviewRepositoryProvider).getReviewByOrderId(orderId);
    });

// ─── Submit state ─────────────────────────────────────────────────────────────

enum ReviewSubmitStatus { idle, loading, success, error }

class ReviewSubmitState {
  final ReviewSubmitStatus status;
  final String? errorMessage;

  const ReviewSubmitState({
    this.status = ReviewSubmitStatus.idle,
    this.errorMessage,
  });
}

class ReviewSubmitNotifier extends StateNotifier<ReviewSubmitState> {
  final ReviewRepository _repo;

  ReviewSubmitNotifier(this._repo) : super(const ReviewSubmitState());

  Future<void> submit({
    required String orderId,
    required String customerId,
    String? technicianId,
    required int rating,
    String? comment,
  }) async {
    state = const ReviewSubmitState(status: ReviewSubmitStatus.loading);
    try {
      await _repo.submitReview(
        orderId: orderId,
        customerId: customerId,
        technicianId: technicianId,
        rating: rating,
        comment: comment,
      );
      state = const ReviewSubmitState(status: ReviewSubmitStatus.success);
    } catch (e) {
      state = ReviewSubmitState(
        status: ReviewSubmitStatus.error,
        errorMessage: e is AppException ? e.message : 'فشل في إرسال التقييم',
      );
    }
  }
}

final reviewSubmitProvider = StateNotifierProvider.autoDispose
    .family<ReviewSubmitNotifier, ReviewSubmitState, String>(
      (ref, orderId) =>
          ReviewSubmitNotifier(ref.read(reviewRepositoryProvider)),
    );
