import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final myAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;

  // جلب technician_id من جدول technicians
  final tech = await client
      .from('technicians')
      .select('id')
      .eq('profile_id', userId)
      .single();
  final techId = tech['id'] as String;

  return await client
      .from('assignments')
      .select('*, orders(*, profiles!customer_id(full_name, phone, address))')
      .eq('technician_id', techId)
      .inFilter('status', ['assigned', 'started'])
      .order('created_at', ascending: false);
});
