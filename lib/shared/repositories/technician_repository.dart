import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/error_mapper.dart';

class TechnicianRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      return await _client
          .from('technicians')
          .select('*, profiles(full_name, phone, avatar_url)')
          .eq('is_active', true);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> addTechnician({
    required String profileId,
    required String specialization,
    required String phone,
  }) async {
    try {
      await _client.from('technicians').insert({
        'profile_id': profileId,
        'specialization': specialization,
        'phone': phone,
      });
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateTechnicianStatus(String id, String status) async {
    try {
      await _client.from('technicians').update({'status': status}).eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateMyAvailability(bool isAvailable) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final status = isAvailable ? 'available' : 'busy';
      await _client
          .from('technicians')
          .update({'status': status})
          .eq('profile_id', userId);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// يبتلع الخطأ عمداً — مقصود للبحث عن هاتف غير موجود
  Future<Map<String, dynamic>?> getProfileByPhone(String phone) async {
    try {
      return await _client
          .from('profiles')
          .select()
          .eq('phone', phone)
          .single();
    } catch (_) {
      return null;
    }
  }

  Future<void> promoteToTechnician({
    required String profileId,
    required String phone,
    required String specialization,
  }) async {
    try {
      await _client.rpc(
        'promote_to_technician',
        params: {
          'p_profile_id': profileId,
          'p_phone': phone,
          'p_specialization': specialization,
        },
      );
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<Map<String, dynamic>> getTechnicianDetails(String id) async {
    try {
      final techData = await _client
          .from('technicians')
          .select(
            '*, profiles(full_name, phone, avatar_url), assignments(*, orders(*))',
          )
          .eq('id', id)
          .single();
      return techData;
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();

      final pending = await _client
          .from('orders')
          .select()
          .eq('status', 'pending')
          .neq('order_type', 'quote_request')
          .count(CountOption.exact);

      final quotesNeedAction = await _client
          .from('orders')
          .select()
          .eq('order_type', 'quote_request')
          .inFilter('quote_status', ['pending', 'rejected'])
          .count(CountOption.exact);

      final completed = await _client
          .from('orders')
          .select()
          .eq('status', 'completed')
          .gte('updated_at', startOfDay)
          .count(CountOption.exact);

      final inProgress = await _client
          .from('orders')
          .select()
          .inFilter('status', ['in_progress', 'assigned', 'on_the_way'])
          .count(CountOption.exact);

      final techs = await _client
          .from('technicians')
          .select()
          .eq('is_active', true)
          .count(CountOption.exact);

      return {
        'pending': pending.count,
        'quotes_need_action': quotesNeedAction.count,
        'completed': completed.count,
        'in_progress': inProgress.count,
        'technicians': techs.count,
      };
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
