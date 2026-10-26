import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../game/sim/score_rules.dart';
import '../state/app_providers.dart';
import '../widgets/cyber_widgets.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultProvider);

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nenhum resultado recente de partida.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/menu'),
                child: const Text('VOLTAR AO MENU'),
              ),
            ],
          ),
        ),
      );
    }

    final o = result.outcome;
    final color = o.victory ? AppColors.green : AppColors.red;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: CyberCard(
                borderColor: color,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho de Status
                    Row(
                      children: [
                        Icon(
                          o.victory ? Icons.verified : Icons.error_outline,
                          size: 38,
                          color: color,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.victory ? 'MISSÃO CONCLUÍDA' : 'FALHA NA DEFESA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: color,
                                ),
                              ),
                              Text(
                                o.victory
                                    ? 'O servidor PHP permaneceu íntegro e operacional.'
                                    : 'A aplicação foi invadida e o servidor entrou em colapso.',
                                style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pontuação em destaque
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PONTUAÇÃO FINAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${o.score}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detalhamento dos pontos
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _ScoreRow(
                            label: 'Ondas concluídas (${o.wavesCompleted} × ${ScoreRules.perWave})',
                            value: '+${o.wavesCompleted * ScoreRules.perWave}',
                          ),
                          const Divider(color: AppColors.border, height: 14),
                          _ScoreRow(
                            label: 'Ameaças eliminadas (${o.kills} × ${ScoreRules.perKill})',
                            value: '+${o.kills * ScoreRules.perKill}',
                          ),
                          const Divider(color: AppColors.border, height: 14),
                          _ScoreRow(
                            label: 'Integridade restante (${o.integrity} × ${ScoreRules.perIntegrity})',
                            value: '+${o.integrity * ScoreRules.perIntegrity}',
                          ),
                          if (o.victory) ...[
                            const Divider(color: AppColors.border, height: 14),
                            _ScoreRow(
                              label: 'Bônus de vitória',
                              value: '+${ScoreRules.victoryBonus}',
                              isBonus: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status de envio ao backend / modo demo
                    _SubmissionStatusWidget(result: result),
                    const SizedBox(height: 20),

                    // Ações
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.replay),
                            label: const Text('NOVA PARTIDA'),
                            onPressed: () => context.go('/match'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.leaderboard_outlined),
                            label: const Text('RANKING'),
                            onPressed: () => context.go('/ranking'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/menu'),
                      child: const Text('VOLTAR AO MENU PRINCIPAL'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    this.isBonus = false,
  });

  final String label;
  final String value;
  final bool isBonus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isBonus ? AppColors.green : AppColors.cyan,
          ),
        ),
      ],
    );
  }
}

class _SubmissionStatusWidget extends StatelessWidget {
  const _SubmissionStatusWidget({required this.result});

  final ResultData result;

  @override
  Widget build(BuildContext context) {
    switch (result.status) {
      case SubmissionStatus.demo:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.amber),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modo Demonstração Local: resultado salvo apenas nesta sessão.',
                  style: TextStyle(fontSize: 11, color: AppColors.amber),
                ),
              ),
            ],
          ),
        );
      case SubmissionStatus.sending:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Registrando resultado no ranking...', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      case SubmissionStatus.saved:
        final newAch = result.submission?.newAchievements ?? const [];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.green),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_done_outlined, size: 16, color: AppColors.green),
                  SizedBox(width: 8),
                  Text(
                    'Resultado sincronizado com o ranking do servidor!',
                    style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (newAch.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '🎉 Novas conquistas desbloqueadas: ${newAch.join(', ')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.cyan),
                ),
              ],
            ],
          ),
        );
      case SubmissionStatus.failed:
      case SubmissionStatus.notRegistered:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.red),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.error ?? 'Falha ao salvar no servidor.',
                  style: const TextStyle(fontSize: 11, color: AppColors.red),
                ),
              ),
            ],
          ),
        );
    }
  }
}
