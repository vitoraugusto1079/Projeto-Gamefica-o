import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../config/enemy_config.dart';
import '../config/tower_config.dart';

/// Desenho vetorial de torres e inimigos, compartilhado entre o Flame e os
/// ícones do HUD (via CustomPainter). Nenhuma imagem externa é usada.
class GlyphPainter {
  static final Map<String, TextPainter> _textCache = {};

  static TextPainter text(String s, double size, Color color, {bool bold = true}) {
    final key = '$s|$size|${color.toARGB32()}|$bold';
    return _textCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'monospace',
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      return tp;
    });
  }

  static void drawCenteredText(Canvas c, String s, Offset center, double size, Color color) {
    final tp = text(s, size, color);
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  static Path polygon(Offset center, double r, int sides, {double rotation = 0}) {
    final p = Path();
    for (var i = 0; i < sides; i++) {
      final a = rotation + i * 2 * math.pi / sides;
      final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  // ---- Torres --------------------------------------------------------------

  /// Desenha o ícone de uma torre centrado em [center] com raio [r].
  static void drawTower(Canvas c, TowerConfig cfg, Offset center, double r,
      {int level = 1, double aim = 0, double flash = 0, double opacity = 1}) {
    final color = Color(cfg.color).withValues(alpha: opacity);
    final dark = const Color(0xFF0A1530).withValues(alpha: 0.95 * opacity);
    final fill = Paint()..color = dark;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Base quadrada (chip) comum a todas.
    final base = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: r * 2, height: r * 2), Radius.circular(r * 0.3));
    c.drawRRect(base, glow);
    c.drawRRect(base, fill);
    c.drawRRect(base, stroke);
    // Pinos do chip.
    final pin = Paint()..color = color.withValues(alpha: 0.6 * opacity);
    for (var i = -1; i <= 1; i++) {
      final o = i * r * 0.5;
      c.drawRect(Rect.fromCenter(center: center + Offset(o, -r - 3), width: 3, height: 6), pin);
      c.drawRect(Rect.fromCenter(center: center + Offset(o, r + 3), width: 3, height: 6), pin);
      c.drawRect(Rect.fromCenter(center: center + Offset(-r - 3, o), width: 6, height: 3), pin);
      c.drawRect(Rect.fromCenter(center: center + Offset(r + 3, o), width: 6, height: 3), pin);
    }

    final inner = Paint()..color = color;
    final innerStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1;

    switch (cfg.kind) {
      case TowerKind.fortinet:
        // Muralha de tijolos + canhão.
        final w = r * 1.1;
        final h = r * 0.8;
        final rect = Rect.fromCenter(center: center, width: w, height: h);
        c.drawRect(rect, innerStroke);
        c.drawLine(rect.centerLeft, rect.centerRight, innerStroke);
        c.drawLine(Offset(rect.center.dx, rect.top), Offset(rect.center.dx, rect.center.dy), innerStroke);
        c.drawLine(Offset(rect.left + w * 0.25, rect.center.dy),
            Offset(rect.left + w * 0.25, rect.bottom), innerStroke);
        c.drawLine(Offset(rect.left + w * 0.75, rect.center.dy),
            Offset(rect.left + w * 0.75, rect.bottom), innerStroke);
        _barrel(c, center, r, aim, color, flash);
      case TowerKind.cloudflare:
        // Nuvem.
        final p = Paint()..color = color;
        c.drawCircle(center + Offset(-r * 0.35, r * 0.08), r * 0.32, p);
        c.drawCircle(center + Offset(r * 0.05, -r * 0.15), r * 0.42, p);
        c.drawCircle(center + Offset(r * 0.42, r * 0.1), r * 0.3, p);
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(center.dx - r * 0.65, center.dy + r * 0.05, r * 1.35, r * 0.35),
                Radius.circular(r * 0.15)),
            p);
        if (flash > 0) {
          c.drawCircle(center, r * 1.1,
              Paint()..color = color.withValues(alpha: (flash * 4).clamp(0, 0.5)));
        }
      case TowerKind.crowdstrike:
        // Olho / radar.
        final eye = Path()
          ..moveTo(center.dx - r * 0.75, center.dy)
          ..quadraticBezierTo(center.dx, center.dy - r * 0.75, center.dx + r * 0.75, center.dy)
          ..quadraticBezierTo(center.dx, center.dy + r * 0.75, center.dx - r * 0.75, center.dy)
          ..close();
        c.drawPath(eye, innerStroke);
        c.drawCircle(center, r * 0.25, inner);
        c.drawCircle(center + Offset(math.cos(aim), math.sin(aim)) * (r * 0.12), r * 0.1,
            Paint()..color = dark);
      case TowerKind.owasp:
        // Chaves { } com escudo.
        final shield = Path()
          ..moveTo(center.dx, center.dy - r * 0.7)
          ..lineTo(center.dx + r * 0.6, center.dy - r * 0.45)
          ..quadraticBezierTo(center.dx + r * 0.55, center.dy + r * 0.45, center.dx, center.dy + r * 0.75)
          ..quadraticBezierTo(center.dx - r * 0.55, center.dy + r * 0.45, center.dx - r * 0.6, center.dy - r * 0.45)
          ..close();
        c.drawPath(shield, innerStroke);
        drawCenteredText(c, '{ }', center + Offset(0, r * 0.02), r * 0.5, color);
      case TowerKind.microsoft:
        // Quatro quadrados (janela de atualização) com seta circular.
        final s = r * 0.32;
        const g = 3.0;
        c.drawRect(Rect.fromLTWH(center.dx - s - g / 2, center.dy - s - g / 2, s, s), inner);
        c.drawRect(Rect.fromLTWH(center.dx + g / 2, center.dy - s - g / 2, s, s), inner);
        c.drawRect(Rect.fromLTWH(center.dx - s - g / 2, center.dy + g / 2, s, s), inner);
        c.drawRect(Rect.fromLTWH(center.dx + g / 2, center.dy + g / 2, s, s), inner);
        c.drawArc(Rect.fromCircle(center: center, radius: r * 0.78), -math.pi * 0.4, math.pi * 1.5,
            false, innerStroke);
    }

    // Indicadores de nível (pontos).
    for (var i = 0; i < level; i++) {
      final x = center.dx - r * 0.5 + i * r * 0.5;
      final y = center.dy + r * 0.82;
      c.drawCircle(Offset(x, y), r * 0.11, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity));
      c.drawCircle(Offset(x, y), r * 0.11,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  static void _barrel(Canvas c, Offset center, double r, double aim, Color color, double flash) {
    final dir = Offset(math.cos(aim), math.sin(aim));
    final p = Paint()
      ..color = color
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    c.drawLine(center, center + dir * (r * 0.95), p);
    if (flash > 0) {
      c.drawCircle(center + dir * (r * 1.05), r * 0.25,
          Paint()..color = const Color(0xFFFFF59D).withValues(alpha: (flash * 6).clamp(0, 1)));
    }
  }

  // ---- Inimigos ------------------------------------------------------------

  static void drawEnemy(Canvas c, EnemyConfig cfg, Offset center,
      {double scale = 1,
      bool shielded = false,
      bool hidden = false,
      bool revealed = false,
      bool patched = false,
      bool slowed = false,
      double time = 0}) {
    final r = cfg.radius * scale;
    final color = Color(cfg.color);
    final alpha = hidden ? 0.35 : 1.0;
    final fill = Paint()..color = color.withValues(alpha: 0.85 * alpha);
    final edge = Paint()
      ..color = const Color(0xFF02060F).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Path shape;
    switch (cfg.shape) {
      case EnemyShape.circle:
        shape = Path()..addOval(Rect.fromCircle(center: center, radius: r));
      case EnemyShape.hexagon:
        shape = polygon(center, r, 6, rotation: math.pi / 6);
      case EnemyShape.diamond:
        shape = polygon(center, r * 1.15, 4, rotation: -math.pi / 2);
      case EnemyShape.triangle:
        shape = polygon(center, r * 1.15, 3, rotation: -math.pi / 2);
      case EnemyShape.square:
        shape = Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: r * 1.8, height: r * 1.8), Radius.circular(r * 0.25)));
      case EnemyShape.boss:
        shape = polygon(center, r, 8, rotation: time * 0.6);
    }

    if (cfg.isBoss) {
      c.drawCircle(center, r * 1.4,
          Paint()
            ..color = color.withValues(alpha: 0.25 + 0.1 * math.sin(time * 4))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      // Cabeças da hidra.
      for (var i = 0; i < 3; i++) {
        final a = -math.pi / 2 + (i - 1) * 0.7 + math.sin(time * 2 + i) * 0.1;
        final head = center + Offset(math.cos(a), math.sin(a)) * (r * 1.15);
        c.drawLine(center, head, Paint()
          ..color = color
          ..strokeWidth = 5);
        c.drawCircle(head, r * 0.28, Paint()..color = color);
        c.drawCircle(head, r * 0.08, Paint()..color = const Color(0xFFFF1744));
      }
    }

    if (slowed) {
      c.drawPath(shape, Paint()
        ..color = const Color(0xFF80D8FF).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    c.drawPath(shape, fill);
    if (hidden || revealed) {
      // Contorno tracejado indica ameaça oculta.
      _dashedCircle(c, center, r * 1.35, revealed ? const Color(0xFFFF5252) : color.withValues(alpha: 0.6),
          time);
    }
    c.drawPath(shape, edge);

    final symbolSize = cfg.symbol.length <= 1
        ? r * 1.1
        : cfg.symbol.length == 2
            ? r * 0.8
            : r * 0.55;
    drawCenteredText(c, cfg.symbol, center, symbolSize, const Color(0xFF02060F).withValues(alpha: alpha));

    if (shielded) {
      // Blindagem hexagonal de SQL Injection.
      c.drawPath(
          polygon(center, r * 1.45, 6, rotation: math.pi / 6),
          Paint()
            ..color = const Color(0xFFFFE082)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    if (patched) {
      // Selo de "corrigido": exploit vulnerável.
      final pc = center + Offset(r * 0.9, -r * 0.9);
      c.drawCircle(pc, 7, Paint()..color = const Color(0xFF29B6F6));
      drawCenteredText(c, '!', pc, 10, const Color(0xFF02060F));
    } else if (cfg.exploitArmor > 0) {
      // Armadura pesada (placas nos cantos).
      final ap = Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final rr = Rect.fromCenter(center: center, width: r * 2.2, height: r * 2.2);
      c.drawRect(rr, ap);
    }
  }

  static void _dashedCircle(Canvas c, Offset center, double r, Color color, double time) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const n = 10;
    for (var i = 0; i < n; i++) {
      final start = time * 1.5 + i * 2 * math.pi / n;
      c.drawArc(Rect.fromCircle(center: center, radius: r), start, math.pi / n, false, p);
    }
  }
}
