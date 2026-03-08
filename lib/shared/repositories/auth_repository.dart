import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// تسجيل حساب جديد بالإيميل وكلمة المرور بالإضافة للاسم ورقم الجوال
  Future<AuthResponse> signUp(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
  }

  /// تسجيل دخول بالإيميل وكلمة المرور
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
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

  /// تحديث بيانات البروفايل
  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').update(profile.toMap()).eq('id', profile.id);
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// هل المستخدم مسجل الدخول
  bool get isLoggedIn => _client.auth.currentSession != null;

  /// ID المستخدم الحالي
  String? get currentUserId => _client.auth.currentUser?.id;
}
