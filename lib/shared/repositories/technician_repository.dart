import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTechnicians() async {
    return await _client
        .from('technicians')
        .select('*, profiles(full_name, phone, avatar_url)')
        .eq('is_active', true);
  }

  Future<void> addTechnician({
    required String profileId,
    required String specialization,
    required String phone,
  }) async {
    await _client.from('technicians').insert({
      'profile_id': profileId,
      'specialization': specialization,
      'phone': phone,
    });
  }

  Future<void> updateTechnicianStatus(String id, String status) async {
    await _client.from('technicians').update({'status': status}).eq('id', id);
  }

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
    await _client.rpc(
      'promote_to_technician',
      params: {
        'p_profile_id': profileId,
        'p_phone': phone,
        'p_specialization': specialization,
      },
    );
  }

  Future<Map<String, dynamic>> getTechnicianDetails(String id) async {
    final techData = await _client
        .from('technicians')
        .select(
          '*, profiles(full_name, phone, avatar_url), assignments(*, orders(*))',
        )
        .eq('id', id)
        .single();

    return techData;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
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
        .eq('status', 'in_progress')
        .count(CountOption.exact);
    final techs = await _client
        .from('technicians')
        .select()
        .eq('is_active', true)
        .count(CountOption.exact);
    return {
      'pending': pending.count,
      'completed': completed.count,
      'in_progress': inProgress.count,
      'technicians': techs.count,
    };
  }
}
