import 'dart:async' show TimeoutException;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase
    show AuthException, PostgrestException, StorageException;
import 'app_exception.dart';

/// يُحوّل أي خطأ خام إلى [AppException] منظم.
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

    // ── 1.5 StorageException من Supabase ─────────────────────────────────────
    if (error is supabase.StorageException) {
      final msg = error.message;
      if (msg.contains('Bucket not found') || msg.contains('not found')) {
        return const ServerException(
          message: 'مجلد الصور (avatars) غير موجود في التخزين، يرجى تهيئته من لوحة التحكم',
        );
      }
      return ServerException(message: 'خطأ في التخزين السحابي: $msg');
    }

    // ── 2. AuthException من Supabase ─────────────────────────────────────────
    if (error is supabase.AuthException) {
      return const AuthException();
    }

    // ── 3. TimeoutException (انتهى وقت الاتصال) ─────────────────────────────
    if (error is TimeoutException) {
      return const NetworkException(
        message: 'انتهى وقت الاتصال، تحقق من الشبكة وأعد المحاولة',
      );
    }

    // ── 4. فحص رسالة الخطأ (بدون dart:io) ───────────────────────────────────
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
