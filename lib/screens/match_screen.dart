import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../game/config/tower_config.dart';
import '../game/flame/php_defense_game.dart';
import '../game/sim/game_simulation.dart';
import '../state/match_controller.dart';
import '../widgets/cyber_widgets.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  PhpDefenseGame? _game;

  @override
  void initState() {
    super.initState();
    // Cria o jogo Flame acoplado ao controller gerenciado pelo Riverpod
    final controller = ref.read(matchControllerProvider.notifier);
    _game = PhpDefenseGame(controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchControllerProvider);
    final controller = ref.read(matchControllerProvider.notifier);

    // Navega automaticamente ao terminar a partida
    ref.listen(matchControllerProvider.select((s) => s.isOver), (prev, isOver) {
      if (isOver) {
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          router.go('/result');
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Camada de renderização Flame
          if (_game != null)
            Positioned.fill(
              child: GameWidget(game: _game!),
            ),

          // 2. Flash avermelhado ao sofrer dano
          if (state.damageFlash > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(state.damageFlash),
                  tween: Tween(begin: 0.35, end: 0.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, child) {
                    return Container(
                      color: AppColors.red.withValues(alpha: val),
                    );
                  },
                ),
              ),
            ),

          // 3. Barra Superior (HUD)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(state: state, controller: controller),
          ),

          // 4. Barra de vida do Chefe (se presente)
          if (state.bossHp != null && state.bossName != null)
            Positioned(
              top: 60,
              left: 40,
              right: 40,
              child: _BossBar(name: state.bossName!, hpFraction: state.bossHp!),
            ),

          // 5. Alerta de chegada do Chefe
          if (state.bossWarning)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: const _BossWarningBanner(),
            ),

          // 6. Toast flutuante de mensagens do sistema
          if (state.message != null)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cyan),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    state.message!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ),
            ),

          // 7. Painel contextual de torre selecionada no mapa
          if (state.selectedTowerId != null)
            Positioned(
              bottom: 86,
              right: 16,
              child: _TowerDetailPanel(controller: controller),
            ),

          // 8. Barra inferior: Catálogo de torres e controle de ondas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCatalogBar(state: state, controller: controller),
          ),

          // 9. Overlay de pausa
          if (state.paused)
            Positioned.fill(
              child: _PauseOverlay(controller: controller),
            ),

          // 10. Overlay de fim de partida (Vitória / Derrota)
          if (state.isOver)
            Positioned.fill(
              child: _GameOverOverlay(victory: state.phase == GamePhase.victory),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.controller});

  final MatchState state;
  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.88),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Integridade do Servidor PHP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.integrity > 30 ? AppColors.green : AppColors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dns,
                    size: 16,
                    color: state.integrity > 30 ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${state.integrity} HP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: state.integrity > 30 ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Créditos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amber, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Text(
                    '${state.credits}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Onda atual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan, width: 1.5),
              ),
              child: Text(
                'ONDA ${state.wave}/${state.totalWaves}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),

            if (state.remaining > 0) ...[
              const SizedBox(width: 8),
              Text(
                '(${state.remaining} rest.)',
                style: const TextStyle(fontSize: 11, color: AppColors.textDim),
              ),
            ],

            const Spacer(),

            // Botão Velocidade 1x/2x
            IconButton.filledTonal(
              icon: Text(
                '${state.speed}x',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: IconButton.styleFrom(
                backgroundColor: state.speed == 2 ? AppColors.cyan : AppColors.surface,
                foregroundColor: state.speed == 2 ? AppColors.background : AppColors.cyan,
              ),
              onPressed: controller.toggleSpeed,
              tooltip: 'Alterar velocidade (1x ou 2x)',
            ),
            const SizedBox(width: 6),

            // Botão Pausa
            IconButton.filledTonal(
              icon: Icon(state.paused ? Icons.play_arrow : Icons.pause, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.cyan,
              ),
              onPressed: controller.togglePause,
              tooltip: 'Pausar',
            ),
          ],
        ),
      ),
    );
  }
}

class _BossBar extends StatelessWidget {
  const _BossBar({required this.name, required this.hpFraction});

