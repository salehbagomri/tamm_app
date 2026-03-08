import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/service_repository.dart';
import '../models/service_type.dart';

final serviceRepositoryProvider = Provider((ref) => ServiceRepository());

final serviceTypesProvider = FutureProvider<List<ServiceType>>((ref) async {
  return ref.read(serviceRepositoryProvider).getServiceTypes();
});
