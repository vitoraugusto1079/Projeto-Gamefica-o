import '../config/enemy_config.dart';
import '../config/tower_config.dart';
import 'vec.dart';

/// Inimigo na simulação.
class SimEnemy {
  SimEnemy({
    required this.id,
    required this.config,
    required this.maxHp,
    required this.distance,
    required this.position,
    this.fromBoss = false,
  })  : hp = maxHp,
        sqlShield = config.sqlShield,
        camouflaged = config.hidden;

  final int id;
  final EnemyConfig config;
  final double maxHp;
  final bool fromBoss;
  double hp;
  double distance;
  Vec position;

  /// Proteção de SQL Injection ainda ativa.
  bool sqlShield;

  /// Camuflagem de XSS ainda ativa.
  bool camouflaged;

  /// Tempo restante de revelação (CrowdStrike).
  double revealTimer = 0;

  double slowTimer = 0;
  double slowFactor = 0;

  /// Tempo restante sob efeito de correção (Microsoft).
  double patchTimer = 0;
  double patchVulnerability = 1;

  bool alive = true;

  EnemyKind get kind => config.kind;
  bool get isRevealed => revealTimer > 0;

  /// Oculto para torres sem detecção.
  bool get isHidden => camouflaged && !isRevealed;
  bool get isPatched => patchTimer > 0;
  double get hpFraction => maxHp <= 0 ? 0 : (hp / maxHp).clamp(0, 1);
  double get currentSpeed => config.speed * (slowTimer > 0 ? (1 - slowFactor) : 1);
}

/// Torre instalada.
class SimTower {
  SimTower({
    required this.id,
    required this.config,
    required this.cell,
    required this.position,
  }) : invested = config.buildCost;

  final int id;
  final TowerConfig config;
  final Cell cell;
  final Vec position;
  int level = 1;

  /// Total gasto (construção + melhorias).
  int invested;
  double cooldown = 0;

  /// Bônus atual concedido por torres de suporte (não acumula: usa o maior).
  double buff = 0;

  /// Ângulo de mira (apenas visual).
  double aimAngle = 0;
  double fireFlash = 0;
  int shotsFired = 0;

  TowerKind get kind => config.kind;
  TowerLevel get stats => config.level(level);
  bool get canUpgrade => level < config.maxLevel;
  TowerLevel? get nextLevel => canUpgrade ? config.level(level + 1) : null;
  double get effectiveDamage => stats.damage * (1 + buff);
  double get effectiveFireRate => stats.fireRate * (1 + buff);

  /// Pode mirar no inimigo considerando ocultação.
  bool canSee(SimEnemy e) =>
      !e.isHidden || config.detectsHidden || config.detectsKinds.contains(e.kind);
}

/// Projétil teleguiado.
class SimProjectile {
  SimProjectile({
    required this.id,
    required this.config,
    required this.stats,
    required this.targetId,
    required this.position,
    required this.damage,
  });

  final int id;

  /// Configuração e nível da torre no momento do disparo (a torre pode ser
  /// vendida ou melhorada durante o voo).
  final TowerConfig config;
  final TowerLevel stats;
  final int targetId;
  Vec position;
  final double damage;
  bool alive = true;

  TowerKind get kind => config.kind;
}
