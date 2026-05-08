import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/env.dart';
import 'core/services/fcm_service.dart';
import 'core/network/tamm_http_client.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    httpClient: TammHttpClient(timeout: const Duration(seconds: 5)),
  );
  await FcmService.initialize();
  runApp(const ProviderScope(child: TammApp()));
}
