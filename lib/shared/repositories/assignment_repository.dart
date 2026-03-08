import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentRepository {
  final _client = Supabase.instance.client;

  Future<void> assignTechnician({
    required String orderId,
    required String technicianId,
  }) async {
    final managerId = _client.auth.currentUser!.id;
    await _client.from('assignments').insert({
      'order_id': orderId,
      'technician_id': technicianId,
      'assigned_by': managerId,
    });
    await _client
        .from('orders')
        .update({'status': 'assigned'})
        .eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> getAssignmentsForOrder(
    String orderId,
  ) async {
    return await _client
        .from('assignments')
        .select('*, technicians(*, profiles(*))')
        .eq('order_id', orderId);
  }

  Future<List<Map<String, dynamic>>> getAssignmentsForTechnician(
    String techId,
  ) async {
    return await _client
        .from('assignments')
        .select('*, orders(*)')
        .eq('technician_id', techId)
        .order('created_at', ascending: false);
  }

  Future<void> updateAssignmentStatus(String id, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'started')
      updates['started_at'] = DateTime.now().toIso8601String();
    if (status == 'completed')
      updates['completed_at'] = DateTime.now().toIso8601String();
    await _client.from('assignments').update(updates).eq('id', id);
  }
}
