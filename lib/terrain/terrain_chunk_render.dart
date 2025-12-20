import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import '../game/iso_grid.dart';
import '../game/clash_of_war_game.dart';
import 'terrain_tile.dart';
import 'terrain_type.dart';

class TerrainChunk extends Component {
  final int chunkX;
  final int chunkY;
  final List<List<TerrainTile>> tiles;
  final IsoGrid iso;
  final int seed;
  bool isLoaded = false;

  TerrainChunk({
    required this.chunkX,
    required this.chunkY,
    required this.tiles,
    required this.iso,
    required this.seed,
  });

  Future<void> loadSprites() async {
    if (isLoaded) return;
    isLoaded = true;

    for (int y = 0; y < tiles.length; y++) {
      for (int x = 0; x < tiles[y].length; x++) {
        await _drawBaseTile(x, y, tiles[y][x]);
        await _drawGrassOverlay(x, y, tiles[y][x]);
      }
    }
  }

  Future<void> _drawBaseTile(int localX, int localY, TerrainTile tile) async {
    final worldX = chunkX + localX;
    final worldY = chunkY + localY;
    
    // Seed determinístico para este tile específico
    final tileSeed = seed ^ (worldX * 73856093) ^ (worldY * 19349663);
    final rand = Random(tileSeed);
    
    String spriteKey;

    switch (tile.type) {
      case TerrainType.grass:
        spriteKey = 'grass_${rand.nextInt(5)}';
        break;
      case TerrainType.sand:
        spriteKey = 'sand_${rand.nextInt(4)}';
        break;
      case TerrainType.shore:
        spriteKey = 'shore_${rand.nextInt(3)}';
        break;
      case TerrainType.midWater:
        spriteKey = 'water_mid';
        break;
      case TerrainType.deepWater:
        spriteKey = 'water_deep';
        break;
    }

    final pos = iso.gridToScreen(worldX.toDouble(), worldY.toDouble());

    try {
      // Cargar desde cache de AssetLoader
      final image = Flame.images.fromCache(spriteKey);
      final sprite = Sprite(image);
      
      add(
        SpriteComponent(
          sprite: sprite,
          position: pos + _randomOffset(rand),
          size: iso.tileSize * _randomScale(rand),
          anchor: Anchor.center,
          priority: worldY + worldX,
        ),
      );
    } catch (e) {
      // Sprite no disponible, continuar
    }
  }

  Future<void> _drawGrassOverlay(int localX, int localY, TerrainTile tile) async {
    if (tile.type != TerrainType.grass) return;

    final worldX = chunkX + localX;
    final worldY = chunkY + localY;
    
    // Seed diferente para overlay (sumamos 1)
    final tileSeed = seed ^ (worldX * 73856093) ^ (worldY * 19349663) + 1;
    final rand = Random(tileSeed);
    
    if (rand.nextDouble() > 0.35) return;

    final pos = iso.gridToScreen(worldX.toDouble(), worldY.toDouble());

    try {
      final spriteKey = 'grass_patch_${rand.nextInt(5)}';
      final image = Flame.images.fromCache(spriteKey);
      final sprite = Sprite(image);
      
      add(
        SpriteComponent(
          sprite: sprite,
          position: pos + _randomOffset(rand, 12),
          size: iso.tileSize * (0.8 + rand.nextDouble() * 0.4),
          angle: rand.nextDouble() * pi,
          anchor: Anchor.center,
          priority: worldY + worldX + 1,
        ),
      );
    } catch (e) {
      // Grass patch opcional
    }
  }

  Vector2 _randomOffset(Random rand, [double max = 8]) =>
      Vector2(rand.nextDouble() * max - max / 2,
              rand.nextDouble() * max - max / 2);

  double _randomScale(Random rand) => 1.2 + rand.nextDouble() * 0.4;
  
  void unloadSprites() {
    removeAll(children);
    isLoaded = false;
  }
}

class TerrainChunkRenderer extends Component {
  final List<List<TerrainTile>> map;
  final IsoGrid iso;
  final int chunkSize;
  final int seed; // AGREGADO: seed del terreno
  
  final Map<String, TerrainChunk> _loadedChunks = {};
  Vector2? _lastCameraPosition;
  final int viewDistance = 2; // Cuántos chunks cargar alrededor

