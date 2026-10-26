import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/achievement.dart';
import '../state/app_providers.dart';
import '../widgets/cyber_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  IconData _iconFor(String code) {
    return switch (code) {
      'shield' => Icons.shield_outlined,
      'server' => Icons.dns_outlined,
      'star' => Icons.star_border,
      'grid' => Icons.grid_view,
      'target' => Icons.track_changes,
      'up' => Icons.keyboard_double_arrow_up,
      _ => Icons.emoji_events_outlined,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final isDemo = ref.watch(isDemoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CONQUISTAS DO SISTEMA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: Column(
        children: [
          if (isDemo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.amber.withValues(alpha: 0.15),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo Demonstração: conquistas calculadas com base nas partidas desta sessão.',
                      style: TextStyle(fontSize: 11, color: AppColors.amber),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: achievementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro ao carregar conquistas: $e',
                    style: const TextStyle(color: AppColors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (list) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final item = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AchievementCard(item: item, icon: _iconFor(item.def.icon)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item, required this.icon});

  final AchievementStatus item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final unlocked = item.unlocked;
    final color = unlocked ? AppColors.cyan : AppColors.textDim;

    return CyberCard(
      borderColor: unlocked ? AppColors.cyan : AppColors.border,
      backgroundColor: unlocked
          ? AppColors.surface
          : AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked ? AppColors.cyan.withValues(alpha: 0.2) : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.def.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? AppColors.text : AppColors.textDim,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppColors.green.withValues(alpha: 0.15)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: unlocked ? AppColors.green : AppColors.border,
                        ),
                      ),
                      child: Text(
                        unlocked ? 'DESBLOQUEADO' : 'BLOQUEADO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: unlocked ? AppColors.green : AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.def.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                ),
                const SizedBox(height: 8),

                // Progresso
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: item.fraction,
                          backgroundColor: AppColors.surfaceHigh,
                          valueColor: AlwaysStoppedAnimation(
                            unlocked ? AppColors.green : AppColors.cyan,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.progress}/${item.def.target}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
