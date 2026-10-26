import 'package:flutter_test/flutter_test.dart';
import 'package:php_defense/game/config/wave_config.dart';
import 'package:php_defense/game/sim/game_simulation.dart';

import 'helpers/bot_player.dart';

void main() {
  test('estratégia automática vence as 15 ondas', () {
    final sim = BotPlayer(GameSimulation()).play();
    // ignore: avoid_print
    print('Bot: fase=${sim.phase} ondas=${sim.wavesCompleted} integridade=${sim.integrity} '
        'abates=${sim.kills} torres=${sim.towers.length} créditos=${sim.credits}');
    expect(sim.phase, GamePhase.victory);
    expect(sim.wavesCompleted, totalWaves);
    expect(sim.bossDefeated, isTrue);
  });

  test('sem torres o servidor é derrotado', () {
    final sim = GameSimulation();
    var steps = 0;
    while (!sim.isOver && steps < 60 * 60 * 30) {
      if (sim.canStartWave) sim.startNextWave();
      sim.step(sim.rules.fixedTimeStep);
      steps++;
    }
    expect(sim.phase, GamePhase.defeat);
    expect(sim.integrity, 0);
  });
}
