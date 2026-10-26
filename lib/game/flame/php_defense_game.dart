import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../../state/match_controller.dart';
import '../config/map_config.dart';
import '../render/circuit_components.dart';
import '../render/entity_renderer_component.dart';
import '../sim/vec.dart';

/// Componente que captura toques e movimentos do mouse dentro dos limites lógicos do mapa.
class _InputCaptureComponent extends PositionComponent
    with TapCallbacks, PointerMoveCallbacks, HoverCallbacks {
  _InputCaptureComponent({
    required this.map,
    required this.controller,
  }) : super(size: Vector2(map.width, map.height));

  final MapConfig map;
  final MatchController controller;

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;
    final isMouse = event.deviceKind == PointerDeviceKind.mouse;
    controller.tapAt(Vec(pos.x, pos.y), isMouse: isMouse);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    final pos = event.localPosition;
    controller.hoverAt(Vec(pos.x, pos.y));
  }

  @override
  void onHoverExit() {
    controller.hoverExit();
  }
}

/// Jogo Flame principal do PHP Defense.
///
/// Gerencia a câmera com resolução fixa alinhada às dimensões lógicas do mapa,
/// garantindo que a proporção e as coordenadas de toque sejam exatas em qualquer
/// tamanho de tela ou orientação.
class PhpDefenseGame extends FlameGame {
  PhpDefenseGame({
    required this.controller,
  }) : map = controller.map,
       super(
         camera: CameraComponent.withFixedResolution(
           width: controller.map.width,
           height: controller.map.height,
         ),
       );

  final MatchController controller;
  final MapConfig map;

  late final EntityRendererComponent _entityRenderer;
  late final PlacementOverlayComponent _placementOverlay;
  late final SelectionOverlayComponent _selectionOverlay;

  @override
  Color backgroundColor() => const Color(0xFF050B1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Centraliza a visão na origem lógica (0, 0)
    camera.viewfinder.anchor = Anchor.topLeft;

    // 1. Cenário da placa de circuito
    world.add(CircuitMapComponent(map: map));

    // 2. Anéis de seleção e raio de torres já construídas
    _selectionOverlay = SelectionOverlayComponent(
      map: map,
      getSelectedTower: () => controller.selectedTower,
    );
    world.add(_selectionOverlay);

    // 3. Prévia de posicionamento de novas torres
    _placementOverlay = PlacementOverlayComponent(
      map: map,
      getKind: () => controller.buildKind,
      getCell: () => controller.previewCell,
      getStatus: () => controller.previewStatus,
    );
    world.add(_placementOverlay);

    // 4. Renderizador de entidades (torres, inimigos, projéteis e partículas)
    _entityRenderer = EntityRendererComponent(
      map: map,
      getSimulation: () => controller.sim,
    );
    world.add(_entityRenderer);

    // 5. Captura de toques e movimentos
    world.add(_InputCaptureComponent(map: map, controller: controller));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Avança a simulação da partida e encaminha eventos visuais
    final events = controller.tick(dt);
    if (events.isNotEmpty) {
      _entityRenderer.handleEvents(events);
    }
  }
}
