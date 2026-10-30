import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trilhas de áudio do jogo:
/// - [menu]: trilha ambiente/eletrônica calma (`assets/audio/menu.mp3`) para menus e navegação
/// - [match]: trilha de ação/combate (`assets/audio/partida.mp3`) durante a partida (`/match`)
enum BgmTrack {
  menu('audio/menu.mp3'),
  match('audio/partida.mp3');

  const BgmTrack(this.assetPath);
  final String assetPath;
}

class AudioState {
  const AudioState({
    this.currentTrack = BgmTrack.menu,
    this.isMuted = false,
    this.isPlaying = false,
  });

  final BgmTrack currentTrack;
  final bool isMuted;
  final bool isPlaying;

  AudioState copyWith({
    BgmTrack? currentTrack,
    bool? isMuted,
    bool? isPlaying,
  }) {
    return AudioState(
      currentTrack: currentTrack ?? this.currentTrack,
      isMuted: isMuted ?? this.isMuted,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioState>(AudioController.new);

class AudioController extends Notifier<AudioState> {
  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool _starting = false;

  @override
  AudioState build() {
    ref.onDispose(_disposePlayer);
    return const AudioState();
  }

  AudioPlayer? _ensurePlayer() {
    if (_player != null) return _player;
    try {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.loop);
      player.setVolume(0.65);

      // Caso alguma plataforma dispare onPlayerComplete mesmo em ReleaseMode.loop,
      // reiniciamos imediatamente a trilha atual para garantir loop infinito.
      _completeSub = player.onPlayerComplete.listen((_) {
        if (!state.isMuted) {
          _playTrack(state.currentTrack, forceRestart: true);
        }
      });

      _stateSub = player.onPlayerStateChanged.listen((playerState) {
        final playing = playerState == PlayerState.playing;
        if (state.isPlaying != playing) {
          state = state.copyWith(isPlaying: playing);
        }
      });

      _player = player;
      return player;
    } catch (e) {
      debugPrint('Aviso: AudioPlayer indisponível neste ambiente: $e');
      return null;
    }
  }

  void _disposePlayer() {
    _completeSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    _player = null;
  }

  /// Sincroniza automaticamente a música de fundo com a rota atual do GoRouter.
  Future<void> syncWithRoute(String location) async {
    final targetTrack =
        location.startsWith('/match') ? BgmTrack.match : BgmTrack.menu;
    await setTrack(targetTrack);
  }

  /// Define e toca a trilha desejada em loop contínuo.
  Future<void> setTrack(BgmTrack track) async {
    final trackChanged = state.currentTrack != track;
    if (trackChanged) {
      state = state.copyWith(currentTrack: track);
    }
    if (state.isMuted) return;

    if (trackChanged || !state.isPlaying) {
      await _playTrack(track, forceRestart: trackChanged);
    }
  }

  /// Chamado no primeiro toque/clique do usuário (necessário em navegadores Web
  /// que bloqueiam autoplay antes da primeira interação).
  Future<void> ensurePlaying() async {
    if (state.isMuted || state.isPlaying || _starting) return;
    await _playTrack(state.currentTrack, forceRestart: false);
  }

  /// Alterna entre som ativado e mudo.
  Future<void> toggleMute() async {
    final nextMuted = !state.isMuted;
    state = state.copyWith(isMuted: nextMuted);

    final player = _ensurePlayer();
    if (player == null) return;

    try {
      if (nextMuted) {
        await player.pause();
        state = state.copyWith(isPlaying: false);
      } else {
        await _playTrack(state.currentTrack, forceRestart: false);
      }
    } catch (e) {
      debugPrint('Aviso ao alternar mudo: $e');
    }
  }

  Future<void> _playTrack(BgmTrack track, {required bool forceRestart}) async {
    if (_starting) return;
    _starting = true;
    try {
      final player = _ensurePlayer();
      if (player == null) return;

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(state.isMuted ? 0.0 : 0.65);

      if (forceRestart) {
        await player.stop();
      }

      await player.play(AssetSource(track.assetPath));
      state = state.copyWith(currentTrack: track, isPlaying: true);
    } catch (e) {
      // Em navegadores Web antes do primeiro clique, o autoplay pode ser adiado;
      // o Listener global em PhpDefenseApp chamará ensurePlaying() no primeiro toque.
      debugPrint('Áudio aguardando interação do usuário: $e');
    } finally {
      _starting = false;
    }
  }
}
