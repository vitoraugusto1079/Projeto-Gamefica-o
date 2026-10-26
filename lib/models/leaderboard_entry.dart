/// Linha do ranking. Contém apenas dados públicos (sem e-mail).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.nickname,
    required this.bestScore,
    required this.wins,
    required this.bestWave,
    required this.isMe,
  });

  final int rank;
  final String nickname;
  final int bestScore;
  final int wins;
  final int bestWave;
  final bool isMe;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m) => LeaderboardEntry(
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        nickname: (m['nickname'] as String?) ?? 'Anônimo',
        bestScore: (m['best_score'] as num?)?.toInt() ?? 0,
        wins: (m['wins'] as num?)?.toInt() ?? 0,
        bestWave: (m['best_wave'] as num?)?.toInt() ?? 0,
        isMe: m['is_me'] == true,
      );
}

/// Resposta da função `finish_match`.
class MatchSubmission {
  const MatchSubmission({
    required this.score,
    required this.newAchievements,
    required this.alreadyFinished,
  });

  final int score;
  final List<String> newAchievements;
  final bool alreadyFinished;

  factory MatchSubmission.fromMap(Map<String, dynamic> m) => MatchSubmission(
        score: (m['score'] as num?)?.toInt() ?? 0,
        newAchievements:
            ((m['new_achievements'] as List?) ?? const []).map((e) => '$e').toList(),
        alreadyFinished: m['already_finished'] == true,
      );
}
