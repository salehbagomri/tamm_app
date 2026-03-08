/// متغيرات البيئة — تُستبدل بالقيم الحقيقية قبل البناء
/// لا ترفع هذا الملف إلى Git بالقيم الحقيقية
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );
}
