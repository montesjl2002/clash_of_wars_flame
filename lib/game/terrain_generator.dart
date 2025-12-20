import '../terrain/terrain_tile.dart';
import '../terrain/terrain_type.dart';

class TerrainGenerator {
  final int width;
  final int height;
  final int seed;
  late List<List<TerrainTile>> tiles;
  
  // Identificador del mapa actual (null = sin mapa)
  String? currentMapId;

  // Constructor desde datos del editor (array de ints) - CON TEXTURAS
  TerrainGenerator.fromEditor({
    required this.width,
    required this.height,
    required List<List<int>> mapData,
    required String mapId,
    int? seed,
  }) : seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    currentMapId = mapId;
    tiles = _convertMapDataToTiles(mapData);
  }
  
  // Constructor para mapa NEGRO (sin mapa guardado)
  TerrainGenerator.empty({
    required this.width,
    required this.height,
    int? seed,
  }) : seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    currentMapId = null;
    // Crear mapa completamente NEGRO (deepWater como placeholder negro)
    tiles = _createBlackMap();
  }

  List<List<TerrainTile>> _createBlackMap() {
    // Mapa completamente negro para indicar "no hay mapa"
    return List.generate(
      height,
      (_) => List.generate(
        width,
        (_) => TerrainTile(
          type: TerrainType.deepWater, // Usamos esto como "negro"
          noiseValue: -1.0,
        ),
      ),
    );
  }

  List<List<TerrainTile>> _convertMapDataToTiles(List<List<int>> mapData) {
    return mapData.map((row) {
      return row.map((typeIndex) {
        final type = TerrainType.values[typeIndex];
        return TerrainTile(
          type: type,
          noiseValue: _getNoiseValueForType(type),
        );
      }).toList();
    }).toList();
  }

  double _getNoiseValueForType(TerrainType type) {
    switch (type) {
      case TerrainType.deepWater:
        return -0.5;
      case TerrainType.midWater:
        return -0.2;
      case TerrainType.shore:
        return -0.05;
      case TerrainType.sand:
        return 0.05;
      case TerrainType.grass:
        return 0.3;
    }
  }

  bool canBuildAt(int x, int y) {
    if (!_isValidPosition(x, y)) return false;
    final type = tiles[y][x].type;
    return type == TerrainType.sand || type == TerrainType.grass;
  }

  bool _isValidPosition(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  bool hasValidMap() => currentMapId != null;

  List<List<TerrainTile>> generate() => tiles;
}