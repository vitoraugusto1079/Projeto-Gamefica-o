import 'dart:math' as math;

/// Vetor 2D imutável usado pela simulação (independente do Flame).
class Vec {
  const Vec(this.x, this.y);

  final double x;
  final double y;

  static const zero = Vec(0, 0);

  Vec operator +(Vec o) => Vec(x + o.x, y + o.y);
  Vec operator -(Vec o) => Vec(x - o.x, y - o.y);
  Vec operator *(double s) => Vec(x * s, y * s);

  double get length => math.sqrt(x * x + y * y);
  double get length2 => x * x + y * y;

  double distanceTo(Vec o) => (this - o).length;
  double distance2To(Vec o) => (this - o).length2;

  Vec normalized() {
    final l = length;
    if (l == 0) return Vec.zero;
    return Vec(x / l, y / l);
  }

  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec($x, $y)';
}

/// Célula da grade lógica do mapa.
class Cell {
  const Cell(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => 'Cell($col, $row)';
}
