import 'terrain_type.dart';

class TerrainTile {
  final TerrainType type;
  final double noiseValue;

  TerrainTile({
    required this.type,
    required this.noiseValue,
  });
}
