import 'dart:ui';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import 'components/unit_component.dart';
import 'components/villager_component.dart';
import 'components/building_component.dart';
import 'core/polar_position.dart';
import 'core/game_constants.dart';
import 'camera/polar_camera.dart';
import 'systems/world_system.dart';
import 'systems/economy_system.dart';
import 'systems/production_system.dart';
import 'systems/combat_system.dart';
import 'systems/ai_system.dart';
import 'systems/input_system.dart';

/* Juego principal RTS Empire of War */
class RTSEmpireOfWar extends FlameGame
    with TapDetector, PanDetector, ScrollDetector {
  late PolarCamera polarCamera;
  late WorldSystem worldSystem;
  late EconomySystem economySystem;
  late ProductionSystem productionSystem;
  late CombatSystem combatSystem;
  late AISystem aiSystem;
  late InputSystem inputSystem;

  final int playerOwner = 0;
  final int aiOwner = 1;

  bool _initialized = false;
  Vector2? _lastPanPosition;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    polarCamera = PolarCamera();
    worldSystem = WorldSystem();
    economySystem = EconomySystem();
    productionSystem = ProductionSystem();
    combatSystem = CombatSystem();

    economySystem.initializePlayer(playerOwner);
    economySystem.initializePlayer(aiOwner);

    inputSystem = InputSystem(
      camera: polarCamera,
      worldSystem: worldSystem,
      playerOwner: playerOwner,
    );

    aiSystem = AISystem(
      aiOwner: aiOwner,
      worldSystem: worldSystem,
      economySystem: economySystem,
      productionSystem: productionSystem,
    );

    _initializeGame();
    _initialized = true;
  }

  /* Inicializa el juego */
  void _initializeGame() {
    worldSystem.initialize();

    final playerStartAngle = -pi / 4;
    final aiStartAngle = pi * 3 / 4;
    final startRadius = GameConstants.worldRadius * 0.3;

    final playerTownCenter = worldSystem.createBuilding(
      BuildingType.townCenter,
      playerOwner,
      PolarPosition(startRadius, playerStartAngle),
    );
    productionSystem.registerBuilding(playerTownCenter);

    final aiTownCenter = worldSystem.createBuilding(
      BuildingType.townCenter,
      aiOwner,
      PolarPosition(startRadius, aiStartAngle),
    );
    productionSystem.registerBuilding(aiTownCenter);

    for (int i = 0; i < 3; i++) {
      final angle = playerStartAngle + (Random().nextDouble() - 0.5) * 0.3;
      final radius = startRadius + (Random().nextDouble() - 0.5) * 100;
      worldSystem.createVillager(playerOwner, PolarPosition(radius, angle));
    }

    for (int i = 0; i < 3; i++) {
      final angle = aiStartAngle + (Random().nextDouble() - 0.5) * 0.3;
      final radius = startRadius + (Random().nextDouble() - 0.5) * 100;
      worldSystem.createVillager(aiOwner, PolarPosition(radius, angle));
    }

    polarCamera.focusOn(PolarPosition(startRadius, playerStartAngle));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_initialized) return;

    worldSystem.update(dt);
    productionSystem.update(dt);
    combatSystem.update(dt, worldSystem.units, worldSystem.buildings);
    aiSystem.update(dt);

    _processCompletedUnits();
    _processVillagerDeposits();
  }

  /* Procesa unidades completadas */
  void _processCompletedUnits() {
    final completed = productionSystem.getCompletedUnits();

    for (final completedUnit in completed) {
      final building = worldSystem.buildings.firstWhere(
        (b) => b.id == completedUnit.buildingId,
      );

      final spawnPos = PolarPosition(
        building.polarPosition.radius + 60,
        building.polarPosition.angle + (Random().nextDouble() - 0.5) * 0.5,
      );

      switch (completedUnit.type) {
        case UnitType.villager:
          worldSystem.createVillager(completedUnit.owner, spawnPos);
          economySystem.addPopulation(completedUnit.owner, 1);
          break;
        case UnitType.infantry:
          worldSystem.createInfantry(completedUnit.owner, spawnPos);
          economySystem.addPopulation(completedUnit.owner, 1);
          break;
        case UnitType.archer:
          worldSystem.createArcher(completedUnit.owner, spawnPos);
          economySystem.addPopulation(completedUnit.owner, 1);
          break;
      }
    }
  }

  /* Procesa depósitos de aldeanos */
  void _processVillagerDeposits() {
    final villagers = worldSystem.units.whereType<VillagerComponent>();

    for (final villager in villagers) {
      if (villager.hasResources) {
        final townCenters = worldSystem.buildings.where(
          (b) => b.type == BuildingType.townCenter && b.owner == villager.owner,
        );

        if (townCenters.isNotEmpty) {
          final nearest = townCenters.first;
          final distance =
              villager.polarPosition.distanceTo(nearest.polarPosition);

          if (distance < 80) {
            economySystem.addResources(
              villager.owner,
              food: villager.carriedFood,
              wood: villager.carriedWood,
              stone: villager.carriedStone,
            );
            villager.depositResources();
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_initialized) return;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF1a1a1a),
    );

    _renderWorld(canvas);
    _renderUI(canvas);
  }

  /* Renderiza el mundo */
/* Renderiza el mundo */
  void _renderWorld(Canvas canvas) {
    _renderMapRings(canvas);

    // Recursos
    for (final resource in worldSystem.resources) {
      final screenPos = polarCamera.worldToScreen(resource.position as PolarPosition);
      canvas.save();
      canvas.translate(screenPos.dx, screenPos.dy);
      resource.render(canvas); // Solo canvas
      canvas.restore();
    }

    // Edificios
    for (final building in worldSystem.buildings) {
      final screenPos = polarCamera.worldToScreen(building.position as PolarPosition);
      canvas.save();
      canvas.translate(screenPos.dx, screenPos.dy);
      building.render(canvas);
      canvas.restore();
    }

    // Unidades
    for (final unit in worldSystem.units) {
      final screenPos = polarCamera.worldToScreen(unit.position as PolarPosition);
      canvas.save();
      canvas.translate(screenPos.dx, screenPos.dy);
      unit.render(canvas);
      canvas.restore();
    }

    // Caja de selección
    final selectionBox = inputSystem.selectionBox;
    if (selectionBox != null) {
      final paint = Paint()
        ..color = GameConstants.selectionColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(selectionBox, paint);

      final borderPaint = Paint()
        ..color = GameConstants.selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(selectionBox, borderPaint);
    }
  }

  /* Renderiza anillos del mapa */
  void _renderMapRings(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    for (int i = 1; i <= GameConstants.numRings; i++) {
      final radius = (i * GameConstants.worldRadius / GameConstants.numRings) *
          polarCamera.zoom;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(center, radius, paint);
    }
  }

  /* Renderiza UI */
  void _renderUI(Canvas canvas) {
    final economy = economySystem.getEconomy(playerOwner);

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
    );

    _drawText(
      canvas,
      'Food: ${economy.food}',
      Offset(10, 10),
      textStyle.copyWith(color: GameConstants.foodColor),
    );

    _drawText(
      canvas,
      'Wood: ${economy.wood}',
      Offset(10, 35),
      textStyle.copyWith(color: GameConstants.woodColor),
    );

    _drawText(
      canvas,
      'Stone: ${economy.stone}',
      Offset(10, 60),
      textStyle.copyWith(color: GameConstants.stoneColor),
    );

    _drawText(
      canvas,
      'Population: ${economy.population}/${economy.maxPopulation}',
      Offset(10, 85),
      textStyle,
    );

    _drawText(
      canvas,
      'Selected: ${inputSystem.selectedUnits.length}',
      Offset(10, 110),
      textStyle.copyWith(color: GameConstants.selectionColor),
    );

    _checkVictoryCondition(canvas);
  }

  /* Verifica condición de victoria */
  void _checkVictoryCondition(Canvas canvas) {
    final playerBuildings = worldSystem.getPlayerBuildings(playerOwner);
    final aiBuildings = worldSystem.getPlayerBuildings(aiOwner);

    final playerTC =
        playerBuildings.any((b) => b.type == BuildingType.townCenter);
    final aiTC = aiBuildings.any((b) => b.type == BuildingType.townCenter);

    if (!playerTC) {
      _drawText(
        canvas,
        'DEFEAT - Press R to restart',
        Offset(size.x / 2 - 150, size.y / 2),
        const TextStyle(color: Colors.red, fontSize: 24),
      );
    } else if (!aiTC) {
      _drawText(
        canvas,
        'VICTORY - Press R to restart',
        Offset(size.x / 2 - 150, size.y / 2),
        const TextStyle(color: Colors.green, fontSize: 24),
      );
    }
  }

  /* Dibuja texto */
  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  void onTapDown(TapDownInfo info) {
    inputSystem.startSelection(info.eventPosition.global as Offset);
  }

  @override
  void onTapUp(TapUpInfo info) {
    inputSystem.endSelection();
  }

  @override
  void onPanStart(DragStartInfo info) {
    _lastPanPosition = info.eventPosition.global;
    inputSystem.startSelection(info.eventPosition.global as Offset);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_lastPanPosition != null) {
      final delta = info.eventPosition.global - _lastPanPosition!;
      polarCamera.pan(-delta.x, -delta.y, 0.016);
      _lastPanPosition = info.eventPosition.global;
    }
    inputSystem.updateSelection(info.eventPosition.global as Offset);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _lastPanPosition = null;
    inputSystem.endSelection();
  }

  @override
  void onScroll(PointerScrollInfo info) {
    polarCamera.adjustZoom(-info.scrollDelta.global.y / 1000);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    polarCamera.updateViewport(Size(canvasSize.x, canvasSize.y));
  }
}
