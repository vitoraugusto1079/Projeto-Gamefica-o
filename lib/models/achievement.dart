import 'profile.dart';

/// Definição de conquista. Os mesmos IDs existem na tabela `achievements`
/// (ver supabase/migrations). A concessão real no modo online é feita pela
/// função `finish_match` no banco.
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.progressOf,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final int Function(PlayerStats s) progressOf;

  /// Código do ícone desenhado localmente.
  final String icon;
}

final List<AchievementDef> achievementDefs = [
  AchievementDef(
    id: 'first_block',
    title: 'Primeiro bloqueio',
    description: 'Elimine o primeiro inimigo.',
    target: 1,
    progressOf: (s) => s.totalKills,
    icon: 'shield',
  ),
  AchievementDef(
    id: 'server_protected',
    title: 'Servidor protegido',
    description: 'Vença uma partida.',
    target: 1,
    progressOf: (s) => s.wins,
    icon: 'server',
  ),
  AchievementDef(
    id: 'flawless_defense',
    title: 'Defesa impecável',
    description: 'Vença uma partida com 100 de integridade.',
    target: 1,
    progressOf: (s) => s.flawlessWins,
    icon: 'star',
  ),
  AchievementDef(
    id: 'security_specialist',
    title: 'Especialista em segurança',
    description: 'Construa os cinco tipos de torre em uma mesma partida.',
    target: 5,
    progressOf: (s) => s.bestTowerKinds,
    icon: 'grid',
  ),
  AchievementDef(
    id: 'threat_hunter',
    title: 'Caçador de ameaças',
    description: 'Derrote o chefe HYDRA AI.',
    target: 1,
    progressOf: (s) => s.bossesDefeated,
    icon: 'target',
  ),
  AchievementDef(
    id: 'max_defense',
    title: 'Defesa máxima',
    description: 'Melhore uma torre até o nível 3.',
    target: 3,
    progressOf: (s) => s.maxTowerLevel,
    icon: 'up',
  ),
];

/// Estado de uma conquista para exibição.
class AchievementStatus {
  const AchievementStatus({
    required this.def,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
  });

  final AchievementDef def;
  final int progress;
  final bool unlocked;
  final DateTime? unlockedAt;

  double get fraction => def.target == 0 ? 1 : (progress / def.target).clamp(0, 1).toDouble();
}
