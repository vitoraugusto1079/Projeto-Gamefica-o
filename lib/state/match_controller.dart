import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/config/boss_config.dart';
import '../game/config/enemy_config.dart';
import '../game/config/map_config.dart';
import '../game/config/tower_config.dart';
import '../game/config/wave_config.dart';
import '../game/sim/entities.dart';
import '../game/sim/game_simulation.dart';
import '../game/sim/sim_events.dart';
import '../game/sim/vec.dart';
import 'app_providers.dart';

/// Instantâneo imutável do estado da partida para o HUD (Flutter).
/// Atualizado apenas quando algum valor exibido muda.
class MatchState {
  const MatchState({
    required this.credits,
    required this.integrity,
    required this.wave,
    required this.totalWaves,
    required this.wavesCompleted,
    required this.phase,
    required this.speed,
    required this.paused,
    required this.remaining,
    required this.buildKind,
    required this.selectedTowerId,
    required this.previewCell,
    required this.previewStatus,
    required this.towerRevision,
    required this.bossHp,
    required this.bossName,
    required this.bossWarning,
    required this.message,
    required this.messageId,
    required this.damageFlash,
  });

  final int credits;
  final int integrity;
  final int wave;
  final int totalWaves;
  final int wavesCompleted;
  final GamePhase phase;
  final int speed;
  final bool paused;

  /// Inimigos restantes na onda (vivos + ainda por surgir).
  final int remaining;

  /// Torre escolhida no catálogo para construir.
  final TowerKind? buildKind;
  final int? selectedTowerId;
  final Cell? previewCell;
  final PlacementStatus? previewStatus;

  /// Incrementado sempre que torres mudam (construção/melhoria/venda).
  final int towerRevision;

  /// Fração de vida do chefe ativo (nulo se não houver chefe).
  final double? bossHp;
  final String? bossName;
  final bool bossWarning;
  final String? message;
  final int messageId;

  /// Incrementado quando o servidor sofre dano (efeito visual).
  final int damageFlash;

  bool get isOver => phase == GamePhase.victory || phase == GamePhase.defeat;
  bool get canStartWave =>
      phase == GamePhase.betweenWaves && wavesCompleted < totalWaves;

  List<Object?> get _props => [
        credits, integrity, wave, totalWaves, wavesCompleted, phase, speed, paused, remaining,
        buildKind, selectedTowerId, previewCell, previewStatus, towerRevision,
        bossHp == null ? null : (bossHp! * 200).round(), bossName, bossWarning, message,
        messageId, damageFlash,
      ];

  @override
  bool operator ==(Object other) {
    if (other is! MatchState) return false;
    final a = _props;
    final b = other._props;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}

/// Controlador da partida: dono da [GameSimulation], intermedia o HUD
/// (Riverpod) e a camada Flame. É descartado ao sair da tela da partida.
class MatchController extends Notifier<MatchState> {
  late GameSimulation sim;
  final MapConfig map = circuitAlpha;

  TowerKind? _buildKind;
  int? _selectedTowerId;
  Cell? _previewCell;
  int _towerRevision = 0;
  bool _bossWarning = false;
  double _bossWarningTimer = 0;
  String? _message;
  int _messageId = 0;
  double _messageTimer = 0;
  int _damageFlash = 0;
  int _matchKey = 0;
  static int _matchKeySeed = 0;
  Future<String?> _matchId = Future.value(null);
  bool _disposed = false;

  TowerKind? get buildKind => _buildKind;
  Cell? get previewCell => _previewCell;
  PlacementStatus? get previewStatus => (_buildKind != null && _previewCell != null)
      ? sim.checkPlacement(_buildKind!, _previewCell!)
      : null;

