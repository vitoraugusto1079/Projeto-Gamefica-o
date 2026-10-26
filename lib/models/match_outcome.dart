/// Resultado final de uma partida, produzido uma única vez pela simulação.
class MatchOutcome {
  const MatchOutcome({
    required this.mapId,
    required this.victory,
    required this.wavesCompleted,
    required this.waveReached,
    required this.kills,
    required this.integrity,
    required this.towerKindsBuilt,
    required this.maxTowerLevel,
    required this.bossDefeated,
    required this.score,
    required this.simSeconds,
  });

  final String mapId;
  final bool victory;
  final int wavesCompleted;
  final int waveReached;
  final int kills;
  final int integrity;
  final int towerKindsBuilt;
  final int maxTowerLevel;
  final bool bossDefeated;
  final int score;

  /// Tempo simulado (não depende da velocidade 1x/2x).
  final double simSeconds;
}
