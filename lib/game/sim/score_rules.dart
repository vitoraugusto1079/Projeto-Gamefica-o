/// Fórmula de pontuação (deve ser idêntica à função `finish_match` no
/// Supabase — ver supabase/migrations).
///
///   pontos = ondas_concluídas × 1000
///          + ameaças_eliminadas × 10
///          + integridade_restante × 25
///          + 5000 se vitória
///
/// Não depende do tempo real nem da velocidade (1x/2x), apenas do resultado.
class ScoreRules {
  static const int perWave = 1000;
  static const int perKill = 10;
  static const int perIntegrity = 25;
  static const int victoryBonus = 5000;

  static int compute({
    required int wavesCompleted,
    required int kills,
    required int integrity,
    required bool victory,
  }) {
    final w = wavesCompleted < 0 ? 0 : wavesCompleted;
    final k = kills < 0 ? 0 : kills;
    final i = integrity.clamp(0, 100);
    return w * perWave + k * perKill + i * perIntegrity + (victory ? victoryBonus : 0);
  }
}
