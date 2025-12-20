import 'dart:math';
import 'package:flame/components.dart';
import '../game/iso_grid.dart';
import 'terrain_tile.dart';
import 'terrain_type.dart';

class TerrainRenderer extends Component {
  final List<List<TerrainTile>> map;
  final IsoGrid iso;
  final Random _rand = Random();

  TerrainRenderer(this.map, this.iso);

  @override
  Future<void> onLoad() async {
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        await _drawBaseTile(x, y, map[y][x]);
        await _drawGrassOverlay(x, y, map[y][x]);
      }
    }
  }

  Future<void> _drawBaseTile(int x, int y, TerrainTile tile) async {
    String spritePath;

    switch (tile.type) {
      case TerrainType.grass:
        spritePath = 'tiles/grass/grass_${_rand.nextInt(5)}.png';
        break;
      case TerrainType.sand:
        spritePath = 'tiles/sand/sand_${_rand.nextInt(4)}.png';
        break;
      case TerrainType.shore:
        spritePath = 'tiles/water/shore_${_rand.nextInt(3)}.png';
        break;
      case TerrainType.midWater:
        spritePath = 'tiles/water/water_mid.png';
        break;
      case TerrainType.deepWater:
        spritePath = 'tiles/water/water_deep.png';
        break;
    }

    final pos = iso.gridToScreen(x.toDouble(), y.toDouble());

    try {
      add(
        SpriteComponent(
          sprite: await Sprite.load(spritePath),
          position: pos + _randomOffset(),
          size: iso.tileSize * _randomScale(),
          anchor: Anchor.center,
          priority: y + x, // Prioridad de renderizado isométrico
        ),
      );
    } catch (e) {
      // Si falta el sprite, dibujar un placeholder de color
      print('Warning: Missing sprite at $spritePath');
    }
  }

  Future<void> _drawGrassOverlay(int x, int y, TerrainTile tile) async {
    if (tile.type != TerrainType.grass) return;
    if (_rand.nextDouble() > 0.35) return;

    final pos = iso.gridToScreen(x.toDouble(), y.toDouble());

    try {
      add(
        SpriteComponent(
          sprite: await Sprite.load(
              'tiles/grass/grass_patch_${_rand.nextInt(5)}.png'),
          position: pos + _randomOffset(12),
          size: iso.tileSize * (0.8 + _rand.nextDouble() * 0.4),
          angle: _rand.nextDouble() * pi,
          anchor: Anchor.center,
          priority: y + x + 1,
        ),
      );
    } catch (e) {
      // Grass patch opcional, ignorar si no existe
    }
  }

  Vector2 _randomOffset([double max = 8]) =>
      Vector2(_rand.nextDouble() * max - max / 2,
              _rand.nextDouble() * max - max / 2);

  double _randomScale() => 1.2 + _rand.nextDouble() * 0.4;
}