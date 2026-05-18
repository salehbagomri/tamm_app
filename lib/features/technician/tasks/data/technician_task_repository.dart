import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';

class TechnicianTaskRepository {
  final _client = Supabase.instance.client;

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    debugPrint('=== updateOrderStatus called: orderId=$orderId  newStatus=$newStatus');
    try {
      final updated = await _client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select();   // returns affected rows — empty if RLS blocked it
      debugPrint('=== orders update result: ${updated.length} row(s) affected — $updated');

      // Sync assignments so myAssignmentsProvider filter stays correct
      final assignmentUpdates = <String, dynamic>{};
      if (newStatus == 'on_the_way') {
        // Keep assignment as 'assigned' — task stays visible
      } else if (newStatus == 'in_progress') {
        assignmentUpdates['status'] = 'started';
      } else if (newStatus == 'completed') {
        assignmentUpdates['status'] = 'completed';
        assignmentUpdates['completed_at'] = DateTime.now().toIso8601String();
      }
      if (assignmentUpdates.isNotEmpty) {
        final assignUpdated = await _client
            .from('assignments')
            .update(assignmentUpdates)
            .eq('order_id', orderId)
            .select();
        debugPrint('=== assignments update result: ${assignUpdated.length} row(s) — $assignUpdated');
      }
    } catch (e) {
      debugPrint('=== updateOrderStatus ERROR: $e');
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في تحديث حالة المهمة');
    }
  }

  Future<void> saveTechnicianNotes(String orderId, String notes) async {
    try {
      await _client
          .from('orders')
          .update({'technician_notes': notes})
          .eq('id', orderId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في حفظ الملاحظات');
    }
  }
}
