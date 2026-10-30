import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio_controller.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(audioControllerProvider.notifier).setTrack(BgmTrack.match);
    });
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

          // 3b. Controles de Zoom e Câmera
          Positioned(
            top: 56,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: _ZoomControlBar(state: state, controller: controller),
            ),
          ),

          // 4. Barra de vida do Chefe (se presente)
          if (state.bossHp != null && state.bossName != null)
            Positioned(
              top: 108,
              left: 24,
              right: 24,
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

          // 7. Painel contextual de torre selecionada (no mapa ou no catálogo)
          if (state.selectedTowerId != null)
            Positioned(
              bottom: 86,
              right: 16,
              child: _TowerDetailPanel(controller: controller),
            )
          else if (state.buildKind != null)
            Positioned(
              bottom: 86,
              right: 16,
              child: _BuildTowerInfoPanel(
                kind: state.buildKind!,
                state: state,
                controller: controller,
              ),
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

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.state, required this.controller});

  final MatchState state;
  final MatchController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioControllerProvider);
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

            const Spacer(),

            // Botão Som / Mudo
            IconButton.filledTonal(
              icon: Icon(
                audioState.isMuted ? Icons.volume_off : Icons.volume_up,
                size: 19,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: audioState.isMuted ? AppColors.textDim : AppColors.cyan,
              ),
              onPressed: () {
                ref.read(audioControllerProvider.notifier).toggleMute();
              },
              tooltip: audioState.isMuted ? 'Ativar música' : 'Silenciar música',
            ),
            const SizedBox(width: 6),

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

class _ZoomControlBar extends StatelessWidget {
  const _ZoomControlBar({required this.state, required this.controller});

  final MatchState state;
  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final canZoomOut = state.zoom > MatchController.minZoom + 0.05;
    final canZoomIn = state.zoom < MatchController.maxZoom - 0.05;
    final isZoomed = state.zoom > 1.05;
    final zoomLabel = '${state.zoom.toStringAsFixed(1)}x';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomMiniButton(
            icon: Icons.remove,
            tooltip: 'Diminuir zoom',
            onPressed: canZoomOut ? controller.zoomOut : null,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: controller.cycleZoom,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.zoom_in, size: 15, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  Text(
                    'ZOOM $zoomLabel',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          _ZoomMiniButton(
            icon: Icons.add,
            tooltip: 'Aumentar zoom',
            onPressed: canZoomIn ? controller.zoomIn : null,
          ),
          if (isZoomed) ...[
            const SizedBox(width: 6),
            _ZoomMiniButton(
              icon: Icons.center_focus_strong,
              tooltip: 'Resetar zoom (visão completa)',
              onPressed: controller.resetZoom,
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text(
                'Arraste p/ mover',
                style: TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoomMiniButton extends StatelessWidget {
  const _ZoomMiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppColors.surfaceHigh : AppColors.background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: enabled ? AppColors.cyan : AppColors.textDim.withValues(alpha: 0.4),
            ),
          ),
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

class _BuildTowerInfoPanel extends StatelessWidget {
  const _BuildTowerInfoPanel({
    required this.kind,
    required this.state,
    required this.controller,
  });

  final TowerKind kind;
  final MatchState state;
  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final cfg = towerConfig(kind);
    final stats = cfg.level(1);
    final canAfford = state.credits >= cfg.buildCost;
    final previewStatus = state.previewStatus;

    final statChips = <String>[
      if (stats.damage > 0) 'Dano ${stats.damage.toStringAsFixed(0)}',
      if (stats.fireRate > 0) '${stats.fireRate.toStringAsFixed(1)}/s',
      'Alc. ${stats.range.toInt()}',
      if (stats.buffPercent > 0) '+${(stats.buffPercent * 100).toInt()}% aliadas',
    ];

    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: AppColors.surface.withValues(alpha: 0.94),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 225),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TowerIconWidget(kind: cfg.kind, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cfg.name.toUpperCase()} · ${cfg.buildCost} cr',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        cfg.role,
                        style: const TextStyle(fontSize: 9.5, color: AppColors.textDim),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: controller.cancelSelection,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 15, color: AppColors.textDim),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              stats.summary,
              style: const TextStyle(fontSize: 10, color: AppColors.text, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                statChips.join('  ·  '),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!canAfford || (previewStatus != null && !previewStatus.isValid)) ...[
              const SizedBox(height: 4),
              Text(
                !canAfford
                    ? 'Créditos insuficientes (${state.credits}/${cfg.buildCost} cr)'
                    : previewStatus!.message,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

    final statChips = <String>[
      if (stats.damage > 0) 'Dano ${tower.effectiveDamage.toStringAsFixed(0)}',
      if (stats.fireRate > 0) '${tower.effectiveFireRate.toStringAsFixed(1)}/s',
      'Alc. ${stats.range.toInt()}',
      if (stats.buffPercent > 0) '+${(stats.buffPercent * 100).toInt()}%',
    ];

    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: AppColors.surface.withValues(alpha: 0.94),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 230),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TowerIconWidget(kind: cfg.kind, size: 24, level: level),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cfg.name.toUpperCase()} (NV $level/${cfg.maxLevel})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        cfg.role,
                        style: const TextStyle(fontSize: 9.5, color: AppColors.textDim),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: controller.cancelSelection,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 15, color: AppColors.textDim),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              stats.summary,
              style: const TextStyle(fontSize: 10, color: AppColors.text, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                statChips.join('  ·  '),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: next != null
                      ? SizedBox(
                          height: 30,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              backgroundColor:
                                  canUpgrade ? AppColors.cyan : AppColors.surfaceHigh,
                              foregroundColor:
                                  canUpgrade ? AppColors.background : AppColors.textDim,
                            ),
                            onPressed: canUpgrade ? controller.upgradeSelected : null,
                            child: Text(
                              'UP (${next.cost} cr)',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NV MÁXIMO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 30,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: AppColors.amber),
                    ),
                    onPressed: controller.sellSelected,
                    child: Text(
                      '+$refund cr',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
