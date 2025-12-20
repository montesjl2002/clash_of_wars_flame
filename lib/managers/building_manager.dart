import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/building_data.dart';
import '../game/building.dart';

class BuildingManager {
  final Map<String, int> _placedBuildings = {};
  final List<Building> _buildings = [];

  bool canPlaceBuilding(String buildingKey) {
    final info = BuildingsDatabase.getBuildingByKey(buildingKey);
    if (info == null) return false;
    if (!info.hasLimit) return true;
    
    final currentCount = _placedBuildings[buildingKey] ?? 0;
    return currentCount < info.maxQuantity;
  }

  int getBuildingCount(String buildingKey) {
    return _placedBuildings[buildingKey] ?? 0;
  }

  Map<String, int> getAllCounts() => Map.from(_placedBuildings);
  
  void addBuilding(Building building) {
    _buildings.add(building);
    final count = _placedBuildings[building.keyName] ?? 0;
    _placedBuildings[building.keyName] = count + 1;
  }

  void removeBuilding(Building building) {
    _buildings.remove(building);
    final count = _placedBuildings[building.keyName] ?? 0;
    if (count > 0) {
      _placedBuildings[building.keyName] = count - 1;
      if (_placedBuildings[building.keyName] == 0) {
        _placedBuildings.remove(building.keyName);
      }
    }
  }

  bool isCellOccupied(int x, int y, {Building? exclude}) {
    for (final building in _buildings) {
      if (exclude != null && building == exclude) continue;
      if (building.occupiesCell(x, y)) return true;
    }
    return false;
  }

  bool isAreaFree(int gx, int gy, int width, int height, {Building? exclude}) {
    for (int dx = 0; dx < width; dx++) {
      for (int dy = 0; dy < height; dy++) {
        if (isCellOccupied(gx + dx, gy + dy, exclude: exclude)) return false;
      }
    }
    return true;
  }

  Building? getBuildingAt(int x, int y) {
    for (final building in _buildings) {
      if (building.occupiesCell(x, y)) return building;
    }
    return null;
  }

  List<Building> getAllBuildings() => List.from(_buildings);

  Future<void> saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buildingsData = _buildings.map((building) => {
        'key': building.keyName,
        'gx': building.gx,
        'gy': building.gy,
        'gridWidth': building.gridWidth,
        'gridHeight': building.gridHeight,
      }).toList();
      
      await prefs.setString('placed_buildings', jsonEncode(buildingsData));
    } catch (e) {
      // Error silencioso
    }
  }

  Future<List<Map<String, dynamic>>> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('placed_buildings');
      if (jsonData == null) return [];
      
      clearAll();
      final List<dynamic> decodedData = jsonDecode(jsonData);
      return decodedData.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  void clearAll() {
    _buildings.clear();
    _placedBuildings.clear();
  }

  Future<void> clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('placed_buildings');
      clearAll();
    } catch (e) {
      // Error silencioso
    }
  }
}