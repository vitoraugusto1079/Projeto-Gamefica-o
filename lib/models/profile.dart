/// Estatísticas agregadas de um jogador (perfil).
class PlayerStats {
  const PlayerStats({
    this.matchesPlayed = 0,
    this.wins = 0,
    this.bestScore = 0,
    this.bestWave = 0,
    this.totalKills = 0,
    this.bestTowerKinds = 0,
    this.maxTowerLevel = 0,
    this.bossesDefeated = 0,
    this.flawlessWins = 0,
  });

  final int matchesPlayed;
  final int wins;
  final int bestScore;
  final int bestWave;
  final int totalKills;
  final int bestTowerKinds;
  final int maxTowerLevel;
  final int bossesDefeated;
  final int flawlessWins;

  factory PlayerStats.fromMap(Map<String, dynamic> m) => PlayerStats(
        matchesPlayed: _i(m['matches_played']),
        wins: _i(m['wins']),
        bestScore: _i(m['best_score']),
        bestWave: _i(m['best_wave']),
        totalKills: _i(m['total_kills']),
        bestTowerKinds: _i(m['best_tower_kinds']),
        maxTowerLevel: _i(m['max_tower_level']),
        bossesDefeated: _i(m['bosses_defeated']),
        flawlessWins: _i(m['flawless_wins']),
      );

  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
}

/// Perfil público/privado do usuário autenticado.
class Profile {
  const Profile({required this.id, required this.nickname, required this.stats, this.email});

  final String id;
  final String nickname;

  /// E-mail apenas do próprio usuário (vindo da sessão, nunca do ranking).
  final String? email;
  final PlayerStats stats;
}
