import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../terrain/terrain_chunk_render.dart';
import 'terrain_generator.dart';

class IsoGrid extends PositionComponent {
  final double tileWidth;
  final double tileHeight;
  final int cols;
  final int rows;

  late List<List<bool>> occupiedCells;
  late TerrainGenerator terrain;
  TerrainChunkRenderer? chunkRenderer;

  Vector2 get tileSize => Vector2(tileWidth, tileHeight);

  IsoGrid({
    required this.tileWidth,
    required this.tileHeight,
    required this.cols,
    required this.rows,
    int? seed,
  }) {
    occupiedCells = List.generate(rows, (_) => List.filled(cols, false));
    terrain = TerrainGenerator.empty(width: cols, height: rows, seed: seed);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadPersistedMap();
  }

  // ========================================================================
  // SISTEMA DE PERSISTENCIA - OPTIMIZADO
  // ========================================================================

  Future<void> _loadPersistedMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString('current_map_data');
      final mapId = prefs.getString('current_map_id');

      if (mapJson != null && mapId != null) {
        final mapData = _decodeMapData(mapJson);
        terrain = TerrainGenerator.fromEditor(
          width: cols,
          height: rows,
          mapData: mapData,
          mapId: mapId,
        );
        debugPrint('✅ Mapa cargado automáticamente: $mapId');
      } else {
        // Si no hay mapa guardado, crear mapa vacío de pasto
        await _createDefaultMap();
      }
    } catch (e) {
      debugPrint('⚠️ Error cargando mapa: $e');
      await _createDefaultMap();
    }

    await _renderTerrain();
  }

  Future<void> _createDefaultMap() async {
    terrain = TerrainGenerator.empty(width: cols, height: rows);
    await _persistCurrentMap();
    debugPrint('🆕 Mapa vacío creado');
  }

  Future<void> _persistCurrentMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = _encodeMapData();

      await prefs.setString('current_map_data', mapData);
      await prefs.setString('current_map_id', terrain.currentMapId ?? 'empty');

      debugPrint('💾 Mapa persistido: ${terrain.currentMapId}');
    } catch (e) {
      debugPrint('❌ Error persistiendo mapa: $e');
    }
  }

  // ========================================================================
  // CODIFICACIÓN/DECODIFICACIÓN - REUTILIZABLE
  // ========================================================================

  String _encodeMapData() {
    return jsonEncode(
      terrain.tiles
          .map((row) => row.map((tile) => tile.type.index).toList())
          .toList(),
    );
  }

  List<List<int>> _decodeMapData(String mapJson) {
    final List<dynamic> decoded = jsonDecode(mapJson);
    return decoded
        .map((row) => (row as List).map((type) => type as int).toList())
        .toList();
  }

  // ========================================================================
  // CARGAR MAPA DESDE EDITOR
  // ========================================================================

  Future<void> loadMapFromEditor(List<List<int>> mapData, String mapId) async {
    terrain = TerrainGenerator.fromEditor(
      width: cols,
      height: rows,
      mapData: mapData,
      mapId: mapId,
    );

    occupiedCells = List.generate(rows, (_) => List.filled(cols, false));
    await _renderTerrain();
    await _persistCurrentMap();

    debugPrint('✅ Mapa del editor cargado: $mapId');
  }

  // ========================================================================
  // RENDERIZADO - OPTIMIZADO
  // ========================================================================

  Future<void> _renderTerrain() async {
    // Remover renderer anterior si existe
    chunkRenderer?.forceReload();
    chunkRenderer?.removeFromParent();

    // Crear nuevo renderer con chunks
    chunkRenderer = TerrainChunkRenderer(
      map: terrain.tiles,
      iso: this,
      seed: terrain.seed,
      chunkSize: 16,
    );

    await chunkRenderer!.onLoad();
    add(chunkRenderer!);
  }

  // ========================================================================
  // CONVERSIÓN DE COORDENADAS - OPTIMIZADO
  // ========================================================================

  Vector2 gridToScreen(double x, double y) {
    final sx = (x - y) * (tileWidth / 2);
    final sy = (x + y) * (tileHeight / 2);
    return Vector2(sx + size.x / 2, sy + size.y / 3);
  }

  Vector2? screenToGrid(Vector2 point) {
    final cx = point.x - size.x / 2;
    final cy = point.y - size.y / 3;

    final xf = (cx / (tileWidth / 2) + cy / (tileHeight / 2)) / 2;
    final yf = (cy / (tileHeight / 2) - cx / (tileWidth / 2)) / 2;

    final ix = xf.round();
    final iy = yf.round();

    if (!_isValidPosition(ix, iy)) return null;
    return Vector2(ix.toDouble(), iy.toDouble());
  }

  // ========================================================================
  // VALIDACIÓN DE CONSTRUCCIÓN - OPTIMIZADO
  // ========================================================================

  bool canPlaceBuilding(int gx, int gy, int width, int height) {
    if (!_isValidBuildingArea(gx, gy, width, height)) return false;

    for (int y = gy; y < gy + height; y++) {
      for (int x = gx; x < gx + width; x++) {
        if (occupiedCells[y][x] || !terrain.canBuildAt(x, y)) {
          return false;
        }
      }
    }
    return true;
  }

  void markOccupied(int gx, int gy, int width, int height) {
    _modifyOccupancy(gx, gy, width, height, true);
  }

  void markFree(int gx, int gy, int width, int height) {
    _modifyOccupancy(gx, gy, width, height, false);
  }

  void _modifyOccupancy(int gx, int gy, int width, int height, bool occupied) {
    for (int y = gy; y < gy + height; y++) {
      for (int x = gx; x < gx + width; x++) {
        if (_isValidPosition(x, y)) {
          occupiedCells[y][x] = occupied;
        }
      }
    }
  }

  // ========================================================================
  // UTILIDADES - REUTILIZABLES
  // ========================================================================

  bool _isValidPosition(int x, int y) {
    return x >= 0 && x < cols && y >= 0 && y < rows;
  }

  bool _isValidBuildingArea(int gx, int gy, int width, int height) {
    return gx >= 0 && gy >= 0 && gx + width <= cols && gy + height <= rows;
  }

  String? getCurrentMapId() => terrain.currentMapId;
  bool isUsingEditorMap() => terrain.currentMapId != null;

  @override
  void render(Canvas canvas) {
    // El terreno se renderiza mediante TerrainChunkRenderer
  }
}
