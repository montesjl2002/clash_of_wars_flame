import 'package:flame/game.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../managers/gold_mine_manager.dart';
import 'asset_loader.dart';
import 'iso_grid.dart';
import 'placement_component.dart';
import 'building.dart';
import '../data/building_data.dart';
import '../managers/building_manager.dart';

class ClashOfWarGame extends FlameGame {
  late IsoGrid isoGrid;
  late BuildingManager buildingManager;
  late GoldMineManager goldMineManager;
  
  String? selectedBuildingKey;
  BuildingInfo? selectedBuildingInfo;
  PlacementComponent? currentPlacement;
  
  Function()? onBuildingPlaced;
  Function(int gold)? onGoldChanged;
  Function(String? mapId)? onMapChanged;
  Function(bool hasMap)? onMapStatusChanged; // NUEVO: notificar si hay mapa
  
  int currentGold = 0;
  
  Vector2 cameraOffset = Vector2.zero();
  double cameraZoom = 1.0;
  final double minZoom = 0.5;
  final double maxZoom = 2.5;
  double _baseZoom = 1.0;

  ClashOfWarGame() {
    isoGrid = IsoGrid(
      tileWidth: 100,
      tileHeight: 50,
      cols: 100,
      rows: 100,
      seed: null,
    );
    buildingManager = BuildingManager();
    goldMineManager = GoldMineManager();
  }

  @override
  Future<void> onLoad() async {
    await AssetLoader.loadAll();
    add(isoGrid);
    
    // Verificar si hay un mapa válido
    final hasValidMap = isoGrid.terrain.hasValidMap();
    onMapStatusChanged?.call(hasValidMap);
    
    if (hasValidMap) {
      // Solo cargar progreso si hay un mapa válido
      await _loadGameState();
      goldMineManager.startProduction();
    } else {
      // Sin mapa válido: dar oro inicial pero no cargar edificios
      currentGold = 1000;
      await saveGold();
      onGoldChanged?.call(currentGold);
    }
    
    _notifyMapChanged();
  }
  
  @override
  void onRemove() {
    goldMineManager.dispose();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    isoGrid.size = canvasSize;
    isoGrid.position = Vector2.zero();
  }

  // ========================================================================
  // CARGA Y GUARDADO DEL ESTADO DEL JUEGO
  // ========================================================================

  Future<void> _loadGameState() async {
    await _loadGold();
    await _loadSavedBuildings();
    
    // Dar oro inicial si es primera vez
    if (currentGold == 0 && buildingManager.getBuildingCount('gold_mine') == 0) {
      currentGold = 1000;
      await saveGold();
      onGoldChanged?.call(currentGold);
    }
  }

  Future<void> _loadSavedBuildings() async {
    final buildingsData = await buildingManager.loadProgress();
    
    for (final data in buildingsData) {
      final key = data['key'] as String;
      final gx = data['gx'] as int;
      final gy = data['gy'] as int;
      final width = data['gridWidth'] as int;
      final height = data['gridHeight'] as int;
      
      isoGrid.markOccupied(gx, gy, width, height);
      
      final building = Building(
        key, gx, gy, isoGrid, 
        gridWidth: width, 
        gridHeight: height
      );
      
      await building.onLoad();
      add(building);
      buildingManager.addBuilding(building);
      
      if (building.isGoldMine()) {
        goldMineManager.registerGoldMine(building);
      }
    }
    
    onBuildingPlaced?.call();
  }

  Future<void> _loadGold() async {
    final prefs = await SharedPreferences.getInstance();
    currentGold = prefs.getInt('player_gold') ?? 0;
  }
  
