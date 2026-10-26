import 'enemy_config.dart';

/// Grupo de inimigos de uma onda.
class SpawnGroup {
  const SpawnGroup(
    this.kind,
    this.count, {
    this.interval = 0.8,
    this.delay = 0,
    this.hpMultiplier = 1,
  });

  final EnemyKind kind;
  final int count;

  /// Intervalo entre surgimentos (s).
  final double interval;

  /// Atraso a partir do início da onda (s).
  final double delay;

  /// Multiplicador de vida para dificuldade progressiva.
  final double hpMultiplier;
}

class WaveConfig {
  const WaveConfig(this.groups, {this.note});

  final List<SpawnGroup> groups;

  /// Texto opcional exibido antes da onda.
  final String? note;

  int get totalSpawns => groups.fold(0, (s, g) => s + g.count);
  Set<EnemyKind> get kinds => groups.map((g) => g.kind).toSet();
}

/// Quinze ondas com introdução gradual das ameaças:
/// 1-2 Força Bruta · 3 DDoS · 4 SQL Injection · 6 XSS · 8 Exploit · 15 HYDRA AI.
const List<WaveConfig> waveConfigs = [
  // 1
  WaveConfig([SpawnGroup(EnemyKind.bruteForce, 12, interval: 1.0)],
      note: 'Tentativas de força bruta. Construa um Firewall perto do caminho.'),
  // 2
  WaveConfig([SpawnGroup(EnemyKind.bruteForce, 20, interval: 0.75)]),
  // 3
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 12, interval: 0.8),
    SpawnGroup(EnemyKind.ddos, 14, interval: 0.3, delay: 6),
  ]),
  // 4
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 14, interval: 0.7),
    SpawnGroup(EnemyKind.sqlInjection, 5, interval: 1.8, delay: 4),
  ]),
  // 5
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 18, interval: 0.6, hpMultiplier: 1.2),
    SpawnGroup(EnemyKind.ddos, 22, interval: 0.25, delay: 5),
    SpawnGroup(EnemyKind.sqlInjection, 6, interval: 1.5, delay: 9),
  ]),
  // 6
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 16, interval: 0.6, hpMultiplier: 1.3),
    SpawnGroup(EnemyKind.xss, 6, interval: 1.6, delay: 4),
  ]),
  // 7
  WaveConfig([
    SpawnGroup(EnemyKind.ddos, 32, interval: 0.2),
    SpawnGroup(EnemyKind.sqlInjection, 8, interval: 1.2, delay: 4),
    SpawnGroup(EnemyKind.xss, 6, interval: 1.4, delay: 8),
  ]),
  // 8
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 20, interval: 0.5, hpMultiplier: 1.4),
    SpawnGroup(EnemyKind.exploit, 3, interval: 4, delay: 5),
  ]),
  // 9
  WaveConfig([
    SpawnGroup(EnemyKind.sqlInjection, 10, interval: 1, hpMultiplier: 1.2),
    SpawnGroup(EnemyKind.xss, 10, interval: 1, delay: 3, hpMultiplier: 1.2),
    SpawnGroup(EnemyKind.ddos, 30, interval: 0.2, delay: 8),
  ]),
  // 10
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 30, interval: 0.4, hpMultiplier: 1.6),
    SpawnGroup(EnemyKind.exploit, 5, interval: 3, delay: 4, hpMultiplier: 1.1),
    SpawnGroup(EnemyKind.ddos, 30, interval: 0.18, delay: 10),
  ]),
  // 11
  WaveConfig([
    SpawnGroup(EnemyKind.xss, 14, interval: 0.8, hpMultiplier: 1.4),
    SpawnGroup(EnemyKind.sqlInjection, 14, interval: 0.8, delay: 2, hpMultiplier: 1.4),
    SpawnGroup(EnemyKind.exploit, 4, interval: 3, delay: 8, hpMultiplier: 1.2),
  ]),
  // 12
  WaveConfig([
    SpawnGroup(EnemyKind.ddos, 60, interval: 0.12, hpMultiplier: 1.5),
    SpawnGroup(EnemyKind.bruteForce, 30, interval: 0.35, delay: 4, hpMultiplier: 1.8),
    SpawnGroup(EnemyKind.exploit, 6, interval: 2.5, delay: 8, hpMultiplier: 1.3),
  ]),
  // 13
  WaveConfig([
    SpawnGroup(EnemyKind.sqlInjection, 18, interval: 0.7, hpMultiplier: 1.6),
    SpawnGroup(EnemyKind.xss, 18, interval: 0.7, delay: 1, hpMultiplier: 1.6),
    SpawnGroup(EnemyKind.ddos, 40, interval: 0.15, delay: 6, hpMultiplier: 1.6),
    SpawnGroup(EnemyKind.exploit, 6, interval: 2.5, delay: 10, hpMultiplier: 1.4),
  ]),
  // 14
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 40, interval: 0.3, hpMultiplier: 2.2),
    SpawnGroup(EnemyKind.exploit, 10, interval: 2, delay: 3, hpMultiplier: 1.5),
    SpawnGroup(EnemyKind.xss, 16, interval: 0.6, delay: 8, hpMultiplier: 1.8),
    SpawnGroup(EnemyKind.sqlInjection, 16, interval: 0.6, delay: 12, hpMultiplier: 1.8),
  ]),
  // 15
  WaveConfig([
    SpawnGroup(EnemyKind.bruteForce, 20, interval: 0.4, hpMultiplier: 2.2),
    SpawnGroup(EnemyKind.hydra, 1, delay: 6),
    SpawnGroup(EnemyKind.ddos, 30, interval: 0.2, delay: 10, hpMultiplier: 1.6),
  ], note: 'Ameaça máxima detectada. Proteja o servidor a qualquer custo.'),
];

int get totalWaves => waveConfigs.length;

/// Escala global de vida por onda (dificuldade progressiva), aplicada em
/// conjunto com [SpawnGroup.hpMultiplier].
const double waveHpScalePerWave = 0.04;

double waveHpScale(int waveNumber) => 1 + waveHpScalePerWave * (waveNumber - 1);

/// Onda (1-based) em que cada tipo aparece pela primeira vez.
Map<EnemyKind, int> firstAppearance() {
  final map = <EnemyKind, int>{};
  for (var i = 0; i < waveConfigs.length; i++) {
    for (final k in waveConfigs[i].kinds) {
      map.putIfAbsent(k, () => i + 1);
    }
  }
  return map;
}
