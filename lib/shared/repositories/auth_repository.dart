import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  bool _googleInitialized = false;

  /// Initialize GoogleSignIn singleton (call once)
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '504988713429-c5f4p7s07f4idf8ikc666uqnsmkoj60k.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  /// تسجيل الدخول بحساب Google (v7 API)
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('فشل في الحصول على رمز المصادقة من Google');
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// جلب بروفايل المستخدم
  Future<UserProfile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  /// هل البروفايل مكتمل؟
  Future<bool> isProfileComplete() async {
    final profile = await getProfile();
    return profile?.isComplete ?? false;
  }

  /// إكمال بيانات البروفايل (Onboarding)
  Future<void> completeProfile({
    required String fullName,
    required String phone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('المستخدم غير مسجل');

    await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'is_complete': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// تحديث بيانات البروفايل
  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').update(profile.toMap()).eq('id', profile.id);
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

  /// هل المستخدم مسجل الدخول
  bool get isLoggedIn => _client.auth.currentSession != null;

  /// ID المستخدم الحالي
  String? get currentUserId => _client.auth.currentUser?.id;
}
