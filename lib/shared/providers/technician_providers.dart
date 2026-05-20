import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../features/technician/tasks/data/technician_task_repository.dart';

final myAssignmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      // جلب technician_id من جدول technicians
      final tech = await client
          .from('technicians')
          .select('id')
          .eq('profile_id', userId)
          .single();
      final techId = tech['id'] as String;

      final rows = await client
          .from('assignments')
          .select(
            '*, orders(*, profiles!customer_id(full_name, phone, address), order_items(*))',
          )
          .eq('technician_id', techId)
          .inFilter('status', ['assigned', 'started'])
          .order('created_at', ascending: false);

      // Safety filter: hide assignments whose order is already completed/cancelled
      // in case the assignment status got out of sync with the order status.
      return rows.where((a) {
        final orderStatus =
            (a['orders'] as Map<String, dynamic>?)?['status'] as String?;
        return orderStatus != 'completed' && orderStatus != 'cancelled';
      }).toList();
    });

final myTechnicianProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      final tech = await client
          .from('technicians')
          .select('*, profiles(*)')
          .eq('profile_id', userId)
          .single();

      final techId = tech['id'] as String;

      final completed = await client
          .from('assignments')
          .select()
          .eq('technician_id', techId)
          .eq('status', 'completed')
          .count(CountOption.exact);

      return {'technician': tech, 'completed_count': completed.count};
    });

// ─── Task update provider ─────────────────────────────────────────────────────

enum TaskUpdateStatus { idle, loading, success, error }

class TaskUpdateState {
  final TaskUpdateStatus status;
  final String? errorMessage;

  const TaskUpdateState({
    this.status = TaskUpdateStatus.idle,
    this.errorMessage,
  });
}

class TaskUpdateNotifier extends StateNotifier<TaskUpdateState> {
  final TechnicianTaskRepository _repo;

  TaskUpdateNotifier(this._repo) : super(const TaskUpdateState());

  Future<bool> updateStatus(String orderId, String newStatus) async {
    state = const TaskUpdateState(status: TaskUpdateStatus.loading);
    try {
      await _repo.updateOrderStatus(orderId, newStatus);
      state = const TaskUpdateState(status: TaskUpdateStatus.success);
      return true;
    } catch (e) {
      state = TaskUpdateState(
        status: TaskUpdateStatus.error,
        errorMessage: e is AppException ? e.message : 'فشل في تحديث الحالة',
      );
      return false;
    }
  }

  Future<void> saveNotes(String orderId, String notes) async {
    try {
      await _repo.saveTechnicianNotes(orderId, notes);
    } catch (_) {
      // Silent fail — auto-save is best-effort
    }
  }
}

final technicianTaskRepositoryProvider =
    Provider((ref) => TechnicianTaskRepository());

final taskUpdateProvider = StateNotifierProvider.autoDispose
    .family<TaskUpdateNotifier, TaskUpdateState, String>(
      (ref, orderId) =>
          TaskUpdateNotifier(ref.read(technicianTaskRepositoryProvider)),
    );
