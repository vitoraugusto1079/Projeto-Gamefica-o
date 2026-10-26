import 'package:php_defense/game/config/tower_config.dart';
import 'package:php_defense/game/sim/game_simulation.dart';
import 'package:php_defense/game/sim/vec.dart';

/// Estratégia automática simples usada para verificar se as 15 ondas são
/// vencíveis com as regras e preços atuais.
class BotPlayer {
  BotPlayer(this.sim, {this.plan = defaultPlan});

  final GameSimulation sim;
  final List<TowerKind> plan;
  int _planIndex = 0;

  static const defaultPlan = [
    TowerKind.fortinet,
    TowerKind.fortinet,
    TowerKind.cloudflare,
    TowerKind.owasp,
    TowerKind.fortinet,
    TowerKind.crowdstrike,
    TowerKind.microsoft,
    TowerKind.owasp,
    TowerKind.cloudflare,
    TowerKind.fortinet,
    TowerKind.fortinet,
    TowerKind.microsoft,
    TowerKind.owasp,
    TowerKind.fortinet,
    TowerKind.cloudflare,
    TowerKind.fortinet,
    TowerKind.crowdstrike,
    TowerKind.fortinet,
  ];

  /// Cobertura do caminho (amostras dentro do alcance) para cada célula.
  int coverage(Cell c, double range) {
    final center = sim.map.cellCenter(c);
    var n = 0;
    for (var d = 0.0; d < sim.track.length; d += 16) {
      if (sim.track.positionAt(d).distanceTo(center) <= range) n++;
    }
    return n;
  }

  Cell? bestCell(TowerKind kind) {
    final range = towerConfig(kind).level(1).range;
    Cell? best;
    var bestScore = -1;
    for (var col = 0; col < sim.map.cols; col++) {
      for (var row = 0; row < sim.map.rows; row++) {
        final c = Cell(col, row);
        if (sim.checkPlacement(kind, c) != PlacementStatus.valid) continue;
        var score = coverage(c, range);
        if (kind == TowerKind.microsoft) {
          // Suporte: valoriza torres próximas.
          score = 0;
          for (final t in sim.towers) {
            if (t.position.distanceTo(sim.map.cellCenter(c)) <= range) score += 10;
          }
          score += coverage(c, range) ~/ 4;
        }
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
    }
    return best;
  }

  void spend() {
    var progressed = true;
    while (progressed) {
      progressed = false;
      if (_planIndex < plan.length) {
        final kind = plan[_planIndex];
        if (sim.credits >= towerConfig(kind).buildCost) {
          final c = bestCell(kind);
          if (c != null && sim.buildTower(kind, c) != null) {
            _planIndex++;
            progressed = true;
            continue;
          }
        }
      }
      // Depois de metade do plano, melhora as torres mais baratas.
      if (_planIndex >= 4) {
        final upgradable = sim.towers.where(sim.canUpgrade).toList()
          ..sort((a, b) => a.nextLevel!.cost.compareTo(b.nextLevel!.cost));
        if (upgradable.isNotEmpty && (_planIndex >= plan.length || sim.credits > 450)) {
          sim.upgradeTower(upgradable.first);
          progressed = true;
        }
      }
    }
  }

  /// Joga a partida inteira. Retorna a simulação ao final.
  GameSimulation play({int maxSteps = 60 * 60 * 60}) {
    var steps = 0;
    while (!sim.isOver && steps < maxSteps) {
      if (sim.canStartWave) {
        spend();
        sim.startNextWave();
      }
      sim.step(sim.rules.fixedTimeStep);
      steps++;
      if (steps % 120 == 0) spend();
    }
    return sim;
  }
}