  Future<void> saveGold() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_gold', currentGold);
  }

  // ========================================================================
  // SISTEMA DE CONSTRUCCIÓN
  // ========================================================================

  Future<void> selectBuildingFromInfo(BuildingInfo info) async {
    if (!buildingManager.canPlaceBuilding(info.key)) return;
    if (currentGold < info.cost) return;
    
    cancelPlacement();
    selectedBuildingKey = info.key;
    selectedBuildingInfo = info;
    
    currentPlacement = await PlacementComponent.create(
      isoGrid,
      info.key,
      buildingWidth: info.gridWidth,
      buildingHeight: info.gridHeight,
    );
    add(currentPlacement!);
  }

  Future<void> selectBuilding(String key) async {
    final buildingInfo = BuildingsDatabase.getBuildingByKey(key);
    if (buildingInfo != null) {
      await selectBuildingFromInfo(buildingInfo);
    }
  }

  void cancelPlacement() {
    selectedBuildingKey = null;
    selectedBuildingInfo = null;
    currentPlacement?.removeFromParent();
    currentPlacement = null;
  }

  // ========================================================================
  // SISTEMA DE CÁMARA
  // ========================================================================

  void handleCameraPan(Vector2 delta) {
    if (currentPlacement == null) {
      cameraOffset += delta / cameraZoom;
    }
  }

  void handleZoomStart() {
    _baseZoom = cameraZoom;
  }

  void handleCameraZoom(double scale, Vector2 focalPoint) {
    final oldZoom = cameraZoom;
    cameraZoom = (_baseZoom * scale).clamp(minZoom, maxZoom);
    
    if (cameraZoom != oldZoom) {
      final screenCenter = size / 2;
      final offsetToFocal = (focalPoint - screenCenter) / oldZoom;
      final zoomDiff = 1 / cameraZoom - 1 / oldZoom;
      cameraOffset += offsetToFocal * zoomDiff * oldZoom;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(cameraZoom);
    canvas.translate(-size.x / 2 + cameraOffset.x, -size.y / 2 + cameraOffset.y);
    super.render(canvas);
    canvas.restore();
  }

  // ========================================================================
  // MANEJO DE INPUT
  // ========================================================================

  void handlePointerMove(Vector2 position) {
    if (currentPlacement != null) {
      final worldPos = screenToWorld(position);
      currentPlacement!.updatePosition(worldPos);
    }
  }

  void handlePointerUp(Vector2 position) {
    if (currentPlacement != null) {
      final worldPos = screenToWorld(position);
      currentPlacement!.updatePosition(worldPos);
      
      if (currentPlacement!.tryPlace()) {
        currentPlacement = null;
        selectedBuildingKey = null;
        selectedBuildingInfo = null;
      }
    }
  }

  Vector2 screenToWorld(Vector2 screenPos) {
    final centerOffset = screenPos - size / 2;
    final zoomedOffset = centerOffset / cameraZoom;
    final worldOffset = zoomedOffset - cameraOffset;
    return worldOffset + size / 2;
  }

  // ========================================================================
  // SISTEMA DE ORO
  // ========================================================================

  void collectGoldFromMine(Building mine) {
    final collected = goldMineManager.collectGold(mine);
    if (collected > 0) {
      currentGold += collected;
      saveGold();
      onGoldChanged?.call(currentGold);
    }
  }
  
  int getTotalMinedGold() => goldMineManager.getTotalAccumulatedGold();

  // ========================================================================
  // CARGAR MAPA DESDE EDITOR
  // ========================================================================
  
  Future<void> loadMapFromEditor(List<List<int>> mapData, String mapId) async {
    await _clearGameState();
    await isoGrid.loadMapFromEditor(mapData, mapId);
    await _resetGame();
    _notifyMapChanged();
    
    // Notificar que ahora SÍ hay un mapa válido
    onMapStatusChanged?.call(true);
  }

  // ========================================================================
  // UTILIDADES
  // ========================================================================

  int getBuildingCount(String buildingKey) =>
      buildingManager.getBuildingCount(buildingKey);
  
  bool canPlaceMoreBuildings(String buildingKey) =>
      buildingManager.canPlaceBuilding(buildingKey);

  String? getCurrentMapId() => isoGrid.getCurrentMapId();
  bool isUsingEditorMap() => isoGrid.isUsingEditorMap();
  bool hasValidMap() => isoGrid.terrain.hasValidMap();

  void _notifyMapChanged() {
    final mapId = isoGrid.getCurrentMapId();
    onMapChanged?.call(mapId);
  }

  Future<void> _clearGameState() async {
    // Remover edificios
    final buildingsToRemove = children.whereType<Building>().toList();
    for (final building in buildingsToRemove) {
      building.removeFromParent();
    }
    
    buildingManager.clearAll();
    goldMineManager.dispose();
    goldMineManager = GoldMineManager();
  }
  
  Future<void> _resetGame() async {
    currentGold = 1000;
    await saveGold();
    onGoldChanged?.call(currentGold);
    
    goldMineManager.startProduction();
    onBuildingPlaced?.call();
  }
}