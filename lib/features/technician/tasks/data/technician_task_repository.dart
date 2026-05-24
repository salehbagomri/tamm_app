import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';

class TechnicianTaskRepository {
  final _client = Supabase.instance.client;

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (newStatus == 'on_the_way') {
        // on_the_way has no assignment status equivalent — update order directly
        final updated = await _client
            .from('orders')
            .update({'status': 'on_the_way'})
            .eq('id', orderId)
            .select();
        if (updated.isEmpty) {
          throw const ServerException(
            message: 'فشل في تحديث حالة المهمة — تحقق من صلاحيات الحساب',
          );
        }
      } else {
        // For in_progress and completed: update ONLY the assignment.
        // The trigger sync_workflow_on_assignment_update handles order status sync.
        final assignmentStatus = newStatus == 'in_progress'
            ? 'started'
            : 'completed';
        final updates = <String, dynamic>{'status': assignmentStatus};
        if (newStatus == 'in_progress') {
          updates['started_at'] = DateTime.now().toIso8601String();
        }
        if (newStatus == 'completed') {
          updates['completed_at'] = DateTime.now().toIso8601String();
        }
        final updated = await _client
            .from('assignments')
            .update(updates)
            .eq('order_id', orderId)
            .select();
        if (updated.isEmpty) {
          throw const ServerException(
            message: 'فشل في تحديث حالة المهمة — تحقق من صلاحيات الحساب',
          );
        }
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في تحديث حالة المهمة');
    }
  }

  Future<void> saveTechnicianNotes(String assignmentId, String notes) async {
    try {
      await _client
          .from('assignments')
          .update({'technician_notes': notes})
          .eq('id', assignmentId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في حفظ الملاحظات');
    }
  }

  Future<void> confirmCashCollected(String assignmentId) async {
    try {
      await _client
          .from('assignments')
          .update({
            'cash_collected': true,
            'cash_collected_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', assignmentId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في تأكيد استلام المبلغ');
    }
  }

  // يرفع صورة واحدة ويُضيفها لمصفوفة photo_urls في assignment
  Future<String> uploadPhoto({
    required String assignmentId,
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final path =
          'assignments/$assignmentId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage
          .from('order-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: false,
            ),
          );

      final url = _client.storage.from('order-photos').getPublicUrl(path);

      // Check if this is the first photo being uploaded to set it as primary photo_url fallback
      final assignment = await _client
          .from('assignments')
          .select('photo_url, photo_urls')
          .eq('id', assignmentId)
          .single();

      final currentPhotoUrl = assignment['photo_url'] as String?;
      final currentPhotoUrls =
          (assignment['photo_urls'] as List?)?.cast<String>() ?? [];
      final bool isFirst =
          currentPhotoUrl == null ||
          currentPhotoUrl.isEmpty ||
          currentPhotoUrls.isEmpty;

      // أضف الـ URL لمصفوفة photo_urls
      await _client.rpc(
        'append_photo_url',
        params: {'p_assignment_id': assignmentId, 'p_url': url},
      );

      if (isFirst) {
        await _client
            .from('assignments')
            .update({'photo_url': url})
            .eq('id', assignmentId);
      }

      return url;
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في رفع الصورة');
    }
  }

  /// يحذف صورة من assignment: يُزيلها من مصفوفة photo_urls، ويعدّل photo_url
  /// إذا كانت الصورة الرئيسية، ثم يحاول حذف الملف من Storage (best-effort).
  Future<void> removePhoto({
    required String assignmentId,
    required String url,
  }) async {
    try {
      final row = await _client
          .from('assignments')
          .select('photo_urls, photo_url')
          .eq('id', assignmentId)
          .single();

      final urls = (row['photo_urls'] as List?)?.cast<String>() ?? [];
      urls.remove(url);

      final updates = <String, dynamic>{'photo_urls': urls};
      if (row['photo_url'] == url) {
        updates['photo_url'] = urls.isNotEmpty ? urls.first : null;
      }

      await _client.from('assignments').update(updates).eq('id', assignmentId);

      final path = _extractStoragePath(url);
      if (path != null) {
        try {
          await _client.storage.from('order-photos').remove([path]);
        } catch (_) {
          // best-effort — DB هو مصدر الحقيقة
        }
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في حذف الصورة');
    }
  }

  String? _extractStoragePath(String publicUrl) {
    const marker = '/order-photos/';
    final idx = publicUrl.indexOf(marker);
    if (idx < 0) return null;
    return publicUrl.substring(idx + marker.length);
  }
}
