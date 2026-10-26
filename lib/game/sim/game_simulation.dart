import 'dart:math' as math;

import '../../models/match_outcome.dart';
import '../config/boss_config.dart';
import '../config/enemy_config.dart';
import '../config/game_rules.dart';
import '../config/map_config.dart';
import '../config/tower_config.dart';
import '../config/wave_config.dart';
import 'entities.dart';
import 'path_track.dart';
import 'score_rules.dart';
import 'sim_events.dart';
import 'vec.dart';

enum GamePhase {
  /// Entre ondas: aguardando o botão "Iniciar onda".
  betweenWaves,
  waveActive,
  victory,
  defeat,
}

enum PlacementStatus { valid, outOfBounds, onPath, occupied, insufficientCredits, gameOver }

extension PlacementStatusText on PlacementStatus {
  bool get isValid => this == PlacementStatus.valid;
  String get message => switch (this) {
        PlacementStatus.valid => 'Posição válida',
        PlacementStatus.outOfBounds => 'Fora do mapa',
        PlacementStatus.onPath => 'Não é possível construir no caminho ou no servidor',
        PlacementStatus.occupied => 'Já existe uma torre aqui',
        PlacementStatus.insufficientCredits => 'Créditos insuficientes',
        PlacementStatus.gameOver => 'A partida terminou',
      };
}

class _PendingSpawn {
  _PendingSpawn(this.time, this.kind, this.hpMultiplier);
  final double time;
  final EnemyKind kind;
  final double hpMultiplier;
}

/// Simulação completa da partida, em Dart puro (sem Flutter/Flame).
///
/// Toda a lógica roda em passos fixos de [GameRules.fixedTimeStep]. A camada
/// visual chama [advance] com o delta real do quadro; a velocidade 2x apenas
/// executa mais passos fixos por segundo real, então o resultado da partida é
/// idêntico em 1x e 2x.
class GameSimulation {
  GameSimulation({
    this.map = circuitAlpha,
    this.rules = GameRules.standard,
    List<WaveConfig>? waves,
  })  : waves = waves ?? waveConfigs,
        track = PathTrack(map.pathPoints),
        _blocked = map.blockedCells,
        integrity = rules.startingIntegrity,
        credits = rules.startingCredits {
    final errors = map.validate();
    if (errors.isNotEmpty) {
      throw StateError('Mapa inválido: ${errors.join('; ')}');
    }
  }

  final MapConfig map;
  final GameRules rules;
  final List<WaveConfig> waves;
  final PathTrack track;
  final Set<Cell> _blocked;

  // ---- Estado público -------------------------------------------------------
  int integrity;
  int credits;
  GamePhase phase = GamePhase.betweenWaves;

  /// Número de ondas concluídas.
  int wavesCompleted = 0;

  /// Onda atual (1-based) quando ativa; senão, a próxima.
  int get currentWave => phase == GamePhase.waveActive
      ? wavesCompleted + 1
      : math.min(wavesCompleted + 1, waves.length);
  int get totalWaves => waves.length;

  int speed = 1;
  bool paused = false;

  int kills = 0;
  bool bossDefeated = false;
  final Set<TowerKind> towerKindsBuilt = {};
  int maxTowerLevel = 0;
  double simTime = 0;

  final List<SimEnemy> enemies = [];
  final Map<Cell, SimTower> towersByCell = {};
  final List<SimProjectile> projectiles = [];
  final List<SimEvent> _events = [];

  Iterable<SimTower> get towers => towersByCell.values;
  bool get isOver => phase == GamePhase.victory || phase == GamePhase.defeat;
  bool get canStartWave => phase == GamePhase.betweenWaves && wavesCompleted < waves.length;
  WaveConfig? get nextWaveConfig =>
      wavesCompleted < waves.length ? waves[wavesCompleted] : null;

  /// Inimigos previstos que ainda não surgiram na onda atual.
  int get pendingSpawns => _queue.length - _queueIndex;
  int get aliveEnemies => enemies.length;

