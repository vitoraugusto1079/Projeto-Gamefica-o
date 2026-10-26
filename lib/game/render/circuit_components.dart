import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../config/map_config.dart';
import '../config/tower_config.dart';
import '../sim/entities.dart';
import '../sim/game_simulation.dart';
import '../sim/vec.dart';
import 'glyph_painter.dart';

/// Renderiza o cenário da placa de circuito: grade, trilhas de cobre que
/// conduzem energia, nós de solda, o caminho dos pacotes e o servidor PHP.
class CircuitMapComponent extends PositionComponent {
  CircuitMapComponent({required this.map})
      : super(size: Vector2(map.width, map.height));

  final MapConfig map;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    _drawBoard(canvas);
    _drawTraces(canvas);
    _drawPath(canvas);
    _drawServer(canvas);
  }

  void _drawBoard(Canvas canvas) {
    final bgPaint = Paint()..color = const Color(0xFF060E1D);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF0F223D)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var c = 0; c <= map.cols; c++) {
      final x = c * map.cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (var r = 0; r <= map.rows; r++) {
      final y = r * map.cellSize;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
  }

  void _drawTraces(Canvas canvas) {
    final tracePaint = Paint()
      ..color = const Color(0xFF0A334A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.35);

    for (var c = 1; c < map.cols; c += 2) {
      for (var r = 1; r < map.rows; r += 2) {
        final cell = Cell(c, r);
        if (map.blockedCells.contains(cell)) continue;
        final p = map.cellCenter(cell);
        canvas.drawCircle(Offset(p.x, p.y), 3, dotPaint);

        if (c + 1 < map.cols && !map.blockedCells.contains(Cell(c + 1, r))) {
          canvas.drawLine(Offset(p.x + 8, p.y), Offset(p.x + map.cellSize - 8, p.y), tracePaint);
        }
      }
    }
  }

  void _drawPath(Canvas canvas) {
    final pts = map.pathPoints;
    if (pts.length < 2) return;

    final pathObj = Path();
    pathObj.moveTo(pts.first.x, pts.first.y);
    for (var i = 1; i < pts.length; i++) {
      pathObj.lineTo(pts[i].x, pts[i].y);
    }

    // Camada externa (brilho da trilha)
    final outerGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = map.cellSize * 0.72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathObj, outerGlow);

    // Faixa da trilha de dados
    final busPaint = Paint()
      ..color = const Color(0xFF0D253F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = map.cellSize * 0.52
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathObj, busPaint);

    // Trilha interna de cobre
    final copperPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathObj, copperPaint);

    // Pulsos de fluxo de dados percorrendo a trilha
    final pulsePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final t = ((_time * 0.15 + i / 8) % 1.0);
      final dist = t * (pts.length - 1);
      final idx = dist.floor().clamp(0, pts.length - 2);
      final frac = dist - idx;
      final p1 = pts[idx];
      final p2 = pts[idx + 1];
      final px = p1.x + (p2.x - p1.x) * frac;
      final py = p1.y + (p2.y - p1.y) * frac;
      canvas.drawCircle(Offset(px, py), 3.5, pulsePaint);
    }
  }

  void _drawServer(Canvas canvas) {
    if (map.serverCells.isEmpty) return;

    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final c in map.serverCells) {
      final x = c.col * map.cellSize;
      final y = c.row * map.cellSize;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x + map.cellSize > maxX) maxX = x + map.cellSize;
      if (y + map.cellSize > maxY) maxY = y + map.cellSize;
    }

    final rect = Rect.fromLTWH(minX + 6, minY + 6, maxX - minX - 12, maxY - minY - 12);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Glow do servidor
    final glow = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.3 + 0.1 * math.sin(_time * 3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rrect, glow);

    // Corpo do servidor
    final body = Paint()..color = const Color(0xFF0B1736);
    canvas.drawRRect(rrect, body);

    final border = Paint()
      ..color = const Color(0xFFB04DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, border);

    // Gavetas de rack do servidor
    final rackPaint = Paint()
      ..color = const Color(0xFF1E3A6E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final stepH = rect.height / 5;
    for (var i = 1; i < 5; i++) {
      final y = rect.top + i * stepH;
      canvas.drawLine(Offset(rect.left + 8, y), Offset(rect.right - 8, y), rackPaint);
    }

    // LEDs do servidor
    for (var i = 0; i < 4; i++) {
      final y = rect.top + (i + 0.5) * stepH;
      final ledOn = ((_time * 2 + i).floor() % 3) != 0;
      final ledColor = i == 0
          ? (ledOn ? const Color(0xFF00E5FF) : const Color(0xFF004D5A))
          : (ledOn ? const Color(0xFF3DFFA2) : const Color(0xFF0F4D2A));
      canvas.drawCircle(Offset(rect.left + 14, y), 3, Paint()..color = ledColor);
    }

    // Logo PHP estilizado
    final center = rect.center;
    GlyphPainter.drawCenteredText(
      canvas,
      'PHP',
      Offset(center.dx + 4, center.dy - 10),
      22,
      const Color(0xFF8892BF),
    );
    GlyphPainter.drawCenteredText(
      canvas,
      'SERVER',
      Offset(center.dx + 4, center.dy + 12),
      11,
      const Color(0xFF00E5FF),
    );
  }
}

/// Renderiza a prévia de posicionamento de uma torre, seu raio de alcance e indicação visual.
class PlacementOverlayComponent extends PositionComponent {
  PlacementOverlayComponent({
    required this.map,
    required this.getKind,
    required this.getCell,
    required this.getStatus,
  });

  final MapConfig map;
  final TowerKind? Function() getKind;
  final Cell? Function() getCell;
  final PlacementStatus? Function() getStatus;

  @override
  void render(Canvas canvas) {
    final kind = getKind();
    final cell = getCell();
    final status = getStatus();

    if (kind == null || cell == null || status == null) return;
    if (!map.isInside(cell)) return;

    final center = map.cellCenter(cell);
    final cfg = towerConfig(kind);
    final range = cfg.level(1).range;
    final valid = status.isValid;
    final color = valid ? const Color(0xFF00E5FF) : const Color(0xFFFF3D5A);

    // Círculo de alcance
    final rangeFill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final rangeStroke = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(center.x, center.y), range, rangeFill);
    canvas.drawCircle(Offset(center.x, center.y), range, rangeStroke);

    // Retângulo da célula
    final cellRect = Rect.fromLTWH(
      cell.col * map.cellSize + 2,
      cell.row * map.cellSize + 2,
      map.cellSize - 4,
      map.cellSize - 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Fantasma da torre
    GlyphPainter.drawTower(
      canvas,
      cfg,
      Offset(center.x, center.y),
      map.cellSize * 0.38,
      opacity: valid ? 0.75 : 0.4,
    );
  }
}

/// Renderiza o anel de alcance e seleção da torre selecionada no mapa.
class SelectionOverlayComponent extends PositionComponent {
  SelectionOverlayComponent({
    required this.map,
    required this.getSelectedTower,
  });

  final MapConfig map;
  final SimTower? Function() getSelectedTower;

  @override
  void render(Canvas canvas) {
    final tower = getSelectedTower();
    if (tower == null) return;

    final center = Offset(tower.position.x, tower.position.y);
    final range = tower.stats.range;
    final color = Color(tower.config.color);

    // Círculo de alcance
    canvas.drawCircle(
      center,
      range,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      range,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Anel pulsante ao redor da torre
    canvas.drawCircle(
      center,
      map.cellSize * 0.48,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}
