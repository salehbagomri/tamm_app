import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

async function testSupabase() {
  try {
    const pubspecPath = path.join(__dirname, 'lib', 'core', 'constants', 'supabase_constants.dart');
    // Read from the db text file instead
    const dbText = fs.readFileSync(path.join(__dirname, 'supabase_db.txt'), 'utf8');
    
    // Extract url and anon key
    let url = '';
    let key = '';
    
    const urlMatch = dbText.match(/URL:\s*(https:\/\/[^\s]+)/);
    if (urlMatch) url = urlMatch[1];
    
    const keyMatch = dbText.match(/anon\s+public:\s*([^\s]+)/);
    if (keyMatch) key = keyMatch[1];
    
    if (!url || !key) {
      console.log('Could not find URL or Key');
      return;
    }

    const supabase = createClient(url, key);
    
    // 1. Check products that require installation
    console.log('--- Checking Products ---');
    const { data: products, error: pErr } = await supabase.from('products').select('id, name, requires_installation').limit(5);
    if (pErr) {
      console.error('Error fetching products:', pErr);
    } else {
      console.log(products);
    }
    
    // 2. Check a common order to see what data comes back
    console.log('\n--- Checking Orders ---');
    const { data: orders, error: oErr } = await supabase.from('orders').select('*, order_items(*)').limit(1);
    if (oErr) {
      console.error('Error fetching orders:', oErr);
    } else {
      console.dir(orders, { depth: null });
    }
  } catch(e) {
    console.error(e);
  }
}

testSupabase();
