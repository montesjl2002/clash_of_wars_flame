import 'package:flame/flame.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../terrain/terrain_type.dart';

class AssetLoader {
  static final Map<String, String> _assets = {
    // ===== EDIFICIOS DE RECURSOS =====
    'townhall': 'assets/buildings/townhall.png',
    'gold_mine': 'assets/buildings/mine.png',
    
    // ===== EDIFICIOS DEFENSIVOS =====
    'archer_tower': 'assets/buildings/tower.png',
    
    // ===== EDIFICIOS DE EJÉRCITO =====
    'barracks': 'assets/buildings/barracks.png',
    'army_camp': 'assets/buildings/army_camp.png',
    'mechanical_workshop': 'assets/buildings/mechanical_workshop.png',
    
    // ===== DECORACIONES =====
    'tree': 'assets/buildings/tree.png',
    
    // ===== TEXTURAS DE TERRENO =====
    // Agua profunda
    'water_deep': 'assets/tiles/water/water_deep.png',
    
    // Agua media
    'water_mid': 'assets/tiles/water/water_mid.png',
    
    // Costas
    'shore_0': 'assets/tiles/water/shore_0.png',
    'shore_1': 'assets/tiles/water/shore_1.png',
    'shore_2': 'assets/tiles/water/shore_2.png',
    
    // Arena
    'sand_0': 'assets/tiles/sand/sand_0.png',
    'sand_1': 'assets/tiles/sand/sand_1.png',
    'sand_2': 'assets/tiles/sand/sand_2.png',
    'sand_3': 'assets/tiles/sand/sand_3.png',
    
    // Pasto base
    'grass_0': 'assets/tiles/grass/grass_0.png',
    'grass_1': 'assets/tiles/grass/grass_1.png',
    'grass_2': 'assets/tiles/grass/grass_2.png',
    'grass_3': 'assets/tiles/grass/grass_3.png',
    'grass_4': 'assets/tiles/grass/grass_4.png',
    
    // Parches de pasto (overlay)
    'grass_patch_0': 'assets/tiles/grass/grass_patch_0.png',
    'grass_patch_1': 'assets/tiles/grass/grass_patch_1.png',
    'grass_patch_2': 'assets/tiles/grass/grass_patch_2.png',
    'grass_patch_3': 'assets/tiles/grass/grass_patch_3.png',
    'grass_patch_4': 'assets/tiles/grass/grass_patch_4.png',
  };

  static Future<void> loadAll() async {
    for (final entry in _assets.entries) {
      try {
        final data = await rootBundle.load(entry.value);
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        Flame.images.add(entry.key, frame.image);
      } catch (e) {
        print('Warning: Could not load asset ${entry.key} at ${entry.value}');
      }
    }
  }

  static String pathFor(String key) => key;
  
  // Verifica si un asset existe
  static bool hasAsset(String key) => _assets.containsKey(key);
  
  // Obtiene la ruta de un asset
  static String? getPath(String key) => _assets[key];
  
  // Obtiene imagen cargada desde cache
  static ui.Image? getImage(String key) {
    try {
      return Flame.images.fromCache(key);
    } catch (e) {
      return null;
    }
  }
  
  // ========================================================================
  // NUEVOS MÉTODOS PARA EL EDITOR DE MAPAS
  // ========================================================================
  
  /// Obtiene una textura de ejemplo para un tipo de terreno (para el pincel)
  static ui.Image? getTerrainPreviewImage(TerrainType type) {
    try {
      switch (type) {
        case TerrainType.deepWater:
          return Flame.images.fromCache('water_deep');
        case TerrainType.midWater:
          return Flame.images.fromCache('water_mid');
        case TerrainType.shore:
          return Flame.images.fromCache('shore_0');
        case TerrainType.sand:
          return Flame.images.fromCache('sand_0');
        case TerrainType.grass:
          return Flame.images.fromCache('grass_0');
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Genera un patrón de textura para usar en el editor
  static Future<ui.Image?> generateEditorTexture(
    TerrainType type,
    int size,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    
    // Colores base para cada terreno
    paint.color = _getTerrainEditorColor(type);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );
    
    // Agregar variación visual
    paint.color = paint.color.withOpacity(0.3);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        ui.Offset(
          (i * size / 5).toDouble(),
          (i * size / 5).toDouble(),
        ),
        size / 8,
        paint,
      );
    }
    
    final picture = recorder.endRecording();
    return await picture.toImage(size, size);
  }
  
  static ui.Color _getTerrainEditorColor(TerrainType type) {
    switch (type) {
      case TerrainType.deepWater:
        return const ui.Color(0xFF1a4d7a);
      case TerrainType.midWater:
        return const ui.Color(0xFF2e75b6);
      case TerrainType.shore:
        return const ui.Color(0xFF5fa3d0);
      case TerrainType.sand:
        return const ui.Color(0xFFf4d58d);
      case TerrainType.grass:
        return const ui.Color(0xFF7cb342);
    }
  }
}