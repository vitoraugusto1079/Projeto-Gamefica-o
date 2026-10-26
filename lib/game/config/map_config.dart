import '../sim/vec.dart';

/// Configuração de um mapa em coordenadas lógicas.
///
/// O mapa é uma grade de [cols] x [rows] células de [cellSize] unidades
/// lógicas. O caminho é definido por pontos de passagem em coordenadas de
/// célula, ligados por segmentos horizontais ou verticais. As células
/// bloqueadas pelo caminho são calculadas a partir desses pontos, então
/// alterar o caminho mantém o bloqueio de posicionamento coerente.
class MapConfig {
  const MapConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.cols,
    required this.rows,
    required this.cellSize,
    required this.waypoints,
    required this.serverCells,
  });

  final String id;
  final String name;
  final String description;
  final int cols;
  final int rows;
  final double cellSize;

  /// Pontos de passagem (coluna, linha). O primeiro pode ficar uma célula
  /// fora do mapa para que os inimigos "entrem" pela borda.
  final List<Cell> waypoints;

  /// Células ocupadas pelo servidor PHP (não aceitam torres).
  final List<Cell> serverCells;

  double get width => cols * cellSize;
  double get height => rows * cellSize;

  bool isInside(Cell c) => c.col >= 0 && c.row >= 0 && c.col < cols && c.row < rows;

  /// Centro de uma célula em coordenadas lógicas.
  Vec cellCenter(Cell c) => Vec((c.col + 0.5) * cellSize, (c.row + 0.5) * cellSize);

  /// Célula que contém um ponto lógico.
  Cell cellAt(Vec p) => Cell((p.x / cellSize).floor(), (p.y / cellSize).floor());

  /// Pontos do caminho em coordenadas lógicas.
  List<Vec> get pathPoints => waypoints.map(cellCenter).toList(growable: false);

  /// Todas as células percorridas pelo caminho (dentro do mapa).
  Set<Cell> get pathCells {
    final cells = <Cell>{};
    for (var i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      final dc = (b.col - a.col).sign;
      final dr = (b.row - a.row).sign;
      var c = a;
      cells.add(c);
      while (c != b) {
        c = Cell(c.col + dc, c.row + dr);
        cells.add(c);
      }
    }
    return cells.where(isInside).toSet();
  }

  /// Células onde não é permitido construir.
  Set<Cell> get blockedCells => {...pathCells, ...serverCells};

  /// Valida a configuração. Retorna a lista de problemas (vazia = válido).
  List<String> validate() {
    final errors = <String>[];
    if (cols <= 0 || rows <= 0 || cellSize <= 0) {
      errors.add('Dimensões inválidas.');
    }
    if (waypoints.length < 2) {
      errors.add('O caminho precisa de pelo menos 2 pontos.');
      return errors;
    }
    for (var i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      if (a == b) errors.add('Pontos $i e ${i + 1} são iguais.');
      if (a.col != b.col && a.row != b.row) {
        errors.add('Segmento $i não é horizontal nem vertical.');
      }
    }
    final first = waypoints.first;
    final firstOk = isInside(first) ||
        (first.col >= -1 && first.row >= -1 && first.col <= cols && first.row <= rows);
    if (!firstOk) errors.add('Ponto inicial muito distante do mapa.');
    for (var i = 1; i < waypoints.length; i++) {
      if (!isInside(waypoints[i])) errors.add('Ponto $i fora do mapa.');
    }
    if (serverCells.isEmpty) errors.add('Servidor sem células.');
    for (final s in serverCells) {
      if (!isInside(s)) errors.add('Célula do servidor fora do mapa: $s');
    }
    if (!serverCells.contains(waypoints.last) &&
        !serverCells.any((s) =>
            (s.col - waypoints.last.col).abs() + (s.row - waypoints.last.row).abs() == 1)) {
      errors.add('O caminho não termina no servidor.');
    }
    return errors;
  }
}

/// Mapa disponível na primeira versão.
const circuitAlpha = MapConfig(
  id: 'placa_alfa',
  name: 'Placa-Mãe Alfa',
  description:
      'Uma placa de circuito com trilhas sinuosas que levam ao servidor PHP. '
      'Ideal para aprender a defender a aplicação.',
  cols: 20,
  rows: 11,
  cellSize: 64,
  waypoints: [
    Cell(-1, 1),
    Cell(3, 1),
    Cell(3, 8),
    Cell(7, 8),
    Cell(7, 2),
    Cell(11, 2),
    Cell(11, 9),
    Cell(15, 9),
    Cell(15, 5),
    Cell(17, 5),
  ],
  serverCells: [
    Cell(18, 4),
    Cell(19, 4),
    Cell(18, 5),
    Cell(19, 5),
    Cell(18, 6),
    Cell(19, 6),
  ],
);

const availableMaps = [circuitAlpha];

MapConfig mapById(String id) =>
    availableMaps.firstWhere((m) => m.id == id, orElse: () => circuitAlpha);
