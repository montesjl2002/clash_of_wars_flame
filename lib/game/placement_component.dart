import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'iso_grid.dart';
import 'building.dart';
import 'clash_of_war_game.dart';
import 'package:flame/flame.dart';

class PlacementComponent extends PositionComponent {
  final IsoGrid grid;
  late SpriteComponent spriteComp;
  final String keyName;
  final int buildingWidth;
  final int buildingHeight;
  
  Vector2? currentGridPos;
  bool canPlace = false;

  PlacementComponent(
    this.grid,
    this.keyName, {
    this.buildingWidth = 1,
    this.buildingHeight = 1,
  });

  static Future<PlacementComponent> create(
    IsoGrid grid,
    String key, {
    int buildingWidth = 1,
    int buildingHeight = 1,
  }) async {
    final component = PlacementComponent(
      grid,
      key,
      buildingWidth: buildingWidth,
      buildingHeight: buildingHeight,
    );
    await component._init();
    return component;
  }

  Future<void> _init() async {
    final image = Flame.images.fromCache(keyName);
    final sprite = Sprite(image);
    
    final spriteWidth = grid.tileWidth * buildingWidth.toDouble();
    final spriteHeight = grid.tileHeight * buildingHeight.toDouble() + 64.0;
    
    spriteComp = SpriteComponent(
      sprite: sprite,
      size: Vector2(spriteWidth, spriteHeight),
      anchor: Anchor.bottomCenter,
    );
    add(spriteComp);
    
    position = grid.gridToScreen(0.0, 0.0);
    priority = 1000;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (currentGridPos != null) {
      canPlace = grid.canPlaceBuilding(
        currentGridPos!.x.toInt(),
        currentGridPos!.y.toInt(),
        buildingWidth,
        buildingHeight,
      );
      
      spriteComp.paint = Paint()
        ..color = canPlace 
            ? const Color(0xAA00FF00)
            : const Color(0xAAFF0000);
    } else {
      spriteComp.paint = Paint()..color = const Color(0xAAFFFFFF);
      canPlace = false;
    }
  }

  void updatePosition(Vector2 screenPos) {
    final gridPos = grid.screenToGrid(screenPos);
    
    if (gridPos != null) {
      currentGridPos = gridPos;
      
      final centerX = gridPos.x + (buildingWidth - 1) / 2.0;
      final centerY = gridPos.y + (buildingHeight - 1) / 2.0;
      final centerScreen = grid.gridToScreen(centerX, centerY);
      
      // CLAVE: Debe ser idéntico a Building
      final offsetY = grid.tileHeight * (buildingHeight == 2 ? 0.5 : 0.3);
      
      position = Vector2(centerScreen.x, centerScreen.y + offsetY);
    } else {
      currentGridPos = null;
      position = screenPos;
    }
  }

  bool tryPlace() {
    if (currentGridPos != null && canPlace) {
      final gx = currentGridPos!.x.toInt();
      final gy = currentGridPos!.y.toInt();
      
      grid.markOccupied(gx, gy, buildingWidth, buildingHeight);
      
      final build = Building(
        keyName,
        gx,
        gy,
        grid,
        gridWidth: buildingWidth,
        gridHeight: buildingHeight,
      );
      
      if (parent != null) {
        parent!.add(build);
        
        if (parent is ClashOfWarGame) {
          final game = parent as ClashOfWarGame;
          game.buildingManager.addBuilding(build);
          game.buildingManager.saveProgress();
          
          // NUEVO: Descontar oro aquí
          if (game.selectedBuildingInfo != null) {
            game.currentGold -= game.selectedBuildingInfo!.cost;
            game.saveGold();
            game.onGoldChanged?.call(game.currentGold);
          }
          
          // Registrar mina de oro
          if (build.isGoldMine()) {
            game.goldMineManager.registerGoldMine(build);
          }
          
          if (game.onBuildingPlaced != null) {
            game.onBuildingPlaced!();
          }
        }
      }
      
      removeFromParent();
      return true;
    }
    return false;
  }
}