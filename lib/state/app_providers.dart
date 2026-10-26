import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../data/supabase_backend.dart';
import '../models/achievement.dart';
import '../models/leaderboard_entry.dart';
import '../models/match_outcome.dart';
import '../models/profile.dart';

final backendProvider = Provider<SupabaseBackend?>((ref) {
  if (!AppEnv.hasSupabase) return null;
  return SupabaseBackend(Supabase.instance.client);
});

/// Verdadeiro quando não há credenciais: modo de demonstração local.
final isDemoProvider = Provider<bool>((ref) => ref.watch(backendProvider) == null);

/// Usuário autenticado (sempre nulo no modo demonstração).
final authUserProvider = StreamProvider<User?>((ref) {
  final backend = ref.watch(backendProvider);
  if (backend == null) return Stream.value(null);
  final controller = StreamController<User?>();
  controller.add(backend.currentUser);
  final sub = backend.authChanges.listen(
    (s) => controller.add(s.session?.user),
    onError: (_) {},
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

final profileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final backend = ref.watch(backendProvider);
  final user = ref.watch(authUserProvider).value;
  if (backend == null || user == null) return null;
  return backend.fetchProfile();
});

/// Progresso local do modo demonstração (apenas em memória, não é enviado).
class DemoProgressNotifier extends Notifier<PlayerStats> {
  @override
  PlayerStats build() => const PlayerStats();

  void record(MatchOutcome o) {
    final s = state;
    state = PlayerStats(
      matchesPlayed: s.matchesPlayed + 1,
      wins: s.wins + (o.victory ? 1 : 0),
      bestScore: o.score > s.bestScore ? o.score : s.bestScore,
      bestWave: o.waveReached > s.bestWave ? o.waveReached : s.bestWave,
      totalKills: s.totalKills + o.kills,
      bestTowerKinds: o.towerKindsBuilt > s.bestTowerKinds ? o.towerKindsBuilt : s.bestTowerKinds,
      maxTowerLevel: o.maxTowerLevel > s.maxTowerLevel ? o.maxTowerLevel : s.maxTowerLevel,
      bossesDefeated: s.bossesDefeated + (o.bossDefeated ? 1 : 0),
      flawlessWins: s.flawlessWins + (o.victory && o.integrity >= 100 ? 1 : 0),
    );
  }
}

final demoProgressProvider =
    NotifierProvider<DemoProgressNotifier, PlayerStats>(DemoProgressNotifier.new);

final achievementsProvider = FutureProvider.autoDispose<List<AchievementStatus>>((ref) async {
  final backend = ref.watch(backendProvider);
  if (backend == null) {
    final stats = ref.watch(demoProgressProvider);
    return achievementDefs.map((d) {
      final p = d.progressOf(stats);
      return AchievementStatus(def: d, progress: p.clamp(0, d.target), unlocked: p >= d.target);
    }).toList();
  }
  ref.watch(authUserProvider);
  return backend.fetchAchievements();
});

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final backend = ref.watch(backendProvider);
  if (backend == null) return const [];
  ref.watch(authUserProvider);
  return backend.fetchLeaderboard();
});

// ---- Resultado da última partida --------------------------------------------

enum SubmissionStatus { demo, notRegistered, sending, saved, failed }

class ResultData {
  const ResultData({
    required this.outcome,
    required this.status,
    this.submission,
    this.error,
    this.matchKey = 0,
  });

  final MatchOutcome outcome;
  final SubmissionStatus status;
  final MatchSubmission? submission;
  final String? error;
  final int matchKey;

  ResultData copyWith({SubmissionStatus? status, MatchSubmission? submission, String? error}) =>
      ResultData(
        outcome: outcome,
        status: status ?? this.status,
        submission: submission ?? this.submission,
        error: error ?? this.error,
        matchKey: matchKey,
      );
}

/// Guarda o resultado da última partida e faz o envio ao backend uma única vez
/// por partida (mesmo se a tela for reconstruída ou o evento repetido).
class ResultNotifier extends Notifier<ResultData?> {
  final Set<int> _submittedKeys = {};

  @override
  ResultData? build() => null;

  /// [matchKey] identifica a partida localmente; [matchId] é o ID no servidor.
  Future<void> submit({
    required int matchKey,
    required MatchOutcome outcome,
    required Future<String?> matchId,
  }) async {
    if (!_submittedKeys.add(matchKey)) return; // já enviado
    final backend = ref.read(backendProvider);
    if (backend == null) {
      ref.read(demoProgressProvider.notifier).record(outcome);
      state = ResultData(outcome: outcome, status: SubmissionStatus.demo, matchKey: matchKey);
      return;
    }
    state = ResultData(outcome: outcome, status: SubmissionStatus.sending, matchKey: matchKey);
    String? id;
    try {
      id = await matchId;
    } catch (_) {
      id = null;
    }
    if (id == null) {
      _update(matchKey, (r) => r.copyWith(
            status: SubmissionStatus.notRegistered,
            error: 'A partida não foi registrada no início (sem conexão?). O resultado não '
                'pôde ser salvo.',
          ));
      return;
    }
    try {
      final sub = await backend.finishMatch(id, outcome);
      _update(matchKey, (r) => r.copyWith(status: SubmissionStatus.saved, submission: sub));
      ref.invalidate(profileProvider);
      ref.invalidate(achievementsProvider);
      ref.invalidate(leaderboardProvider);
    } on BackendException catch (e) {
      _update(matchKey, (r) => r.copyWith(status: SubmissionStatus.failed, error: e.message));
    }
  }

  void _update(int key, ResultData Function(ResultData) f) {
    final s = state;
    if (s != null && s.matchKey == key) state = f(s);
  }

  void clear() => state = null;
}

final resultProvider = NotifierProvider<ResultNotifier, ResultData?>(ResultNotifier.new);