  MatchOutcome? _outcome;

  /// Resultado final (não nulo somente após vitória/derrota). Criado uma vez.
  MatchOutcome? get outcome => _outcome;

  int _nextId = 1;
  double _accumulator = 0;
  double _waveTime = 0;
  List<_PendingSpawn> _queue = [];
  int _queueIndex = 0;

  // ---- Eventos -------------------------------------------------------------
  List<SimEvent> drainEvents() {
    if (_events.isEmpty) return const [];
    final copy = List<SimEvent>.of(_events);
    _events.clear();
    return copy;
  }

  // ---- Laço de tempo -------------------------------------------------------

  /// Avança a simulação com o tempo real decorrido no quadro.
  void advance(double realDt) {
    if (paused || isOver) return;
    if (realDt <= 0) return;
    // Limita quadros muito longos (ex.: aba em segundo plano).
    final dt = math.min(realDt, 0.25);
    _accumulator += dt * speed;
    final step = rules.fixedTimeStep;
    var steps = 0;
    final maxSteps = rules.maxStepsPerFrame * speed;
    while (_accumulator >= step && steps < maxSteps) {
      this.step(step);
      _accumulator -= step;
      steps++;
      if (isOver) break;
    }
    if (steps >= maxSteps) _accumulator = 0;
  }

  /// Executa um passo fixo da simulação.
  void step(double dt) {
    if (isOver) return;
    simTime += dt;
    if (phase == GamePhase.waveActive) {
      _spawnDue(dt);
    }
    _applySupportEffects();
    _updateEnemies(dt);
    if (isOver) return;
    _updateTowers(dt);
    _updateProjectiles(dt);
    _checkWaveEnd();
  }

  // ---- Ondas ---------------------------------------------------------------

