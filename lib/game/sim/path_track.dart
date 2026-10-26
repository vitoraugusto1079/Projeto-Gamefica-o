import 'vec.dart';

/// Trajeto percorrido pelos inimigos, parametrizado por distância.
class PathTrack {
  PathTrack(List<Vec> points)
      : assert(points.length >= 2),
        points = List.unmodifiable(points) {
    var acc = 0.0;
    _cumulative.add(0);
    for (var i = 0; i < points.length - 1; i++) {
      acc += points[i].distanceTo(points[i + 1]);
      _cumulative.add(acc);
    }
    length = acc;
  }

  final List<Vec> points;
  final List<double> _cumulative = [];
  late final double length;

  /// Posição no caminho para uma distância percorrida.
  Vec positionAt(double distance) {
    if (distance <= 0) return points.first;
    if (distance >= length) return points.last;
    // Busca binária pelo segmento.
    var lo = 0;
    var hi = _cumulative.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_cumulative[mid] <= distance) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segLen = _cumulative[hi] - _cumulative[lo];
    final t = segLen == 0 ? 0.0 : (distance - _cumulative[lo]) / segLen;
    final a = points[lo];
    final b = points[hi];
    return Vec(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
  }
}
