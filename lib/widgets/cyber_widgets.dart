import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/config/tower_config.dart';
import '../game/render/glyph_painter.dart';

/// Renderiza o ícone vetorial de uma torre diretamente via Canvas.
class TowerIconWidget extends StatelessWidget {
  const TowerIconWidget({
    super.key,
    required this.kind,
    this.size = 48,
    this.level = 1,
  });

  final TowerKind kind;
  final double size;
  final int level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TowerPainter(kind: kind, level: level),
      ),
    );
  }
}

class _TowerPainter extends CustomPainter {
  _TowerPainter({required this.kind, required this.level});

  final TowerKind kind;
  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final cfg = towerConfig(kind);
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    GlyphPainter.drawTower(canvas, cfg, center, r, level: level);
  }

  @override
  bool shouldRepaint(covariant _TowerPainter old) =>
      old.kind != kind || old.level != level;
}

/// Cartão estilizado com bordas tecnológicas para a identidade visual cibersegurança.
class CyberCard extends StatelessWidget {
  const CyberCard({
    super.key,
    required this.child,
    this.borderColor = AppColors.border,
    this.backgroundColor = AppColors.surface,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
