import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../models/saved_address.dart';

class SavedAddressesRepository {
  final SupabaseClient _db = Supabase.instance.client;

  String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AuthException();
    return id;
  }

  Future<List<SavedAddress>> fetchAll() async {
    try {
      final rows = await _db
          .from('saved_addresses')
          .select()
          .eq('user_id', _userId)
          .order('is_default', ascending: false)
          .order('created_at');
      return rows.map((r) => SavedAddress.fromMap(r)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<SavedAddress> add(SavedAddress address) async {
    try {
      if (address.isDefault) await _clearDefault();
      final insertData = address.toInsertMap();
      insertData['user_id'] = _userId; // تأكيد إدخال معرف المستخدم الفعلي
      final row = await _db
          .from('saved_addresses')
          .insert(insertData)
          .select()
          .single();
      return SavedAddress.fromMap(row);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> update(SavedAddress address) async {
    try {
      if (address.isDefault) await _clearDefault();
      await _db
          .from('saved_addresses')
          .update({
            'label': address.label,
            'address': address.address,
            'city': address.city,
            'lat': address.lat,
            'lng': address.lng,
            'is_default': address.isDefault,
          })
          .eq('id', address.id)
          .eq('user_id', _userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _db
          .from('saved_addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> setDefault(String id) async {
    try {
      await _clearDefault();
      await _db
          .from('saved_addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> _clearDefault() async {
    await _db
        .from('saved_addresses')
        .update({'is_default': false})
        .eq('user_id', _userId)
        .eq('is_default', true);
  }
}
