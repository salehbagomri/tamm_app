import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_exception.dart';

/// مدة عرض الخطأ قبل المسح التلقائي
const _kAutoClearDuration = Duration(seconds: 5);

/// يُدير عرض الأخطاء المركزية عبر SnackBar في الـ Shells.
///
/// الحالة الابتدائية [null] تعني "لا يوجد خطأ حالياً".
///
/// الاستخدام — إظهار خطأ:
/// ```dart
/// ref.read(errorProvider.notifier).show(ErrorMapper.from(e));
/// ```
///
/// الاستخدام — مسح يدوي:
/// ```dart
/// ref.read(errorProvider.notifier).clear();
/// ```
class ErrorNotifier extends StateNotifier<AppException?> {
  Timer? _clearTimer;

  ErrorNotifier() : super(null);

  /// يُظهر الخطأ ويبدأ عدّاداً للمسح التلقائي بعد [_kAutoClearDuration].
  void show(AppException exception) {
    _clearTimer?.cancel();
    state = exception;
    _clearTimer = Timer(_kAutoClearDuration, clear);
  }

  /// يمسح الخطأ الحالي فوراً ويلغي العدّاد إن وُجد.
  void clear() {
    _clearTimer?.cancel();
    _clearTimer = null;
    state = null;
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }
}

/// الـ Provider المركزي للأخطاء — يُستهلك في كل Shell.
final errorProvider = StateNotifierProvider<ErrorNotifier, AppException?>(
  (ref) => ErrorNotifier(),
);
