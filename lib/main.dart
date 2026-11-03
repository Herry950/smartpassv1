import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/constants/supabase_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  await initializeDateFormatting('fr_FR');

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  final supabase = Supabase.instance.client;

  supabase.auth.onAuthStateChange.listen((data) {
    debugPrint('========== SUPABASE AUTH EVENT ==========');
    debugPrint('EVENT : ${data.event}');
    debugPrint('USER : ${data.session?.user.id ?? "NULL"}');
    debugPrint('EMAIL : ${data.session?.user.email ?? "NULL"}');
    debugPrint('SESSION : ${data.session == null ? "NULL" : "ACTIVE"}');
    debugPrint('=========================================');
  });

  debugPrint('========== SUPABASE INITIAL STATE ==========');
  debugPrint('URL : ${Uri.base}');
  debugPrint('USER : ${supabase.auth.currentUser?.id ?? "NULL"}');
  debugPrint('SESSION : ${supabase.auth.currentSession == null ? "NULL" : "ACTIVE"}');
  debugPrint('============================================');

  runApp(const SmartPassApp());
}