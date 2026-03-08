import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_type.dart';

class ServiceRepository {
  final _client = Supabase.instance.client;

  Future<List<ServiceType>> getServiceTypes() async {
    final data = await _client
        .from('service_types')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return data.map((e) => ServiceType.fromMap(e)).toList();
  }
}
