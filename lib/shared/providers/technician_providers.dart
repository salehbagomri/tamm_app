import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../features/technician/tasks/data/technician_task_repository.dart';
import '../models/technician_earning.dart';

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

// ─── Completed assignments (history) ─────────────────────────────────────────

final completedAssignmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;

  final tech = await client
      .from('technicians')
      .select('id')
      .eq('profile_id', userId)
      .single();
  final techId = tech['id'] as String;

  return await client
      .from('assignments')
      .select(
        '*, orders(*, profiles!customer_id(full_name, phone, address))',
      )
      .eq('technician_id', techId)
      .eq('status', 'completed')
      .order('completed_at', ascending: false);
});

// ─── Performance stats (today / week / total) ─────────────────────────────────

class TechStats {
  final int total;
  final int today;
  final int thisWeek;
  const TechStats({
    required this.total,
    required this.today,
    required this.thisWeek,
  });
}

final techStatsProvider =
    FutureProvider.autoDispose<TechStats>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;

  final tech = await client
      .from('technicians')
      .select('id')
      .eq('profile_id', userId)
      .single();
  final techId = tech['id'] as String;

  final now = DateTime.now().toLocal();
  final todayStart =
      DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
  final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1)
      .toUtc()
      .toIso8601String();

  final totalRes = await client
      .from('assignments')
      .select()
      .eq('technician_id', techId)
      .eq('status', 'completed')
      .count(CountOption.exact);

  final todayRes = await client
      .from('assignments')
      .select()
      .eq('technician_id', techId)
      .eq('status', 'completed')
      .gte('completed_at', todayStart)
      .count(CountOption.exact);

  final weekRes = await client
      .from('assignments')
      .select()
      .eq('technician_id', techId)
      .eq('status', 'completed')
      .gte('completed_at', weekStart)
      .count(CountOption.exact);

  return TechStats(
    total: totalRes.count,
    today: todayRes.count,
    thisWeek: weekRes.count,
  );
});

// ─── Assignment detail provider (independent — works from notifications too) ──

final assignmentDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, assignmentId) async {
  final client = Supabase.instance.client;
  return await client
      .from('assignments')
      .select(
        '*, orders(*, profiles!customer_id(full_name, phone, address), '
        'order_items(*, service_types(name), products(name)))',
      )
      .eq('id', assignmentId)
      .single();
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

  Future<void> saveNotes(String assignmentId, String notes) async {
    try {
      await _repo.saveTechnicianNotes(assignmentId, notes);
    } catch (_) {
      // Silent fail — auto-save is best-effort
    }
  }
}

// ─── Cash collected confirmation provider ────────────────────────────────────

enum CashCollectedStatus { idle, loading, success, error }

class CashCollectedState {
  final CashCollectedStatus status;
  final bool collected;
  final String? errorMessage;

  const CashCollectedState({
    this.status = CashCollectedStatus.idle,
    this.collected = false,
    this.errorMessage,
  });
}

class CashCollectedNotifier extends StateNotifier<CashCollectedState> {
  final TechnicianTaskRepository _repo;

  CashCollectedNotifier(this._repo, {required bool initialValue})
      : super(CashCollectedState(collected: initialValue));

  Future<bool> confirm(String assignmentId) async {
    state = CashCollectedState(
      status: CashCollectedStatus.loading,
      collected: state.collected,
    );
    try {
      await _repo.confirmCashCollected(assignmentId);
      state = const CashCollectedState(
        status: CashCollectedStatus.success,
        collected: true,
      );
      return true;
    } catch (e) {
      state = CashCollectedState(
        status: CashCollectedStatus.error,
        collected: false,
        errorMessage:
            e is AppException ? e.message : 'فشل في تأكيد استلام المبلغ',
      );
      return false;
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

final cashCollectedProvider = StateNotifierProvider.autoDispose
    .family<CashCollectedNotifier, CashCollectedState, ({String assignmentId, bool initialValue})>(
      (ref, args) => CashCollectedNotifier(
        ref.read(technicianTaskRepositoryProvider),
        initialValue: args.initialValue,
      ),
    );

// ─── Photo upload provider ────────────────────────────────────────────────────

enum PhotoUploadStatus { idle, uploading, done, error }

class PhotoUploadState {
  final PhotoUploadStatus status;
  final String? errorMessage;
  const PhotoUploadState({
    this.status = PhotoUploadStatus.idle,
    this.errorMessage,
  });
}

class PhotoUploadNotifier extends StateNotifier<PhotoUploadState> {
  final TechnicianTaskRepository _repo;
  PhotoUploadNotifier(this._repo) : super(const PhotoUploadState());

  Future<bool> upload({
    required String assignmentId,
    required List<int> bytes,
    required String extension,
  }) async {
    state = const PhotoUploadState(status: PhotoUploadStatus.uploading);
    try {
      final data = Uint8List.fromList(bytes);
      await _repo.uploadPhoto(
        assignmentId: assignmentId,
        bytes: data,
        extension: extension,
      );
      state = const PhotoUploadState(status: PhotoUploadStatus.done);
      return true;
    } catch (e) {
      state = PhotoUploadState(
        status: PhotoUploadStatus.error,
        errorMessage: e is AppException ? e.message : 'فشل رفع الصورة',
      );
      return false;
    }
  }
}

final photoUploadProvider = StateNotifierProvider.autoDispose
    .family<PhotoUploadNotifier, PhotoUploadState, String>(
      (ref, assignmentId) =>
          PhotoUploadNotifier(ref.read(technicianTaskRepositoryProvider)),
    );

// ─── Technician earnings (commission) ─────────────────────────────────────────

final myEarningsProvider =
    FutureProvider.autoDispose<List<TechnicianEarning>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;

  final tech = await client
      .from('technicians')
      .select('id')
      .eq('profile_id', userId)
      .single();
  final techId = tech['id'] as String;

  final rows = await client
      .from('technician_earnings')
      .select('*, orders(order_number)')
      .eq('technician_id', techId)
      .order('created_at', ascending: false);

  return rows
      .map<TechnicianEarning>(
        (m) => TechnicianEarning.fromMap(m),
      )
      .toList();
});
