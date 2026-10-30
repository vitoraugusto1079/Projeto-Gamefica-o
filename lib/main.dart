import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/audio_controller.dart';
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

class PhpDefenseApp extends ConsumerStatefulWidget {
  const PhpDefenseApp({super.key});

  @override
  ConsumerState<PhpDefenseApp> createState() => _PhpDefenseAppState();
}

class _PhpDefenseAppState extends ConsumerState<PhpDefenseApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioControllerProvider.notifier).setTrack(BgmTrack.menu);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(audioControllerProvider.notifier).ensurePlaying();
      },
      child: MaterialApp.router(
        title: 'PHP Defense',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    );
  }
}
