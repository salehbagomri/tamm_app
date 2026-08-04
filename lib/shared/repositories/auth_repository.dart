import 'dart:typed_data';
import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/services/fcm_service.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/app_exception.dart';
import '../providers/auth_providers.dart';
import '../models/user_profile.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  bool _googleInitialized = false;

  /// Initialize GoogleSignIn singleton (call once) — mobile only
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized || kIsWeb) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '504988713429-c5f4p7s07f4idf8ikc666uqnsmkoj60k.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  /// تسجيل الدخول بحساب Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: استخدام Supabase OAuth redirect flow
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://tamm-app-8c990.web.app',
        );
        // OAuth redirect — لن يصل لهنا لأن الصفحة ستتحول
        return null;
      }

      // Mobile: استخدام google_sign_in + ID token
      await _ensureGoogleInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
          message: 'فشل في الحصول على رمز المصادقة من Google',
        );
      }

      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// إنشاء حساب جديد بالبريد
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
      );
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// إعادة تعيين كلمة المرور — يوجّه المستخدم إلى التطبيق عبر tamm://reset-password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'tamm://reset-password',
      );
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// تحديث كلمة المرور بعد التحقق من رابط الاستعادة
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// جلب بروفايل المستخدم
  Future<UserProfile?> getProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// هل البروفايل مكتمل؟
  /// يعتمد على bubble up من getProfile — لا try/catch إضافي مطلوب
  Future<bool> isProfileComplete() async {
    final profile = await getProfile();
    return profile?.isComplete ?? false;
  }

  /// إكمال بيانات البروفايل (Onboarding)
  Future<void> completeProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException();

      await _client
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone': phone,
            'is_complete': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  /// تحديث بيانات البروفايل
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _client
          .from('profiles')
          .update(profile.toMap())
          .eq('id', profile.id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// رفع صورة المستخدم إلى storage بـ bucket "avatars" وتحديث profiles.avatar_url.
  /// تُرجع الـ public URL النهائي. تستبدل الصورة السابقة (upsert).
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthException();
      }
      final cleanExt = extension.toLowerCase().replaceAll('.', '');
      final path = '${user.id}/avatar.$cleanExt';
      // الخادم يدعم mime type: image/jpeg وليس image/jpg
      final mimeType = cleanExt == 'jpg' || cleanExt == 'jpeg'
          ? 'jpeg'
          : cleanExt;

      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$mimeType',
              upsert: true,
            ),
          );

      // cache-buster timestamp يضمن أن CachedNetworkImage يحدّث الصورة فوراً
      final url = _client.storage.from('avatars').getPublicUrl(path);
      final bustedUrl = '$url?v=${DateTime.now().millisecondsSinceEpoch}';

      await _client
          .from('profiles')
          .update({'avatar_url': bustedUrl})
          .eq('id', user.id);

      return bustedUrl;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  /// تسجيل الخروج — معالجة صامتة (الأخطاء لا تُرمى للمستخدم)
  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // تجاهل أخطاء Google signOut — لا تمنع signOut من Supabase
    }
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] signOut error: $e');
      // لا rethrow — المستخدم يُعامَل كخارج بنجاح
    }
  }

  /// تسجيل الخروج مع تأكيد (UI logic — لا تعديل)
  static Future<void> confirmSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        title: Text(
          'تسجيل الخروج',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.body(context.colors.textSecond),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.bluePrimary,
            ),
            child: Text(
              'تأكيد',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // إلغاء تسجيل FCM قبل الخروج
    await FcmService.unregisterToken();
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      context.go('/customer/home');
    }
  }

  /// حذف الحساب
  Future<void> deleteAccount() async {
    try {
      await FcmService.unregisterToken();
      await _client.rpc('delete_user_account');
      await _client.auth.signOut();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// هل المستخدم مسجل الدخول
  bool get isLoggedIn => _client.auth.currentSession != null;

  /// ID المستخدم الحالي
  String? get currentUserId => _client.auth.currentUser?.id;
}
