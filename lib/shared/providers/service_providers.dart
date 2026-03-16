import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/service_repository.dart';
import '../models/service_type.dart';

final serviceRepositoryProvider = Provider((ref) => ServiceRepository());

final serviceTypesProvider = FutureProvider<List<ServiceType>>((ref) async {
  return ref.read(serviceRepositoryProvider).getServiceTypes();
});

final serviceDetailProvider = FutureProvider.family<ServiceType, String>((ref, id) async {
  final data = await Supabase.instance.client
      .from('service_types')
      .select()
      .eq('id', id)
      .single();
  return ServiceType.fromMap(data);
});