  @override
  MatchState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      sim.paused = true;
    });
    _newMatch();
    return _snapshot();
  }

  void _newMatch() {
    sim = GameSimulation(map: map);
    _buildKind = null;
    _selectedTowerId = null;
    _previewCell = null;
    _towerRevision++;
    _bossWarning = false;
    _message = null;
    _matchKey = ++_matchKeySeed;
    final backend = ref.read(backendProvider);
    if (backend != null && backend.currentUser != null) {
      // Registra o início no servidor; falhas não impedem a partida local.
      final f = backend.startMatch(map.id).then<String?>((id) => id).catchError((Object _) {
        _toast('Sem conexão com o servidor: este resultado não será salvo.');
        return null;
      });
      _matchId = f;
    } else {
      _matchId = Future.value(null);
    }
  }

  // ---- Laço chamado pelo Flame --------------------------------------------

  /// Avança a simulação e devolve os eventos para os efeitos visuais.
  List<SimEvent> tick(double dt) {
    if (_disposed) return const [];
    sim.advance(dt);
    final events = sim.drainEvents();
    for (final e in events) {
      switch (e) {
        case EnemyLeakedEvent():
          _damageFlash++;
        case BossSpawnedEvent():
          _bossWarning = true;
          _bossWarningTimer = 5;
        case BossSplitEvent(:final released):
          _toast('${enemyConfig(e.kind).name} se fragmentou em $released ameaças!');
        case WaveCompletedEvent(:final wave, :final bonus):
          if (!sim.isOver) _toast('Onda $wave concluída! +$bonus créditos');
        case GameOverEvent():
          _onGameOver();
        default:
          break;
      }
    }
    // Temporizadores de interface só correm quando a simulação corre.
    if (!sim.paused && !sim.isOver) {
      final scaled = dt * sim.speed;
      if (_bossWarningTimer > 0) {
        _bossWarningTimer -= scaled;
        if (_bossWarningTimer <= 0) _bossWarning = false;
      }
    }
    if (_messageTimer > 0 && !sim.paused) {
      _messageTimer -= dt;
      if (_messageTimer <= 0) _message = null;
    }
    // Torre selecionada pode ter sido vendida.
    if (_selectedTowerId != null && sim.towerById(_selectedTowerId!) == null) {
      _selectedTowerId = null;
    }
    _publish();
    return events;
  }

  void _onGameOver() {
    final outcome = sim.outcome;
    if (outcome == null) return;
    _buildKind = null;
    _previewCell = null;
    ref.read(resultProvider.notifier).submit(
          matchKey: _matchKey,
          outcome: outcome,
          matchId: _matchId,
        );
  }

  // ---- Ações do jogador ---------------------------------------------------

  void selectBuildKind(TowerKind? kind) {
    if (sim.isOver) return;
    _buildKind = (_buildKind == kind) ? null : kind;
    _selectedTowerId = null;
    _previewCell = null;
    _publish();
  }

  void cancelSelection() {
    _buildKind = null;
    _selectedTowerId = null;
    _previewCell = null;
    _publish();
  }

  /// Movimento do ponteiro (mouse) sobre o mapa.
  void hoverAt(Vec p) {
    if (_buildKind == null) return;
    final cell = map.cellAt(p);
    if (_previewCell != cell) {
      _previewCell = cell;
      _publish();
    }
  }

  void hoverExit() {
    if (_buildKind != null && _previewCell != null) {
      _previewCell = null;
      _publish();
    }
  }

  /// Toque/clique no mapa.
  /// Com mouse, um clique em posição válida constrói direto. No toque, o
  /// primeiro toque mostra a prévia e o segundo na mesma célula confirma.
  void tapAt(Vec p, {required bool isMouse}) {
    if (sim.isOver) return;
    final cell = map.cellAt(p);
    final kind = _buildKind;
    if (kind != null) {
      final status = sim.checkPlacement(kind, cell);
      final confirm = isMouse || _previewCell == cell;
      _previewCell = cell;
      if (confirm && status.isValid) {
        _place(kind, cell);
      } else if (confirm && !status.isValid) {
        _toast(status.message);
      }
      _publish();
      return;
    }
    final tower = sim.towerAt(cell);
    _selectedTowerId = tower?.id;
    _publish();
  }

  /// Confirma a construção na célula da prévia (botão do HUD).
  void confirmPlacement() {
    final kind = _buildKind;
    final cell = _previewCell;
    if (kind == null || cell == null) return;
    final status = sim.checkPlacement(kind, cell);
    if (!status.isValid) {
      _toast(status.message);
      _publish();
      return;
    }
    _place(kind, cell);
    _publish();
  }

  void _place(TowerKind kind, Cell cell) {
    final t = sim.buildTower(kind, cell);
    if (t == null) return;
    _towerRevision++;
    _previewCell = null;
    // Mantém o tipo selecionado se ainda houver créditos para outra torre.
    if (sim.credits < towerConfig(kind).buildCost) _buildKind = null;
  }

  SimTower? get selectedTower =>
      _selectedTowerId == null ? null : sim.towerById(_selectedTowerId!);

  void upgradeSelected() {
    final t = selectedTower;
    if (t == null) return;
    if (sim.upgradeTower(t)) {
      _towerRevision++;
    } else if (t.canUpgrade) {
      _toast('Créditos insuficientes para melhorar.');
    }
    _publish();
  }

  void sellSelected() {
    final t = selectedTower;
    if (t == null) return;
    final refund = sim.sellTower(t);
    if (refund > 0) _toast('${t.config.name} vendida: +$refund créditos');
    _selectedTowerId = null;
    _towerRevision++;
    _publish();
  }

  void startWave() {
    if (sim.startNextWave()) {
      _publish();
    }
  }

  void toggleSpeed() {
    sim.speed = sim.speed == 1 ? 2 : 1;
    _publish();
  }

  void setPaused(bool value) {
    if (sim.isOver) return;
    sim.paused = value;
    _publish();
  }

  void togglePause() => setPaused(!sim.paused);

  void restart() {
    _newMatch();
    _publish();
  }

  // ---- Informações auxiliares para a interface ----------------------------

  /// Ameaças que aparecem pela primeira vez na próxima onda.
  List<EnemyConfig> get newThreatsNextWave {
    final next = sim.nextWaveConfig;
    if (next == null) return const [];
    final first = firstAppearance();
    final waveNumber = sim.wavesCompleted + 1;
    return next.kinds
        .where((k) => first[k] == waveNumber && !enemyConfig(k).isBoss)
        .map(enemyConfig)
        .toList();
  }

  BossConfig? get bossNextWave {
    final next = sim.nextWaveConfig;
    if (next == null) return null;
    for (final k in next.kinds) {
      final b = bossConfigs[k];
      if (b != null) return b;
    }
    return null;
  }

  // ---- Publicação de estado -----------------------------------------------

  void _toast(String msg) {
    _message = msg;
    _messageId++;
    _messageTimer = 2.6;
  }

  SimEnemy? get _boss {
    for (final e in sim.enemies) {
      if (e.config.isBoss && e.alive) return e;
    }
    return null;
  }

  MatchState _snapshot() {
    final boss = _boss;
    final kind = _buildKind;
    final cell = _previewCell;
    return MatchState(
      credits: sim.credits,
      integrity: sim.integrity,
      wave: sim.currentWave,
      totalWaves: sim.totalWaves,
      wavesCompleted: sim.wavesCompleted,
      phase: sim.phase,
      speed: sim.speed,
      paused: sim.paused,
      remaining: sim.phase == GamePhase.waveActive ? sim.aliveEnemies + sim.pendingSpawns : 0,
      buildKind: kind,
      selectedTowerId: _selectedTowerId,
      previewCell: cell,
      previewStatus: (kind != null && cell != null) ? sim.checkPlacement(kind, cell) : null,
      towerRevision: _towerRevision,
      bossHp: boss?.hpFraction,
      bossName: boss?.config.name,
      bossWarning: _bossWarning,
      message: _message,
      messageId: _messageId,
      damageFlash: _damageFlash,
    );
  }

  void _publish() {
    if (_disposed) return;
    final next = _snapshot();
    if (next != state) state = next;
  }
}

final matchControllerProvider =
    NotifierProvider.autoDispose<MatchController, MatchState>(MatchController.new);
