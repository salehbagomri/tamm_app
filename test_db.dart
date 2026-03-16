import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  String url = 'https://xisbsyrbjflcvbyowqbe.supabase.co';
  String key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhpc2JzeXJiamZsY3ZieW93cWJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MDYyNDcsImV4cCI6MjA4ODQ4MjI0N30.fhdswxx5zBMV3e-26gzrmtKB8vbRBBSDfQ3mYKStLKQ';
  
  final client = SupabaseClient(url, key);
  
  try {
    // Cannot easily test RLS for a specific user without logging in.
    // However, if the user didn't execute `phase_01_store_db.md` correctly, `cart_items` may not exist.
    
    // Instead of login, let's just describe the table via REST or let's intentionally use service role key if we had it.
    // Let's do a simple check on cart_items again.
    final result = await client.from('cart_items').select('id, user_id, product_id, quantity').limit(1).maybeSingle();
    print('cart_items returned: \$result');

    // Also check if `requires_installation` is available in the column returned
    final productCheck = await client.from('products').select('requires_installation').limit(1).maybeSingle();
    print('Products requires_installation schema check: \$productCheck');

  } catch (e) {
    print('Error testing DB: \$e');
  }
}
