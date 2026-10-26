import 'package:flutter_test/flutter_test.dart';
import 'package:php_defense/game/config/enemy_config.dart';
import 'package:php_defense/game/config/tower_config.dart';
import 'package:php_defense/game/sim/entities.dart';
import 'package:php_defense/game/sim/game_simulation.dart';
import 'package:php_defense/game/sim/score_rules.dart';
import 'package:php_defense/game/sim/sim_events.dart';
import 'package:php_defense/game/sim/vec.dart';

void main() {
  group('Economia e Posicionamento', () {
    test('inicia com 400 créditos e 100 de integridade', () {
      final sim = GameSimulation();
      expect(sim.credits, 400);
      expect(sim.integrity, 100);
      expect(sim.phase, GamePhase.betweenWaves);
    });

    test('rejeita posicionamento fora dos limites, no caminho ou sobre outra torre', () {
      final sim = GameSimulation();
      // Fora do mapa
      expect(
        sim.checkPlacement(TowerKind.fortinet, const Cell(-2, 0)),
        PlacementStatus.outOfBounds,
      );
      // No caminho
      final pathCell = sim.map.waypoints[1]; // Cell(3, 1)
      expect(
        sim.checkPlacement(TowerKind.fortinet, pathCell),
        PlacementStatus.onPath,
      );
      // No servidor PHP
      expect(
        sim.checkPlacement(TowerKind.fortinet, const Cell(18, 4)),
        PlacementStatus.onPath,
      );

      // Célula válida
      const validCell = Cell(1, 4);
      expect(sim.checkPlacement(TowerKind.fortinet, validCell), PlacementStatus.valid);
      final tower = sim.buildTower(TowerKind.fortinet, validCell);
      expect(tower, isNotNull);
      expect(sim.credits, 400 - towerConfig(TowerKind.fortinet).buildCost);

      // Não permite construir na mesma célula
      expect(
        sim.checkPlacement(TowerKind.fortinet, validCell),
        PlacementStatus.occupied,
      );
    });

    test('venda devolve 70% do investimento total e libera a célula', () {
      final sim = GameSimulation();
      const cell = Cell(2, 4);
      final t = sim.buildTower(TowerKind.fortinet, cell)!;
      final costInitial = t.invested;

      // Melhora para nível 2
      final nextCost = t.nextLevel!.cost;
      expect(sim.upgradeTower(t), isTrue);
      expect(t.level, 2);
      expect(t.invested, costInitial + nextCost);

      final creditsBeforeSell = sim.credits;
      final expectedRefund = (t.invested * 0.7).floor();
      final refund = sim.sellTower(t);

      expect(refund, expectedRefund);
      expect(sim.credits, creditsBeforeSell + expectedRefund);
      expect(sim.towerAt(cell), isNull);

      // Célula liberada para nova construção
      expect(sim.checkPlacement(TowerKind.cloudflare, cell), PlacementStatus.valid);
    });

    test('impede créditos negativos ao tentar comprar além do saldo', () {
      final sim = GameSimulation();
      sim.credits = 50; // insuficiente para qualquer torre
      expect(
        sim.checkPlacement(TowerKind.fortinet, const Cell(1, 4)),
        PlacementStatus.insufficientCredits,
      );
      final t = sim.buildTower(TowerKind.fortinet, const Cell(1, 4));
      expect(t, isNull);
      expect(sim.credits, 50);
    });
  });

  group('Mecânicas Especializadas de Defesa e Inimigos', () {
    test('SQL Injection tem blindagem reduzindo dano comum, removida pela OWASP', () {
      final enemy1 = SimEnemy(
        id: 1,
        config: enemyConfig(EnemyKind.sqlInjection),
        maxHp: 20,
        distance: 10,
        position: const Vec(50, 50),
      );

      // Fortinet (dano comum) contra SQL Shield
      final dmgFortinet = GameSimulation.computeDamage(
        enemy1,
        10,
        towerConfig(TowerKind.fortinet),
      );
      expect(dmgFortinet, lessThan(3.0)); // 10 * 0.15 = 1.5

      // OWASP ignora a blindagem e tem bônus de x2
      final dmgOwasp = GameSimulation.computeDamage(
        enemy1,
        10,
        towerConfig(TowerKind.owasp),
      );
      expect(dmgOwasp, 20.0); // 10 * 2 = 20.0
    });

    test('XSS surge camuflado e é revelado pela CrowdStrike', () {
      final sim = GameSimulation();
      sim.credits = 1000;
      final xss = sim.spawnEnemy(EnemyKind.xss, distance: 30);
      expect(xss.isHidden, isTrue);

      // Fortinet não enxerga XSS enquanto oculto
      const fortinetCell = Cell(0, 0);
      final fortinet = sim.buildTower(TowerKind.fortinet, fortinetCell)!;
      expect(fortinet.canSee(xss), isFalse);

      // CrowdStrike enxerga e tem revelação (célula fora do caminho)
      const csCell = Cell(1, 4);
      final cs = sim.buildTower(TowerKind.crowdstrike, csCell)!;
      expect(cs.canSee(xss), isTrue);

      // Aplica efeito de revelação (CrowdStrike alcance cobre a posição)
      xss.position = cs.position;
      sim.step(0.1);
      expect(xss.isRevealed, isTrue);
      expect(xss.isHidden, isFalse);
      // Agora Fortinet consegue vê-lo
      expect(fortinet.canSee(xss), isTrue);
    });

    test('Microsoft vulnerabiliza Exploits e não acumula bônus indefinidamente', () {
      final sim = GameSimulation();
      sim.credits = 1000;
      const msCell1 = Cell(0, 3);
      const msCell2 = Cell(0, 4);
      final ms1 = sim.buildTower(TowerKind.microsoft, msCell1)!;
      final ms2 = sim.buildTower(TowerKind.microsoft, msCell2)!;
      expect(ms2, isNotNull);

      const fCell = Cell(0, 5);
      final fortinet = sim.buildTower(TowerKind.fortinet, fCell)!;

      // Avança um passo para aplicar efeitos de suporte
      sim.step(0.1);

      // O bônus concedido à Fortinet deve ser o maior, NÃO a soma (não acumula)
      expect(fortinet.buff, ms1.stats.buffPercent);

      // Exploit sob efeito da Microsoft fica patched e vulnerável
      final exploit = sim.spawnEnemy(EnemyKind.exploit, distance: 0);
      exploit.position = ms1.position;
      sim.step(0.1);
      expect(exploit.isPatched, isTrue);
      expect(exploit.patchVulnerability, greaterThanOrEqualTo(1.25));
    });
  });

  group('Chefe HYDRA AI e Divisão em Inimigos Menores', () {
    test('ao ser destruído, o chefe libera grupo configurável de inimigos na mesma posição', () {
      final sim = GameSimulation();
      final hydra = sim.spawnEnemy(EnemyKind.hydra, distance: 150);
      final initialEnemies = sim.enemies.length;
      expect(initialEnemies, 1);

      // Destrói a Hydra AI
      sim.debugDamage(hydra, hydra.hp + 10, TowerKind.fortinet);

      expect(sim.bossDefeated, isTrue);
      // Chefe foi removido e inimigos menores liberados
      expect(sim.enemies.length, greaterThan(1));
      expect(sim.enemies.any((e) => e.fromBoss), isTrue);

      // Verifica evento de split
      final events = sim.drainEvents();
      expect(events.any((e) => e is BossSplitEvent), isTrue);
    });
  });

  group('Finalização Única e Cálculo de Pontuação', () {
    test('cálculo estrito de pontuação de acordo com as regras', () {
      final scoreVictory = ScoreRules.compute(
        wavesCompleted: 15,
        kills: 120,
        integrity: 80,
        victory: true,
      );
      // 15*1000 + 120*10 + 80*25 + 5000 = 15000 + 1200 + 2000 + 5000 = 23200
      expect(scoreVictory, 23200);

      final scoreDefeat = ScoreRules.compute(
        wavesCompleted: 8,
        kills: 60,
        integrity: 0,
        victory: false,
      );
      // 8*1000 + 60*10 + 0 + 0 = 8000 + 600 = 8600
      expect(scoreDefeat, 8600);
    });

    test('projétil teleguiado se dissipa se o alvo morrer antes do impacto', () {
      final sim = GameSimulation();
      final enemy = sim.spawnEnemy(EnemyKind.bruteForce, distance: 20);
      const towerCell = Cell(0, 0);
      final t = sim.buildTower(TowerKind.fortinet, towerCell)!;
      expect(t, isNotNull);

      // Executa passos até o projétil ser disparado
      while (sim.projectiles.isEmpty) {
        sim.step(0.1);
      }
      expect(sim.projectiles.isNotEmpty, isTrue);

      // Elimina o alvo manualmente
      enemy.alive = false;
      sim.step(0.1);

      // Projétil detectou alvo nulo e gerou evento ProjectileFizzledEvent
      final events = sim.drainEvents();
      expect(events.any((e) => e is ProjectileFizzledEvent), isTrue);
    });
  });
}
