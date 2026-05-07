import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tamm_colors.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class InAppNotificationState {
  final bool isVisible;
  final String title;
  final String body;
  final String? orderId;
  final String? notificationType;

  const InAppNotificationState({
    this.isVisible = false,
    this.title = '',
    this.body = '',
    this.orderId,
    this.notificationType,
  });

  InAppNotificationState copyWith({
    bool? isVisible,
    String? title,
    String? body,
    String? orderId,
    String? notificationType,
  }) {
    return InAppNotificationState(
      isVisible: isVisible ?? this.isVisible,
      title: title ?? this.title,
      body: body ?? this.body,
      orderId: orderId ?? this.orderId,
      notificationType: notificationType ?? this.notificationType,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class InAppNotificationNotifier
    extends StateNotifier<InAppNotificationState> {
  Timer? _timer;

  InAppNotificationNotifier() : super(const InAppNotificationState());

  void show({
    required String title,
    required String body,
    String? orderId,
    String? notificationType,
  }) {
    _timer?.cancel();
    state = InAppNotificationState(
      isVisible: true,
      title: title,
      body: body,
      orderId: orderId,
      notificationType: notificationType,
    );
    // Auto-dismiss after 4 seconds
    _timer = Timer(const Duration(seconds: 4), hide);
  }

  void hide() {
    _timer?.cancel();
    state = state.copyWith(isVisible: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final inAppNotificationProvider =
    StateNotifierProvider<InAppNotificationNotifier, InAppNotificationState>(
  (ref) => InAppNotificationNotifier(),
);

// ─── Widget ──────────────────────────────────────────────────────────────────

class InAppNotificationBanner extends ConsumerWidget {
  const InAppNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inAppNotificationProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      top: state.isVisible ? 0 : -120,
      left: 0,
      right: 0,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Swipe up to dismiss
          if (details.delta.dy < -5) {
            ref.read(inAppNotificationProvider.notifier).hide();
          }
        },
        onTap: () {
          final orderId = state.orderId;
          final type = state.notificationType;
          ref.read(inAppNotificationProvider.notifier).hide();
          if (orderId != null && context.mounted) {
            final route = _buildRoute(type, orderId);
            if (route != null) context.push(route);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.bluePrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForType(state.notificationType),
                    color: context.colors.bluePrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.title,
                        style: GoogleFonts.harmattan(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.body,
                        style: GoogleFonts.harmattan(
                          fontSize: 13,
                          color: context.colors.textSecond,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close, size: 18, color: context.colors.textFaint),
                  onPressed: () =>
                      ref.read(inAppNotificationProvider.notifier).hide(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _buildRoute(String? type, String orderId) {
    if (type == 'new_assignment') return '/technician/task/$orderId';
    if (type == 'quote_sent') return '/customer/quote-response/$orderId';
    return null; // let FcmService handle role-based routing
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'on_the_way':      return Icons.directions_car_outlined;
      case 'in_progress':     return Icons.build_outlined;
      case 'completed':       return Icons.task_alt;
      case 'quote_sent':      return Icons.request_quote_outlined;
      case 'quote_responded': return Icons.reply_outlined;
      case 'new_order':       return Icons.shopping_bag_outlined;
      case 'new_assignment':  return Icons.assignment_outlined;
      default:                return Icons.notifications_outlined;
    }
  }
}
