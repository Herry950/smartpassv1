
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/theme_controller.dart';
import 'core/constants/supabase_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // Capturer l'URL initiale avant le démarrage de GoRouter.
  final initialUri = Uri.base;

  await initializeDateFormatting('fr_FR');

  // Thème choisi par l'utilisateur (conservé entre les sessions).
  await ThemeController.load();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
    authOptions: const FlutterAuthClientOptions(
      detectSessionInUri: false,
    ),
  );

  final supabase = Supabase.instance.client;

  supabase.auth.onAuthStateChange.listen(
    (data) {
      debugPrint('========== SUPABASE AUTH EVENT ==========');
      debugPrint('EVENT : ${data.event}');
      debugPrint('USER : ${data.session?.user.id ?? "NULL"}');
      debugPrint('EMAIL : ${data.session?.user.email ?? "NULL"}');
      debugPrint(
        'SESSION : ${data.session == null ? "NULL" : "ACTIVE"}',
      );
      debugPrint('=========================================');
    },
    onError: (error) {
      debugPrint('SUPABASE AUTH STREAM ERROR: $error');
    },
  );

  final fragmentUri = Uri.tryParse(
    initialUri.hasFragment ? '?${initialUri.fragment}' : '',
  );

  final callbackParameters =
      fragmentUri?.queryParameters ?? <String, String>{};

  debugPrint('========== SMARTPASS INITIAL STATE ==========');
  debugPrint('PATH : ${initialUri.path}');
  debugPrint(
    'QUERY PARAMETERS : ${initialUri.queryParameters.keys.toList()}',
  );
  debugPrint(
    'FRAGMENT PARAMETERS : ${callbackParameters.keys.toList()}',
  );
  debugPrint(
    'SUPABASE CALLBACK ERROR : ${callbackParameters['error'] ?? 'NONE'}',
  );
  debugPrint(
    'SUPABASE CALLBACK ERROR CODE : '
    '${callbackParameters['error_code'] ?? 'NONE'}',
  );
  debugPrint(
    'SUPABASE CALLBACK ERROR DESCRIPTION : '
    '${callbackParameters['error_description'] ?? 'NONE'}',
  );
  debugPrint(
    'HAS SB PARAMETER : ${callbackParameters.containsKey('sb')}',
  );
  debugPrint(
    'SESSION : '
    '${supabase.auth.currentSession == null ? "NULL" : "ACTIVE"}',
  );
  debugPrint('============================================');

  runApp(
    SmartPassApp(initialUri: initialUri),
  );
}
