import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  ref.watch(authStateProvider);
  final repo = ref.read(authRepositoryProvider);
  return repo.getProfile();
});

final roleStreamProvider = StreamProvider<String?>((ref) {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(null);

  return Supabase.instance.client
    .from('profiles')
    .stream(primaryKey: ['id'])
    .eq('id', userId)
    .map((rows) => rows.isEmpty ? null : rows.first['role'] as String?);
});

/// هل المستخدم زائر (غير مسجّل)؟
final isGuestProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser == null;
});
