import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/app_exception.dart';

class AssignmentRepository {
  final _client = Supabase.instance.client;

  Future<void> assignTechnician({
    required String orderId,
    required String technicianId,
  }) async {
    try {
      final managerId = _client.auth.currentUser!.id;
      await _client.from('assignments').insert({
        'order_id': orderId,
        'technician_id': technicianId,
        'assigned_by': managerId,
      });

      // تحديث حالة الطلب — رسالة مخصصة عند الفشل
      try {
        await _client
            .from('orders')
            .update({'status': 'assigned'})
            .eq('id', orderId);
      } catch (e) {
        throw const ServerException(
          message: 'فشل في تحديث حالة الطلب',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAssignmentsForOrder(
    String orderId,
  ) async {
    try {
      return await _client
          .from('assignments')
          .select('*, technicians(*, profiles(*))')
          .eq('order_id', orderId);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAssignmentsForTechnician(
    String techId,
  ) async {
    try {
      return await _client
          .from('assignments')
          .select('*, orders(*)')
          .eq('technician_id', techId)
          .order('created_at', ascending: false);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateAssignmentStatus(String id, String status) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (status == 'started') {
        updates['started_at'] = DateTime.now().toIso8601String();
      }
      if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }
      await _client.from('assignments').update(updates).eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateAssignmentData(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final updates = Map<String, dynamic>.from(data);
      if (updates['status'] == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }
      await _client.from('assignments').update(updates).eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
