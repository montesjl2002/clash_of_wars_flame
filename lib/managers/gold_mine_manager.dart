import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/building.dart';

class GoldMineManager {
  static const double goldPerMinute = 10.0;
  static const double maxGoldStorage = 5000.0;
  
  final List<Building> _goldMines = [];
  Timer? _productionTimer;
  
  void registerGoldMine(Building mine) {
    if (mine.isGoldMine() && !_goldMines.contains(mine)) {
      _goldMines.add(mine);
      _loadMineProgress(mine);
    }
  }
  
  void unregisterGoldMine(Building mine) {
    _goldMines.remove(mine);
  }
  
  void startProduction() {
    _productionTimer?.cancel();
    _productionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateProduction(),
    );
  }
  
  void stopProduction() {
    _productionTimer?.cancel();
    _saveMinesProgress();
  }
  
  void _updateProduction() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    for (final mine in _goldMines) {
      if (mine.lastCollectionTime == 0) {
        mine.lastCollectionTime = now;
      }
      
      final elapsedMinutes = (now - mine.lastCollectionTime) / 60.0;
      final produced = elapsedMinutes * goldPerMinute;
      
      mine.accumulatedGold = (mine.accumulatedGold + produced).clamp(0, maxGoldStorage);
      mine.lastCollectionTime = now;
    }
  }
  
  int collectGold(Building mine) {
    if (!mine.isGoldMine()) return 0;
    
    final collected = mine.accumulatedGold.floor();
    mine.accumulatedGold = 0;
    mine.lastCollectionTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    _saveMineProgress(mine);
    return collected;
  }
  
  int getTotalAccumulatedGold() {
    return _goldMines.fold(0, (sum, mine) => sum + mine.accumulatedGold.floor());
  }
  
  Future<void> _loadMineProgress(Building mine) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mine_${mine.gx}_${mine.gy}';
    
    mine.accumulatedGold = prefs.getDouble('${key}_gold') ?? 0.0;
    mine.lastCollectionTime = prefs.getDouble('${key}_time') ?? 
        DateTime.now().millisecondsSinceEpoch / 1000.0;
  }
  
  Future<void> _saveMineProgress(Building mine) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mine_${mine.gx}_${mine.gy}';
    
    await prefs.setDouble('${key}_gold', mine.accumulatedGold);
    await prefs.setDouble('${key}_time', mine.lastCollectionTime);
  }
  
  Future<void> _saveMinesProgress() async {
    for (final mine in _goldMines) {
      await _saveMineProgress(mine);
    }
  }
  
  void dispose() {
    stopProduction();
  }
}