  TerrainChunkRenderer({
    required this.map,
    required this.iso,
    required this.seed, // AGREGADO
    this.chunkSize = 16, // 16x16 tiles por chunk
  });

  @override
  Future<void> onLoad() async {
    // Cargar chunks iniciales alrededor del centro
    await updateVisibleChunks(Vector2.zero());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Obtener posición de la cámara del juego
    final cameraPos = _getCameraPosition();
    
    // Solo actualizar si la cámara se movió significativamente
    if (_lastCameraPosition == null || 
        cameraPos.distanceTo(_lastCameraPosition!) > chunkSize * iso.tileWidth / 3) {
      _lastCameraPosition = cameraPos.clone();
      updateVisibleChunks(cameraPos);
    }
  }

  Vector2 _getCameraPosition() {
    // Obtener la posición de la cámara desde el juego padre
    if (parent?.parent is ClashOfWarGame) {
      final game = parent!.parent as ClashOfWarGame;
      return -game.cameraOffset;
    }
    return Vector2.zero();
  }

  Future<void> updateVisibleChunks(Vector2 cameraPos) async {
    // Calcular qué chunk está en el centro de la pantalla
    final centerGridPos = iso.screenToGrid(cameraPos + iso.size / 2);
    if (centerGridPos == null) return;

    final centerChunkX = (centerGridPos.x / chunkSize).floor();
    final centerChunkY = (centerGridPos.y / chunkSize).floor();

    final chunksToLoad = <String>{};
    final chunksToKeep = <String>{};

    // Determinar qué chunks deben estar cargados
    for (int cy = centerChunkY - viewDistance; cy <= centerChunkY + viewDistance; cy++) {
      for (int cx = centerChunkX - viewDistance; cx <= centerChunkX + viewDistance; cx++) {
        if (_isValidChunk(cx, cy)) {
          final key = _getChunkKey(cx, cy);
          chunksToKeep.add(key);
          
          if (!_loadedChunks.containsKey(key)) {
            chunksToLoad.add(key);
          }
        }
      }
    }

    // Descargar chunks que ya no son visibles
    final chunksToUnload = _loadedChunks.keys
        .where((key) => !chunksToKeep.contains(key))
        .toList();
        
    for (final key in chunksToUnload) {
      final chunk = _loadedChunks.remove(key);
      chunk?.unloadSprites();
      chunk?.removeFromParent();
    }

    // Cargar nuevos chunks
    for (final key in chunksToLoad) {
      final coords = _parseChunkKey(key);
      await _loadChunk(coords.$1, coords.$2);
    }
  }

  Future<void> _loadChunk(int chunkX, int chunkY) async {
    final key = _getChunkKey(chunkX, chunkY);
    if (_loadedChunks.containsKey(key)) return;

    // Extraer tiles para este chunk
    final chunkTiles = <List<TerrainTile>>[];
    final startX = chunkX * chunkSize;
    final startY = chunkY * chunkSize;

    for (int y = 0; y < chunkSize; y++) {
      final row = <TerrainTile>[];
      for (int x = 0; x < chunkSize; x++) {
        final worldX = startX + x;
        final worldY = startY + y;
        
        if (worldX < map[0].length && worldY < map.length) {
          row.add(map[worldY][worldX]);
        }
      }
      if (row.isNotEmpty) {
        chunkTiles.add(row);
      }
    }

    if (chunkTiles.isEmpty) return;

    // Crear y cargar el chunk
    final chunk = TerrainChunk(
      chunkX: startX,
      chunkY: startY,
      tiles: chunkTiles,
      iso: iso,
      seed: seed, // PASAMOS EL SEED
    );

    add(chunk);
    _loadedChunks[key] = chunk;
    await chunk.loadSprites();
  }

  bool _isValidChunk(int chunkX, int chunkY) {
    final startX = chunkX * chunkSize;
    final startY = chunkY * chunkSize;
    
    return startX >= 0 && startY >= 0 &&
           startX < map[0].length && startY < map.length;
  }

  String _getChunkKey(int chunkX, int chunkY) => '$chunkX,$chunkY';
  
  (int, int) _parseChunkKey(String key) {
    final parts = key.split(',');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
  
  void forceReload() {
    for (final chunk in _loadedChunks.values) {
      chunk.unloadSprites();
      chunk.removeFromParent();
    }
    _loadedChunks.clear();
    _lastCameraPosition = null;
  }
}