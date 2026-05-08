import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_type.dart';
import '../../core/errors/error_mapper.dart';

class ServiceRepository {
  final _client = Supabase.instance.client;

  /// جلب الخدمات النشطة للعملاء
  Future<List<ServiceType>> getServiceTypes() async {
    try {
      final data = await _client
          .from('service_types')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return data.map((e) => ServiceType.fromMap(e)).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// جلب جميع الخدمات (نشطة وغير نشطة) للمدير
  Future<List<ServiceType>> getAllServiceTypes() async {
    try {
      final data = await _client
          .from('service_types')
          .select()
          .order('sort_order', ascending: true);
      return data.map((e) => ServiceType.fromMap(e)).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// إضافة خدمة جديدة
  Future<void> addServiceType(Map<String, dynamic> serviceData) async {
    try {
      await _client.from('service_types').insert(serviceData);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// تحديث بيانات خدمة
  Future<void> updateServiceType(
    String id,
    Map<String, dynamic> serviceData,
  ) async {
    try {
      await _client.from('service_types').update(serviceData).eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// حذف (أو إخفاء) خدمة
  Future<void> hideServiceType(String id, bool isActive) async {
    try {
      await _client
          .from('service_types')
          .update({'is_active': isActive})
          .eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
