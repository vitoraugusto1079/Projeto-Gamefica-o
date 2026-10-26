/// Regras gerais da partida. Todos os valores são editáveis aqui.
class GameRules {
  const GameRules({
    this.startingIntegrity = 100,
    this.startingCredits = 400,
    this.sellRefundRate = 0.7,
    this.fixedTimeStep = 1 / 60,
    this.maxStepsPerFrame = 12,
    this.waveBonusBase = 100,
    this.waveBonusPerWave = 15,
  });

  /// Integridade inicial do servidor.
  final int startingIntegrity;

  /// Créditos iniciais.
  final int startingCredits;

  /// Percentual do investimento devolvido na venda (0.7 = 70%).
  final double sellRefundRate;

  /// Passo fixo da simulação, em segundos. A simulação é sempre avançada em
  /// passos deste tamanho, independente da taxa de quadros e da velocidade.
  final double fixedTimeStep;

  /// Limite de passos por quadro (evita "espiral da morte" em quadros lentos).
  final int maxStepsPerFrame;

  /// Bônus por onda concluída: base + onda * porOnda.
  final int waveBonusBase;
  final int waveBonusPerWave;

  int waveBonus(int waveNumber) => waveBonusBase + waveNumber * waveBonusPerWave;

  static const GameRules standard = GameRules();
}
