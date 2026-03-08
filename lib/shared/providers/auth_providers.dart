import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getProfile();
});
