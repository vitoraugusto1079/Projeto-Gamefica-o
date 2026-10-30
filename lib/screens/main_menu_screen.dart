import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio_controller.dart';
import '../core/theme.dart';
import '../state/app_providers.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(isDemoProvider);
    final user = ref.watch(authUserProvider).value;
    final profile = ref.watch(profileProvider).value;
    final audioState = ref.watch(audioControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Logo e Título
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cyan, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.25),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PHP',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'PHP DEFENSE',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'TOWER DEFENSE DE CIBERSEGURANÇA',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: AppColors.cyan.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pill de estado (Demo vs Autenticado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDemo || user == null
                          ? AppColors.amber.withValues(alpha: 0.12)
                          : AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDemo || user == null ? AppColors.amber : AppColors.cyan,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDemo || user == null ? Icons.info_outline : Icons.verified_user,
                          size: 16,
                          color: isDemo || user == null ? AppColors.amber : AppColors.cyan,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isDemo || user == null
                                ? 'Modo Demonstração Local (Offline)'
                                : 'Defensor: ${profile?.nickname ?? 'Carregando...'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDemo || user == null ? AppColors.amber : AppColors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botões principais
                  _MenuButton(
                    icon: Icons.play_arrow,
                    label: 'DEFENDER SERVIDOR',
                    color: AppColors.cyan,
                    textColor: AppColors.background,
                    isPrimary: true,
                    onPressed: () => context.go('/map-select'),
                  ),
                  const SizedBox(height: 12),

                  _MenuButton(
                    icon: Icons.school_outlined,
                    label: 'TUTORIAL DIDÁTICO',
                    color: AppColors.surfaceHigh,
                    textColor: AppColors.text,
                    onPressed: () => context.go('/tutorial'),
                  ),
                  const SizedBox(height: 12),

                  _MenuButton(
                    icon: Icons.emoji_events_outlined,
                    label: 'CONQUISTAS',
                    color: AppColors.surfaceHigh,
                    textColor: AppColors.text,
                    onPressed: () => context.go('/achievements'),
                  ),
                  const SizedBox(height: 12),

                  _MenuButton(
                    icon: Icons.leaderboard_outlined,
                    label: 'RANKING GLOBAL',
                    color: AppColors.surfaceHigh,
                    textColor: AppColors.text,
                    onPressed: () => context.go('/ranking'),
                  ),
                  const SizedBox(height: 12),

                  _MenuButton(
                    icon: Icons.person_outline,
                    label: user == null ? 'CONECTAR CONTA' : 'MEU PERFIL',
                    color: AppColors.surfaceHigh,
                    textColor: AppColors.text,
                    onPressed: () => context.go(user == null ? '/auth' : '/profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
            Positioned(
              top: 12,
              right: 16,
              child: IconButton.filledTonal(
                icon: Icon(
                  audioState.isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: audioState.isMuted ? AppColors.textDim : AppColors.cyan,
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                ),
                tooltip: audioState.isMuted ? 'Ativar música' : 'Silenciar música',
                onPressed: () {
                  ref.read(audioControllerProvider.notifier).toggleMute();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        height: 52,
        child: FilledButton.icon(
          icon: Icon(icon, size: 22),
          label: Text(label, style: const TextStyle(fontSize: 14, letterSpacing: 1.5)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onPressed,
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 20, color: AppColors.cyan),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 13, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
