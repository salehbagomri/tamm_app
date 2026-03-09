import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_type.dart';

class ServiceRepository {
  final _client = Supabase.instance.client;

  /// جلب الخدمات النشطة للعملاء
  Future<List<ServiceType>> getServiceTypes() async {
    final data = await _client
        .from('service_types')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return data.map((e) => ServiceType.fromMap(e)).toList();
  }

  /// جلب جميع الخدمات (نشطة وغير نشطة) للمدير
  Future<List<ServiceType>> getAllServiceTypes() async {
    final data = await _client
        .from('service_types')
        .select()
        .order('sort_order', ascending: true);
    return data.map((e) => ServiceType.fromMap(e)).toList();
  }

  /// إضافة خدمة جديدة
  Future<void> addServiceType(Map<String, dynamic> serviceData) async {
    await _client.from('service_types').insert(serviceData);
  }

  /// تحديث بيانات خدمة
  Future<void> updateServiceType(
    String id,
    Map<String, dynamic> serviceData,
  ) async {
    await _client.from('service_types').update(serviceData).eq('id', id);
  }

  /// حذف (أو إخفاء) خدمة
  Future<void> hideServiceType(String id, bool isActive) async {
    await _client
        .from('service_types')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
