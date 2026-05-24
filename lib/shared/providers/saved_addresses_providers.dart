import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_address.dart';
import '../repositories/saved_addresses_repository.dart';

final savedAddressesRepositoryProvider = Provider<SavedAddressesRepository>(
  (_) => SavedAddressesRepository(),
);

final savedAddressesProvider =
    FutureProvider.autoDispose<List<SavedAddress>>((ref) async {
  final repo = ref.read(savedAddressesRepositoryProvider);
  return repo.fetchAll();
});
