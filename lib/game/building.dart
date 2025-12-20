import 'package:flame/components.dart';
import 'iso_grid.dart';
import 'package:flame/flame.dart';

class Building extends PositionComponent {
  final String keyName;
  final int gx;
  final int gy;
  final IsoGrid grid;
  final int gridWidth;
  final int gridHeight;
  
  // Para edificios que generan recursos
  double accumulatedGold = 0;
  double lastCollectionTime = 0;

  Building(
    this.keyName,
    this.gx,
    this.gy,
    this.grid, {
    this.gridWidth = 1,
    this.gridHeight = 1,
  });

  @override
  Future<void> onLoad() async {
    final image = Flame.images.fromCache(keyName);
    final sprite = Sprite(image);
    
    final spriteWidth = grid.tileWidth * gridWidth.toDouble();
    final spriteHeight = grid.tileHeight * gridHeight.toDouble() + 64.0;
    
    final spriteComp = SpriteComponent(
      sprite: sprite,
      size: Vector2(spriteWidth, spriteHeight),
      anchor: Anchor.bottomCenter,
    );
    add(spriteComp);
    
    final centerX = gx.toDouble() + (gridWidth - 1) / 2.0;
    final centerY = gy.toDouble() + (gridHeight - 1) / 2.0;
    final centerScreen = grid.gridToScreen(centerX, centerY);
    
    // CLAVE: Usar la misma fórmula que PlacementComponent
    final offsetY = grid.tileHeight * (gridHeight == 2 ? 0.5 : 0.3);
    
    position = Vector2(centerScreen.x, centerScreen.y + offsetY);
    priority = (gx + gridWidth - 1 + gy + gridHeight - 1);
  }
  
  bool occupiesCell(int x, int y) {
    return x >= gx && x < gx + gridWidth && y >= gy && y < gy + gridHeight;
  }
  
  bool isGoldMine() => keyName == 'gold_mine';
}