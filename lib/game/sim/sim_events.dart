import '../config/enemy_config.dart';
import '../config/tower_config.dart';
import 'vec.dart';

/// Eventos emitidos pela simulação para a camada visual e para a interface.
/// São consumidos (drenados) a cada quadro; não afetam a lógica.
sealed class SimEvent {
  const SimEvent();
}

class TowerFiredEvent extends SimEvent {
  const TowerFiredEvent(this.towerId, this.kind, this.from, this.to);
  final int towerId;
  final TowerKind kind;
  final Vec from;
  final Vec to;
}

class ProjectileHitEvent extends SimEvent {
  const ProjectileHitEvent(this.kind, this.at, this.splashRadius);
  final TowerKind kind;
  final Vec at;
  final double splashRadius;
}

class ProjectileFizzledEvent extends SimEvent {
  const ProjectileFizzledEvent(this.at);
  final Vec at;
}

class EnemyKilledEvent extends SimEvent {
  const EnemyKilledEvent(this.kind, this.at, this.reward);
  final EnemyKind kind;
  final Vec at;
  final int reward;
}

class EnemyLeakedEvent extends SimEvent {
  const EnemyLeakedEvent(this.kind, this.damage);
  final EnemyKind kind;
  final int damage;
}

class ShieldStrippedEvent extends SimEvent {
  const ShieldStrippedEvent(this.at, this.kind);
  final Vec at;
  final EnemyKind kind;
}

class BossSpawnedEvent extends SimEvent {
  const BossSpawnedEvent(this.kind);
  final EnemyKind kind;
}

class BossSplitEvent extends SimEvent {
  const BossSplitEvent(this.kind, this.at, this.released);
  final EnemyKind kind;
  final Vec at;
  final int released;
}

class WaveCompletedEvent extends SimEvent {
  const WaveCompletedEvent(this.wave, this.bonus);
  final int wave;
  final int bonus;
}

class GameOverEvent extends SimEvent {
  const GameOverEvent(this.victory);
  final bool victory;
}
