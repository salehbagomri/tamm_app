import 'package:flutter/foundation.dart';

/// الإجراء الموصى به للمستخدم بعد وقوع الخطأ
enum ErrorAction {
  /// أعد المحاولة — للأخطاء المؤقتة (شبكة، خادم)
  retry,

  /// سجّل دخولك مجدداً — انتهت الجلسة
  relogin,

  /// تجاهل — لا يمكن فعل شيء (صلاحيات، تحقق)
  dismiss,
}

/// القاعدة المشتركة لجميع أخطاء التطبيق
@immutable
sealed class AppException implements Exception {
  final String message;
  final ErrorAction action;

  const AppException({required this.message, required this.action});

  @override
  String toString() => 'AppException($runtimeType): $message';
}

// ─────────────────────────────────────────────────────────────────────────────

/// انقطاع الاتصال بالإنترنت
@immutable
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'لا يوجد اتصال بالإنترنت، تحقق من الشبكة وأعد المحاولة',
    super.action = ErrorAction.retry,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// انتهاء الجلسة أو خطأ في المصادقة
@immutable
final class AuthException extends AppException {
  const AuthException({
    super.message = 'انتهت جلستك، يرجى تسجيل الدخول مجدداً',
    super.action = ErrorAction.relogin,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// خطأ في الخادم (5xx)
@immutable
final class ServerException extends AppException {
  const ServerException({
    super.message = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
    super.action = ErrorAction.retry,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// غير مصرح بالوصول (403 / RLS)
@immutable
final class PermissionException extends AppException {
  const PermissionException({
    super.message = 'ليس لديك صلاحية للوصول لهذا المورد',
    super.action = ErrorAction.dismiss,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// بيانات ناقصة أو غير صحيحة — الرسالة دائماً ديناميكية
@immutable
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.action = ErrorAction.dismiss,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Fallback — أي خطأ غير معروف
@immutable
final class UnknownException extends AppException {
  const UnknownException({
    super.message = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى',
    super.action = ErrorAction.retry,
  });
}
