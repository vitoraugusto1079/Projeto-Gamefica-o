import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppEnv.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseKey,
      );
    } catch (e) {
      // Falhas na inicialização do backend são tratadas exibindo o modo demonstração
      debugPrint('Falha ao inicializar Supabase: $e');
    }
  }

  runApp(const ProviderScope(child: PhpDefenseApp()));
}

class PhpDefenseApp extends ConsumerWidget {
  const PhpDefenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PHP Defense',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
