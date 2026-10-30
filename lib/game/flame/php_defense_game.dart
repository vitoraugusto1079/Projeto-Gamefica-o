import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../../state/match_controller.dart';
import '../config/map_config.dart';
import '../render/circuit_components.dart';
import '../render/entity_renderer_component.dart';
import '../sim/vec.dart';

/// Componente que captura toques, arrastos (pan), pinça (zoom) e movimentos do mouse.
class _InputCaptureComponent extends PositionComponent
    with
        TapCallbacks,
        DragCallbacks,
        ScaleCallbacks,
        PointerMoveCallbacks,
        HoverCallbacks {
  _InputCaptureComponent({
    required this.map,
    required this.controller,
    required this.gameRef,
  }) : super(size: Vector2(map.width, map.height));

  final MapConfig map;
  final MatchController controller;
  final PhpDefenseGame gameRef;

  double _scaleStartZoom = 1.0;

  /// Permite iniciar arrasto ou pinça de qualquer ponto da tela.
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    final pos = event.localPosition;
    final isMouse = event.deviceKind == PointerDeviceKind.mouse;
    controller.tapAt(Vec(pos.x, pos.y), isMouse: isMouse);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isScaling) return;
    gameRef.panBy(event.canvasDelta);
  }

  @override
  void onScaleStart(ScaleStartEvent event) {
    super.onScaleStart(event);
    _scaleStartZoom = controller.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateEvent event) {
    if (event.pointerCount >= 2 && event.scale > 0) {
      controller.setZoom(_scaleStartZoom * event.scale);
    }
    if (!event.focalPointDelta.isZero()) {
      gameRef.panBy(event.focalPointDelta);
    }
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
/// Utiliza câmera de tela cheia com suporte a zoom (botões na tela ou pinça) e
/// deslocamento por arrasto (pan), mantendo o alinhamento exato das coordenadas
/// lógicas do mapa em qualquer resolução ou orientação (horizontal e vertical).
class PhpDefenseGame extends FlameGame {
  PhpDefenseGame({
    required this.controller,
  }) : map = controller.map,
       super(camera: CameraComponent());

  final MatchController controller;
  final MapConfig map;

  late final EntityRendererComponent _entityRenderer;
  late final PlacementOverlayComponent _placementOverlay;
  late final SelectionOverlayComponent _selectionOverlay;

  double _fitZoom = 1.0;
  double _appliedUserZoom = 1.0;
  int _lastResetTick = 0;

  @override
  Color backgroundColor() => const Color(0xFF050B1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(map.width / 2, map.height / 2);

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

    // 5. Captura de toques, arrasto de câmera e gestos de zoom
    world.add(
      _InputCaptureComponent(
        map: map,
        controller: controller,
        gameRef: this,
      ),
    );

    _recalculateFitZoom();
    _syncCamera();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recalculateFitZoom();
    _syncCamera();
  }

  void _recalculateFitZoom() {
    if (canvasSize.x <= 0 || canvasSize.y <= 0) return;
    _fitZoom = math.min(canvasSize.x / map.width, canvasSize.y / map.height);
  }

  void _syncCamera() {
    if (!isLoaded) return;
    if (_lastResetTick != controller.cameraResetTick) {
      _lastResetTick = controller.cameraResetTick;
      camera.viewfinder.position = Vector2(map.width / 2, map.height / 2);
    }
    _appliedUserZoom = controller.zoom;
    final effectiveZoom = (_fitZoom * _appliedUserZoom).clamp(0.05, 20.0);
    camera.viewfinder.zoom = effectiveZoom;
    _clampCameraPosition();
  }

  /// Move a câmera de acordo com o arrasto em pixels da tela.
  void panBy(Vector2 canvasDelta) {
    if (!isLoaded) return;
    final z = camera.viewfinder.zoom;
    if (z <= 0) return;
    camera.viewfinder.position -= canvasDelta / z;
    _clampCameraPosition();
  }

  void _clampCameraPosition() {
    final z = camera.viewfinder.zoom;
    if (z <= 0 || canvasSize.x <= 0 || canvasSize.y <= 0) return;

    if (_appliedUserZoom <= 1.01) {
      camera.viewfinder.position = Vector2(map.width / 2, map.height / 2);
      return;
    }

    final visW = canvasSize.x / z;
    final visH = canvasSize.y / z;
    final padX = 48.0 / z;
    final padY = 100.0 / z;

    final minX = math.min(map.width / 2, math.max(0.0, visW / 2 - padX));
    final maxX = math.max(map.width / 2, math.min(map.width, map.width - visW / 2 + padX));

    final minY = math.min(map.height / 2, math.max(0.0, visH / 2 - padY));
    final maxY = math.max(map.height / 2, math.min(map.height, map.height - visH / 2 + padY));

    final cur = camera.viewfinder.position;
    camera.viewfinder.position = Vector2(
      cur.x.clamp(minX, maxX),
      cur.y.clamp(minY, maxY),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_appliedUserZoom != controller.zoom ||
        _lastResetTick != controller.cameraResetTick) {
      _syncCamera();
    }
    // Avança a simulação da partida e encaminha eventos visuais
    final events = controller.tick(dt);
    if (events.isNotEmpty) {
      _entityRenderer.handleEvents(events);
    }
  }
}