  bool startNextWave() {
    if (!canStartWave) return false;
    final wave = waves[wavesCompleted];
    final scale = waveHpScale(wavesCompleted + 1);
    final list = <_PendingSpawn>[];
    for (final g in wave.groups) {
      for (var i = 0; i < g.count; i++) {
        list.add(_PendingSpawn(g.delay + i * g.interval, g.kind, g.hpMultiplier * scale));
      }
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    _queue = list;
    _queueIndex = 0;
    _waveTime = 0;
    phase = GamePhase.waveActive;
    return true;
  }

  void _spawnDue(double dt) {
    _waveTime += dt;
    while (_queueIndex < _queue.length && _queue[_queueIndex].time <= _waveTime) {
      final p = _queue[_queueIndex++];
      final e = spawnEnemy(p.kind, hpMultiplier: p.hpMultiplier);
      if (e.config.isBoss) _events.add(BossSpawnedEvent(e.kind));
    }
  }

  /// Cria um inimigo no caminho. Público para testes.
  SimEnemy spawnEnemy(
    EnemyKind kind, {
    double hpMultiplier = 1,
    double distance = 0,
    bool fromBoss = false,
  }) {
    final cfg = enemyConfig(kind);
    final d = distance.clamp(0.0, track.length);
    final e = SimEnemy(
      id: _nextId++,
      config: cfg,
      maxHp: cfg.maxHp * hpMultiplier,
      distance: d,
      position: track.positionAt(d),
      fromBoss: fromBoss,
    );
    enemies.add(e);
    return e;
  }

  void _checkWaveEnd() {
    if (phase != GamePhase.waveActive) return;
    if (_queueIndex < _queue.length) return;
    if (enemies.isNotEmpty) return;
    wavesCompleted++;
    final bonus = rules.waveBonus(wavesCompleted);
    credits += bonus;
    _events.add(WaveCompletedEvent(wavesCompleted, bonus));
    projectiles.clear();
    if (wavesCompleted >= waves.length) {
      _finish(victory: true);
    } else {
      phase = GamePhase.betweenWaves;
    }
  }

  // ---- Inimigos ------------------------------------------------------------

  void _updateEnemies(double dt) {
    for (final e in enemies) {
      if (!e.alive) continue;
      if (e.revealTimer > 0) e.revealTimer = math.max(0, e.revealTimer - dt);
      if (e.slowTimer > 0) e.slowTimer = math.max(0, e.slowTimer - dt);
      if (e.patchTimer > 0) e.patchTimer = math.max(0, e.patchTimer - dt);
      e.distance += e.currentSpeed * dt;
      if (e.distance >= track.length) {
        e.alive = false;
        integrity = math.max(0, integrity - e.config.baseDamage);
        _events.add(EnemyLeakedEvent(e.kind, e.config.baseDamage));
      } else {
        e.position = track.positionAt(e.distance);
      }
    }
    enemies.removeWhere((e) => !e.alive);
    if (integrity <= 0) {
      _finish(victory: false);
    }
  }

  SimEnemy? _enemyById(int id) {
    for (final e in enemies) {
      if (e.id == id) return e.alive ? e : null;
    }
    return null;
  }

  // ---- Efeitos de suporte / detecção --------------------------------------

  void _applySupportEffects() {
    final supports = <SimTower>[];
    final detectors = <SimTower>[];
    for (final t in towers) {
      if (t.config.isSupport) supports.add(t);
      if (t.stats.revealDuration > 0) detectors.add(t);
    }
    // Bônus: cada torre recebe o MAIOR bônus entre os suportes no alcance.
    for (final t in towers) {
      var best = 0.0;
      if (!t.config.isSupport) {
        for (final s in supports) {
          final r = s.stats.range;
          if (s.position.distance2To(t.position) <= r * r) {
            best = math.max(best, s.stats.buffPercent);
          }
        }
      }
      t.buff = best;
    }
    if (enemies.isEmpty) return;
    // Correção (Microsoft) em Exploits.
    for (final s in supports) {
      final st = s.stats;
      if (st.patchVulnerability <= 0) continue;
      for (final e in enemies) {
        if (e.config.exploitArmor <= 0) continue;
        if (_inRange(s.position, st.range, e)) {
          if (e.patchTimer <= 0) e.patchVulnerability = 1;
          e.patchTimer = 0.6;
          e.patchVulnerability = math.max(e.patchVulnerability, st.patchVulnerability);
        }
      }
    }
    // Revelação (CrowdStrike).
    for (final d in detectors) {
      for (final e in enemies) {
        if (!e.camouflaged) continue;
        if (_inRange(d.position, d.stats.range, e)) {
          e.revealTimer = math.max(e.revealTimer, d.stats.revealDuration);
        }
      }
    }
  }

  bool _inRange(Vec center, double range, SimEnemy e) {
    final r = range + e.config.radius * 0.5;
    return center.distance2To(e.position) <= r * r;
  }

  // ---- Torres --------------------------------------------------------------

  static bool canConfigSee(TowerConfig c, SimEnemy e) =>
      !e.isHidden || c.detectsHidden || c.detectsKinds.contains(e.kind);

  void _updateTowers(double dt) {
    for (final t in towers) {
      if (t.fireFlash > 0) t.fireFlash = math.max(0, t.fireFlash - dt);
      if (t.config.isSupport || t.stats.fireRate <= 0) continue;
      if (t.cooldown > 0) t.cooldown -= dt;
      if (t.cooldown > 0) continue;
      final target = _pickTarget(t);
      if (target == null) continue;
      t.cooldown = 1 / t.effectiveFireRate;
      t.aimAngle = math.atan2(target.position.y - t.position.y, target.position.x - t.position.x);
      t.fireFlash = 0.12;
      t.shotsFired++;
      projectiles.add(SimProjectile(
        id: _nextId++,
        config: t.config,
        stats: t.stats,
        targetId: target.id,
        position: t.position,
        damage: t.effectiveDamage,
      ));
      _events.add(TowerFiredEvent(t.id, t.kind, t.position, target.position));
    }
  }

  /// Alvo prioritário: o inimigo visível mais avançado no caminho.
  SimEnemy? _pickTarget(SimTower t) {
    SimEnemy? best;
    for (final e in enemies) {
      if (!e.alive) continue;
      if (!t.canSee(e)) continue;
      if (!_inRange(t.position, t.stats.range, e)) continue;
      if (best == null || e.distance > best.distance) best = e;
    }
    return best;
  }

  // ---- Projéteis -----------------------------------------------------------

  void _updateProjectiles(double dt) {
    for (final p in projectiles) {
      if (!p.alive) continue;
      final target = _enemyById(p.targetId);
      if (target == null) {
        // Alvo removido: o projétil se dissipa sem causar dano.
        p.alive = false;
        _events.add(ProjectileFizzledEvent(p.position));
        continue;
      }
      final toTarget = target.position - p.position;
      final dist = toTarget.length;
      final travel = p.config.projectileSpeed * dt;
      if (dist <= travel + target.config.radius) {
        p.alive = false;
        _impact(p, target);
      } else {
        p.position = p.position + toTarget.normalized() * travel;
      }
    }
    projectiles.removeWhere((p) => !p.alive);
    enemies.removeWhere((e) => !e.alive);
  }

  void _impact(SimProjectile p, SimEnemy target) {
    final st = p.stats;
    final at = target.position;
    _events.add(ProjectileHitEvent(p.kind, at, st.splashRadius));
    if (st.splashRadius > 0) {
      final victims = <SimEnemy>[];
      for (final e in enemies) {
        if (!e.alive) continue;
        if (!canConfigSee(p.config, e) && e.id != target.id) continue;
        final r = st.splashRadius + e.config.radius;
        if (e.position.distance2To(at) <= r * r) victims.add(e);
      }
      for (final e in victims) {
        _hit(e, p.damage, p.config, st);
      }
    } else {
      _hit(target, p.damage, p.config, st);
    }
  }

  /// Calcula o dano final contra um inimigo (público para testes).
  static double computeDamage(SimEnemy e, double base, TowerConfig c) {
    var dmg = base * (c.bonusVs[e.kind] ?? 1);
    if (e.sqlShield && !c.ignoresSqlShield) dmg *= sqlShieldDamageFactor;
    if (e.config.exploitArmor > 0) {
      dmg *= e.isPatched ? e.patchVulnerability : (1 - e.config.exploitArmor);
    }
    return dmg;
  }

  void _hit(SimEnemy e, double base, TowerConfig c, TowerLevel st) {
    if (!e.alive) return;
    final dmg = computeDamage(e, base, c);
    if (c.stripsSqlShield && e.sqlShield) {
      e.sqlShield = false;
      _events.add(ShieldStrippedEvent(e.position, e.kind));
    }
    if (c.stripsCamouflage && e.camouflaged) {
      e.camouflaged = false;
      _events.add(ShieldStrippedEvent(e.position, e.kind));
    }
    if (st.slowFactor > 0 && !e.config.isBoss) {
      e.slowFactor = math.max(e.slowTimer > 0 ? e.slowFactor : 0, st.slowFactor);
      e.slowTimer = math.max(e.slowTimer, st.slowDuration);
    } else if (st.slowFactor > 0 && e.config.isBoss) {
      // Chefes sofrem apenas metade da lentidão.
      e.slowFactor = math.max(e.slowTimer > 0 ? e.slowFactor : 0, st.slowFactor / 2);
      e.slowTimer = math.max(e.slowTimer, st.slowDuration);
    }
    e.hp -= dmg;
    if (e.hp <= 0) _kill(e);
  }

  void _kill(SimEnemy e) {
    if (!e.alive) return; // garante recompensa única
    e.alive = false;
    e.hp = 0;
    kills++;
    credits += e.config.reward;
    _events.add(EnemyKilledEvent(e.kind, e.position, e.config.reward));
    final boss = bossConfigs[e.kind];
    if (boss != null) {
      bossDefeated = true;
      _releaseFromBoss(e, boss);
    }
  }

  /// Libera os inimigos do chefe a partir da posição dele no caminho.
  void _releaseFromBoss(SimEnemy bossEnemy, BossConfig boss) {
    var index = 0;
    for (final g in boss.spawnOnDeath) {
      for (var i = 0; i < g.count; i++) {
        final d = math.max(0.0, bossEnemy.distance - index * boss.spawnSpacing);
        spawnEnemy(g.kind, distance: d, fromBoss: true);
        index++;
      }
    }
    _events.add(BossSplitEvent(bossEnemy.kind, bossEnemy.position, index));
  }

  /// Aplica dano direto (utilizado em testes e para depuração).
  void debugDamage(SimEnemy e, double amount, TowerKind source) {
    final c = towerConfig(source);
    _hit(e, amount, c, c.level(1));
    enemies.removeWhere((x) => !x.alive);
  }

  // ---- Economia e posicionamento -------------------------------------------

  PlacementStatus checkPlacement(TowerKind kind, Cell cell) {
    if (isOver) return PlacementStatus.gameOver;
    if (!map.isInside(cell)) return PlacementStatus.outOfBounds;
    if (_blocked.contains(cell)) return PlacementStatus.onPath;
    if (towersByCell.containsKey(cell)) return PlacementStatus.occupied;
    if (credits < towerConfig(kind).buildCost) return PlacementStatus.insufficientCredits;
    return PlacementStatus.valid;
  }

  SimTower? buildTower(TowerKind kind, Cell cell) {
    if (!checkPlacement(kind, cell).isValid) return null;
    final cfg = towerConfig(kind);
    credits -= cfg.buildCost;
    final t = SimTower(id: _nextId++, config: cfg, cell: cell, position: map.cellCenter(cell));
    towersByCell[cell] = t;
    towerKindsBuilt.add(kind);
    maxTowerLevel = math.max(maxTowerLevel, 1);
    return t;
  }

  SimTower? towerAt(Cell cell) => towersByCell[cell];

  SimTower? towerById(int id) {
    for (final t in towers) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool canUpgrade(SimTower t) =>
      !isOver && t.canUpgrade && credits >= t.nextLevel!.cost && towersByCell[t.cell] == t;

  bool upgradeTower(SimTower t) {
    if (!canUpgrade(t)) return false;
    final cost = t.nextLevel!.cost;
    credits -= cost;
    t.invested += cost;
    t.level++;
    maxTowerLevel = math.max(maxTowerLevel, t.level);
    return true;
  }

  int sellValue(SimTower t) => (t.invested * rules.sellRefundRate).floor();

  /// Vende a torre e devolve o valor creditado (0 se não foi possível).
  int sellTower(SimTower t) {
    if (isOver) return 0;
    if (towersByCell[t.cell] != t) return 0;
    towersByCell.remove(t.cell);
    final refund = sellValue(t);
    credits += refund;
    return refund;
  }

  // ---- Fim de jogo ---------------------------------------------------------

  void _finish({required bool victory}) {
    if (_outcome != null) return; // finalização única
    phase = victory ? GamePhase.victory : GamePhase.defeat;
    projectiles.clear();
    _outcome = MatchOutcome(
      mapId: map.id,
      victory: victory,
      wavesCompleted: wavesCompleted,
      waveReached: victory ? wavesCompleted : math.min(wavesCompleted + 1, waves.length),
      kills: kills,
      integrity: integrity,
      towerKindsBuilt: towerKindsBuilt.length,
      maxTowerLevel: maxTowerLevel,
      bossDefeated: bossDefeated,
      score: ScoreRules.compute(
        wavesCompleted: wavesCompleted,
        kills: kills,
        integrity: integrity,
        victory: victory,
      ),
      simSeconds: simTime,
    );
    _events.add(GameOverEvent(victory));
  }
}
