import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../config/enemy_config.dart';
import '../config/map_config.dart';
import '../config/tower_config.dart';
import '../sim/game_simulation.dart';
import '../sim/sim_events.dart';
import '../sim/vec.dart';
import 'glyph_painter.dart';

class VisualParticle {
  VisualParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.life,
  }) : maxLife = life;

  Vec position;
  final Vec velocity;
  final Color color;
  final double radius;
  double life;
  final double maxLife;

  bool update(double dt) {
    position = position + velocity * dt;
    life -= dt;
    return life > 0;
  }
}

class VisualRing {
  VisualRing({
    required this.position,
    required this.color,
    required this.maxRadius,
    required this.duration,
  });

  final Vec position;
  final Color color;
  final double maxRadius;
  final double duration;
  double elapsed = 0;

  bool update(double dt) {
    elapsed += dt;
    return elapsed < duration;
  }

  double get fraction => (elapsed / duration).clamp(0.0, 1.0);
}

/// Componente que renderiza as entidades da simulação:
/// - Torres (com miras, canhões, animações de disparo e níveis)
/// - Inimigos (com formatos distintos, barras de vida, blindagens e estados)
/// - Projéteis (com cauda de energia)
/// - Efeitos visuais (anéis de impacto de área, estilhaços de dados, partículas)
class EntityRendererComponent extends PositionComponent {
  EntityRendererComponent({
    required this.map,
    required this.getSimulation,
  }) : super(size: Vector2(map.width, map.height));

  final MapConfig map;
  final GameSimulation Function() getSimulation;

  final List<VisualParticle> _particles = [];
  final List<VisualRing> _rings = [];
  double _time = 0;

  void handleEvents(List<SimEvent> events) {
    for (final e in events) {
      switch (e) {
        case ProjectileHitEvent(:final kind, :final at, :final splashRadius):
          final color = Color(towerConfig(kind).color);
          if (splashRadius > 0) {
            _rings.add(VisualRing(
              position: at,
              color: color,
              maxRadius: splashRadius,
              duration: 0.35,
            ));
          }
          _spawnSparks(at, color, count: splashRadius > 0 ? 12 : 5);
        case EnemyKilledEvent(:final kind, :final at):
          final color = Color(enemyConfig(kind).color);
          _rings.add(VisualRing(
            position: at,
            color: color,
            maxRadius: enemyConfig(kind).radius * 2,
            duration: 0.25,
          ));
          _spawnSparks(at, color, count: 14);
        case ShieldStrippedEvent(:final at):
          _rings.add(VisualRing(
            position: at,
            color: const Color(0xFFFFD54F),
            maxRadius: 28,
            duration: 0.3,
          ));
          _spawnSparks(at, const Color(0xFFFFD54F), count: 8);
        case BossSplitEvent(:final at):
          _rings.add(VisualRing(
            position: at,
            color: const Color(0xFFB04DFF),
            maxRadius: 65,
            duration: 0.6,
          ));
          _spawnSparks(at, const Color(0xFFB04DFF), count: 24);
        default:
          break;
      }
    }
  }

  void _spawnSparks(Vec at, Color color, {int count = 6}) {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 40 + rng.nextDouble() * 120;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;
      _particles.add(VisualParticle(
        position: at,
        velocity: Vec(vx, vy),
        color: color,
        radius: 1.5 + rng.nextDouble() * 2.5,
        life: 0.2 + rng.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    _particles.removeWhere((p) => !p.update(dt));
    _rings.removeWhere((r) => !r.update(dt));
  }

  @override
  void render(Canvas canvas) {
    final sim = getSimulation();

    _drawTowers(canvas, sim);
    _drawEnemies(canvas, sim);
    _drawProjectiles(canvas, sim);
    _drawRings(canvas);
    _drawParticles(canvas);
  }

  void _drawTowers(Canvas canvas, GameSimulation sim) {
    final r = map.cellSize * 0.38;
    for (final t in sim.towers) {
      GlyphPainter.drawTower(
        canvas,
        t.config,
        Offset(t.position.x, t.position.y),
        r,
        level: t.level,
        aim: t.aimAngle,
        flash: t.fireFlash,
      );

      // Efeito de suporte buffando a torre
      if (t.buff > 0) {
        final center = Offset(t.position.x, t.position.y);
        canvas.drawCircle(
          center,
          r * 1.15,
          Paint()
            ..color = const Color(0xFF29B6F6).withValues(alpha: 0.35 + 0.15 * math.sin(_time * 4))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _drawEnemies(Canvas canvas, GameSimulation sim) {
    for (final e in sim.enemies) {
      if (!e.alive) continue;
      final center = Offset(e.position.x, e.position.y);

      GlyphPainter.drawEnemy(
        canvas,
        e.config,
        center,
        shielded: e.sqlShield,
        hidden: e.camouflaged,
        revealed: e.isRevealed,
        patched: e.isPatched,
        slowed: e.slowTimer > 0,
        time: _time,
      );

      // Barra de vida (exceto para chefes que possuem barra destacada no HUD)
      if (!e.config.isBoss && e.hp < e.maxHp) {
        final barW = e.config.radius * 2.2;
        const barH = 3.5;
        final barY = center.dy - e.config.radius - 8;
        final barX = center.dx - barW / 2;

        // Fundo da barra
        canvas.drawRect(
          Rect.fromLTWH(barX, barY, barW, barH),
          Paint()..color = const Color(0xFF0A1526),
        );

        // Vida restante
        final hpColor = e.hpFraction > 0.5
            ? const Color(0xFF3DFFA2)
            : (e.hpFraction > 0.25 ? const Color(0xFFFFC23D) : const Color(0xFFFF3D5A));

        canvas.drawRect(
          Rect.fromLTWH(barX, barY, barW * e.hpFraction, barH),
          Paint()..color = hpColor,
        );

        // Borda da barra
        canvas.drawRect(
          Rect.fromLTWH(barX, barY, barW, barH),
          Paint()
            ..color = const Color(0xFF1E3A6E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawProjectiles(Canvas canvas, GameSimulation sim) {
    for (final p in sim.projectiles) {
      if (!p.alive) continue;
      final center = Offset(p.position.x, p.position.y);
      final color = Color(p.config.color);

      // Projétil com núcleo brilhante e cauda
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, 4.5, glowPaint);

      final corePaint = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawCircle(center, 2.5, corePaint);

      final ringPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, 4.5, ringPaint);
    }
  }

  void _drawRings(Canvas canvas) {
    for (final r in _rings) {
      final curR = r.maxRadius * r.fraction;
      final alpha = (1.0 - r.fraction).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(r.position.x, r.position.y),
        curR,
        Paint()
          ..color = r.color.withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in _particles) {
      final frac = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: frac)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.position.x, p.position.y), p.radius * frac, paint);
    }
  }
}
