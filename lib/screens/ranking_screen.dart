import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/leaderboard_entry.dart';
import '../state/app_providers.dart';
import '../widgets/cyber_widgets.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  Color _badgeColor(int rank) {
    return switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => AppColors.border,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(leaderboardProvider);
    final isDemo = ref.watch(isDemoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RANKING GLOBAL DE DEFENSORES'),
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
                      'Modo Demonstração: configure as credenciais do Supabase para sincronizar com o ranking global.',
                      style: TextStyle(fontSize: 11, color: AppColors.amber),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: rankingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro ao carregar ranking: $e',
                    style: const TextStyle(color: AppColors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum resultado registrado ainda no ranking.',
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RankItemCard(item: item, badgeColor: _badgeColor(item.rank)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankItemCard extends StatelessWidget {
  const _RankItemCard({required this.item, required this.badgeColor});

  final LeaderboardEntry item;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final isTop3 = item.rank <= 3;

    return CyberCard(
      borderColor: item.isMe ? AppColors.cyan : (isTop3 ? badgeColor : AppColors.border),
      backgroundColor: item.isMe
          ? AppColors.cyan.withValues(alpha: 0.12)
          : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Posição no ranking
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isTop3 ? badgeColor.withValues(alpha: 0.2) : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor, width: isTop3 ? 2 : 1),
            ),
            child: Center(
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? badgeColor : AppColors.textDim,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Apelido do defensor (nunca expõe e-mail)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.nickname,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: item.isMe ? AppColors.cyan : AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VOCÊ',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Vitórias: ${item.wins} · Maior onda: ${item.bestWave}/15',
                  style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                ),
              ],
            ),
          ),

          // Pontuação máxima
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.bestScore}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Text(
                'pontos',
                style: TextStyle(fontSize: 9, color: AppColors.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
