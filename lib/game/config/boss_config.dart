import 'enemy_config.dart';

/// Grupo de inimigos liberados por um chefe ao ser destruído.
class BossSpawn {
  const BossSpawn(this.kind, this.count);
  final EnemyKind kind;
  final int count;
}

/// Configuração de comportamento dos chefes (nome e aparência ficam em
/// [EnemyConfig]; aqui ficam aviso e inimigos liberados).
class BossConfig {
  const BossConfig({
    required this.kind,
    required this.warningTitle,
    required this.warningText,
    required this.spawnOnDeath,
    this.spawnSpacing = 14,
  });

  final EnemyKind kind;
  final String warningTitle;
  final String warningText;
  final List<BossSpawn> spawnOnDeath;

  /// Distância (no caminho) entre os inimigos liberados.
  final double spawnSpacing;

  int get totalSpawnCount => spawnOnDeath.fold(0, (s, g) => s + g.count);
}

const Map<EnemyKind, BossConfig> bossConfigs = {
  EnemyKind.hydra: BossConfig(
    kind: EnemyKind.hydra,
    warningTitle: 'ALERTA: HYDRA AI DETECTADA',
    warningText:
        'Uma IA invasora está a caminho. Ao ser destruída, ela se fragmenta '
        'em várias ameaças menores.',
    spawnOnDeath: [
      BossSpawn(EnemyKind.bruteForce, 6),
      BossSpawn(EnemyKind.sqlInjection, 3),
      BossSpawn(EnemyKind.xss, 3),
      BossSpawn(EnemyKind.ddos, 8),
    ],
  ),
};
