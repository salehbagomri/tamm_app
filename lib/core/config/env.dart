/// متغيرات البيئة — تُستبدل بالقيم الحقيقية قبل البناء
/// لا ترفع هذا الملف إلى Git بالقيم الحقيقية
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xisbsyrbjflcvbyowqbe.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhpc2JzeXJiamZsY3ZieW93cWJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MDYyNDcsImV4cCI6MjA4ODQ4MjI0N30.fhdswxx5zBMV3e-26gzrmtKB8vbRBBSDfQ3mYKStLKQ',
  );
}