  final String name;
  final double hpFraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB04DFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB04DFF).withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AMEAÇA CHEFE: $name',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFFB04DFF),
                ),
              ),
              Text(
                '${(hpFraction * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB04DFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hpFraction,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFB04DFF)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BossWarningBanner extends StatelessWidget {
  const _BossWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.5),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'ALERTA: HYDRA AI DETECTADA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCatalogBar extends StatelessWidget {
  const _BottomCatalogBar({required this.state, required this.controller});

  final MatchState state;
  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Catálogo de torres
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TowerKind.values.map((k) {
                    final cfg = towerConfig(k);
                    final isSelected = state.buildKind == k;
                    final canAfford = state.credits >= cfg.buildCost;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => controller.selectBuildKind(k),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 82,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.cyan.withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.cyan
                                  : (canAfford ? AppColors.border : AppColors.surfaceHigh),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TowerIconWidget(kind: k, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                cfg.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? AppColors.text : AppColors.textDim,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${cfg.buildCost} cr',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? AppColors.amber : AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botão de confirmação de toque OU botão de Iniciar Onda
            if (state.buildKind != null && state.previewCell != null) ...[
              FilledButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('CONSTRUIR'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.background,
                ),
                onPressed: controller.confirmPlacement,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: controller.cancelSelection,
                tooltip: 'Cancelar',
              ),
            ] else ...[
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  state.phase == GamePhase.waveActive ? 'EM ONDA' : 'INICIAR ONDA',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: state.canStartWave ? AppColors.cyan : AppColors.surfaceHigh,
                  foregroundColor:
                      state.canStartWave ? AppColors.background : AppColors.textDim,
                  minimumSize: const Size(130, 48),
                ),
                onPressed: state.canStartWave ? controller.startWave : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TowerDetailPanel extends StatelessWidget {
  const _TowerDetailPanel({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final tower = controller.selectedTower;
    if (tower == null) return const SizedBox.shrink();

    final cfg = tower.config;
    final level = tower.level;
    final stats = tower.stats;
    final next = tower.nextLevel;
    final refund = controller.sim.sellValue(tower);
    final canUpgrade = controller.sim.canUpgrade(tower);

    return CyberCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TowerIconWidget(kind: cfg.kind, size: 36, level: level),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                      Text(
                        'Nível $level de ${cfg.maxLevel} · ${cfg.role}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.cancelSelection,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Atributos
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  if (stats.damage > 0)
                    _MiniRow(label: 'Dano efetivo', value: tower.effectiveDamage.toStringAsFixed(1)),
                  if (stats.fireRate > 0)
                    _MiniRow(label: 'Cadência', value: '${tower.effectiveFireRate.toStringAsFixed(1)}/s'),
                  _MiniRow(label: 'Alcance', value: '${stats.range.toInt()} px'),
                  if (stats.splashRadius > 0)
                    _MiniRow(label: 'Área', value: '${stats.splashRadius.toInt()} px'),
                  if (tower.buff > 0)
                    _MiniRow(label: 'Bônus de suporte', value: '+${(tower.buff * 100).toInt()}%'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Melhoria
            if (next != null) ...[
              Text(
                'Próximo nível: ${next.summary}',
                style: const TextStyle(fontSize: 11, color: AppColors.cyan),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_upward, size: 16),
                label: Text('MELHORAR (${next.cost} cr)'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  backgroundColor: canUpgrade ? AppColors.cyan : AppColors.surfaceHigh,
                  foregroundColor: canUpgrade ? AppColors.background : AppColors.textDim,
                ),
                onPressed: canUpgrade ? controller.upgradeSelected : null,
              ),
            ] else ...[
              const Center(
                child: Text(
                  'NÍVEL MÁXIMO ATINGIDO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Venda (70% do investido)
            OutlinedButton.icon(
              icon: const Icon(Icons.sell_outlined, size: 16, color: AppColors.amber),
              label: Text('VENDER (+$refund cr)', style: const TextStyle(color: AppColors.amber)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                side: const BorderSide(color: AppColors.amber),
              ),
              onPressed: controller.sellSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
          Text(value,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.85),
      child: Center(
        child: CyberCard(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'SIMULAÇÃO PAUSADA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: controller.togglePause,
                  child: const Text('CONTINUAR'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: controller.restart,
                  child: const Text('REINICIAR PARTIDA'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/menu'),
                  child: const Text('SAIR PARA O MENU'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.victory});

  final bool victory;

  @override
  Widget build(BuildContext context) {
    final color = victory ? AppColors.green : AppColors.red;

    return Container(
      color: AppColors.background.withValues(alpha: 0.88),
      child: Center(
        child: CyberCard(
          padding: const EdgeInsets.all(32),
          borderColor: color,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  victory ? Icons.verified : Icons.warning_amber_rounded,
                  size: 56,
                  color: color,
                ),
                const SizedBox(height: 16),
                Text(
                  victory ? 'SERVIDOR PROTEGIDO' : 'SERVIDOR COMPROMETIDO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  victory
                      ? 'Todas as 15 ondas cibernéticas foram neutralizadas com sucesso.'
                      : 'A integridade do servidor PHP chegou a zero.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textDim),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: () => context.go('/result'),
                  child: const Text('VER RELATÓRIO DA PARTIDA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
