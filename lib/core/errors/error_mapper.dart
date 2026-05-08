import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase show AuthException, PostgrestException;
import 'app_exception.dart';

/// يُحوّل أي خطأ خام إلى [AppException] منظّم.
///
/// الاستخدام:
/// ```dart
/// try {
///   ...
/// } catch (e) {
///   final appError = ErrorMapper.from(e);
///   ref.read(errorProvider.notifier).show(appError);
/// }
/// ```
abstract final class ErrorMapper {
  ErrorMapper._();

  /// يُعيد [AppException] مناسباً لأي نوع من الأخطاء.
  /// لا يستخدم [dart:io] لضمان التوافق مع Flutter Web.
  static AppException from(Object error) {
    // ── 1. PostgrestException من Supabase ────────────────────────────────────
    if (error is supabase.PostgrestException) {
      final code = error.code ?? '';
      if (code == '42501' || code == '403') {
        return const PermissionException();
      }
      return const ServerException();
    }

    // ── 2. AuthException من Supabase ─────────────────────────────────────────
    if (error is supabase.AuthException) {
      return const AuthException();
    }

    // ── 3. فحص رسالة الخطأ (بدون dart:io) ───────────────────────────────────
    final message = error.toString().toLowerCase();
    const networkKeywords = [
      'network',
      'socket',
      'connection',
      'failed host',
      'timed out',
      'no internet',
      'unreachable',
      'errno',
    ];
    if (networkKeywords.any(message.contains)) {
      return const NetworkException();
    }

    // ── 4. Fallback ───────────────────────────────────────────────────────────
    return const UnknownException();
  }
}
