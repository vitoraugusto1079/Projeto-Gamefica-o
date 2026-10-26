import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/achievement.dart';
import '../models/leaderboard_entry.dart';
import '../models/match_outcome.dart';
import '../models/profile.dart';

class BackendException implements Exception {
  BackendException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum SignUpResult { signedIn, confirmationRequired }


class SupabaseBackend {
  SupabaseBackend(this.client);

  final SupabaseClient client;

  GoTrueClient get _auth => client.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  // ---- Autenticação --------------------------------------------------------

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw BackendException(translateAuthError(e.message));
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nickname': nickname.trim()},
      );
      return res.session != null ? SignUpResult.signedIn : SignUpResult.confirmationRequired;
    } on AuthException catch (e) {
      throw BackendException(translateAuthError(e.message));
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Mesmo com falha de rede a sessão local é removida pelo SDK.
    }
  }

  // ---- Perfil --------------------------------------------------------------

  Future<Profile> fetchProfile() async {
    final user = _requireUser();
    try {
      final row = await client
          .from('profiles')
          .select(
              'id, nickname, matches_played, wins, best_score, best_wave, total_kills, '
              'best_tower_kinds, max_tower_level, bosses_defeated, flawless_wins')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) {
        throw BackendException('Perfil não encontrado. Verifique se as migrations foram aplicadas.');
      }
      return Profile(
        id: user.id,
        nickname: row['nickname'] as String? ?? 'Defensor',
        email: user.email,
        stats: PlayerStats.fromMap(row),
      );
    } on PostgrestException catch (e) {
      throw BackendException('Erro ao carregar perfil: ${e.message}');
    } on BackendException {
      rethrow;
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  Future<void> updateNickname(String nickname) async {
    final user = _requireUser();
    try {
      await client.from('profiles').update({'nickname': nickname.trim()}).eq('id', user.id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw BackendException('Este apelido já está em uso.');
      if (e.code == '23514') {
        throw BackendException('Apelido inválido: use de 3 a 20 caracteres (letras, números, _ ou -).');
      }
      throw BackendException('Erro ao salvar apelido: ${e.message}');
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  // ---- Partidas ------------------------------------------------------------

  /// Registra o início da partida no servidor e devolve o ID.
  Future<String> startMatch(String mapId) async {
    _requireUser();
    try {
      final id = await client.rpc('start_match', params: {'p_map_id': mapId});
      return id as String;
    } on PostgrestException catch (e) {
      throw BackendException('Não foi possível registrar a partida: ${e.message}');
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  /// Finaliza a partida (transacional e idempotente no servidor).
  Future<MatchSubmission> finishMatch(String matchId, MatchOutcome o) async {
    _requireUser();
    try {
      final res = await client.rpc('finish_match', params: {
        'p_match_id': matchId,
        'p_victory': o.victory,
        'p_waves_completed': o.wavesCompleted,
        'p_kills': o.kills,
        'p_integrity': o.integrity,
        'p_tower_kinds': o.towerKindsBuilt,
        'p_max_tower_level': o.maxTowerLevel,
        'p_boss_defeated': o.bossDefeated,
      });
      return MatchSubmission.fromMap(Map<String, dynamic>.from(res as Map));
    } on PostgrestException catch (e) {
      throw BackendException('Resultado rejeitado pelo servidor: ${e.message}');
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  // ---- Conquistas ----------------------------------------------------------

  Future<List<AchievementStatus>> fetchAchievements() async {
    final profile = await fetchProfile();
    try {
      final rows = await client
          .from('user_achievements')
          .select('achievement_id, unlocked_at')
          .eq('user_id', profile.id);
      final unlocked = <String, DateTime?>{
        for (final r in rows)
          r['achievement_id'] as String: DateTime.tryParse('${r['unlocked_at']}'),
      };
      return achievementDefs
          .map((d) => AchievementStatus(
                def: d,
                progress: d.progressOf(profile.stats).clamp(0, d.target),
                unlocked: unlocked.containsKey(d.id),
                unlockedAt: unlocked[d.id],
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw BackendException('Erro ao carregar conquistas: ${e.message}');
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  // ---- Ranking -------------------------------------------------------------

  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 50}) async {
    try {
      final rows = await client.rpc('get_leaderboard', params: {'p_limit': limit});
      return (rows as List)
          .map((r) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw BackendException('Erro ao carregar ranking: ${e.message}');
    } catch (e) {
      throw BackendException(_networkMessage(e));
    }
  }

  // ---- Utilitários ---------------------------------------------------------

  User _requireUser() {
    final u = currentUser;
    if (u == null) throw BackendException('Sessão expirada. Entre novamente.');
    return u;
  }

  static String _networkMessage(Object e) {
    if (e is BackendException) return e.message;
    return 'Falha de comunicação com o servidor. Verifique sua conexão.';
  }

  /// Traduz mensagens comuns do Supabase Auth.
  static String translateAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'E-mail ou senha incorretos.';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (m.contains('email not confirmed')) {
      return 'E-mail ainda não confirmado. Verifique sua caixa de entrada.';
    }
    if (m.contains('password should be at least') || m.contains('weak password')) {
      return 'Senha fraca: use pelo menos 6 caracteres.';
    }
    if (m.contains('invalid email') || m.contains('unable to validate email')) {
      return 'E-mail inválido.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Muitas tentativas. Aguarde alguns instantes.';
    }
    if (m.contains('database error saving new user')) {
      return 'Não foi possível criar o perfil (apelido em uso ou inválido).';
    }
    return 'Erro de autenticação: $message';
  }
}
