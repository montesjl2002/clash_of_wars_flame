import '../components/unit_component.dart';
import '../components/building_component.dart';
import '../core/game_constants.dart';

/* Sistema que gestiona las colas de producción */
class ProductionSystem {
  final Map<String, ProductionQueue> _queues = {};
  
  /* Añade un edificio al sistema de producción */
  void registerBuilding(BuildingComponent building) {
    if (!_queues.containsKey(building.id)) {
      _queues[building.id] = ProductionQueue();
    }
  }
  
  /* Encola producción de aldeano */
  bool queueVillager(BuildingComponent building, int owner) {
    if (building.type != BuildingType.townCenter) return false;
    
    final queue = _queues[building.id];
    if (queue == null) return false;
    
    queue.add(ProductionItem(
      type: UnitType.villager,
      totalTime: GameConstants.villagerProductionTime,
      owner: owner,
    ));
    
    return true;
  }
  
  /* Encola producción de infantería */
  bool queueInfantry(BuildingComponent building, int owner) {
    if (building.type != BuildingType.barracks) return false;
    
    final queue = _queues[building.id];
    if (queue == null) return false;
    
    queue.add(ProductionItem(
      type: UnitType.infantry,
      totalTime: GameConstants.infantryProductionTime,
      owner: owner,
    ));
    
    return true;
  }
  
  /* Encola producción de arquero */
  bool queueArcher(BuildingComponent building, int owner) {
    if (building.type != BuildingType.barracks) return false;
    
    final queue = _queues[building.id];
    if (queue == null) return false;
    
    queue.add(ProductionItem(
      type: UnitType.archer,
      totalTime: GameConstants.archerProductionTime,
      owner: owner,
    ));
    
    return true;
  }
  
  /* Actualiza todas las colas de producción */
  void update(double dt) {
    for (final queue in _queues.values) {
      queue.update(dt);
    }
  }
  
  /* Obtiene la cola de un edificio */
  ProductionQueue? getQueue(String buildingId) {
    return _queues[buildingId];
  }
  
  /* Obtiene unidades completadas */
  List<CompletedUnit> getCompletedUnits() {
    final completed = <CompletedUnit>[];
    
    for (final entry in _queues.entries) {
      final buildingId = entry.key;
      final queue = entry.value;
      
      while (queue.hasCompleted) {
        final item = queue.popCompleted();
        if (item != null) {
          completed.add(CompletedUnit(
            type: item.type,
            owner: item.owner,
            buildingId: buildingId,
          ));
        }
      }
    }
    
    return completed;
  }
  
  /* Limpia el sistema */
  void clear() {
    _queues.clear();
  }
}

/* Cola de producción de un edificio */
class ProductionQueue {
  final List<ProductionItem> _queue = [];
  
  /* Añade un ítem a la cola */
  void add(ProductionItem item) {
    _queue.add(item);
  }
  
  /* Actualiza la producción */
  void update(double dt) {
    if (_queue.isEmpty) return;
    
    final current = _queue.first;
    current.progress += dt;
    
    if (current.progress >= current.totalTime) {
      current.completed = true;
    }
  }
  
  /* Verifica si hay ítems completados */
  bool get hasCompleted => _queue.isNotEmpty && _queue.first.completed;
  
  /* Obtiene el progreso actual */
  double get currentProgress {
    if (_queue.isEmpty) return 0;
    return _queue.first.progress / _queue.first.totalTime;
  }
  
  /* Obtiene el tipo actual en producción */
  UnitType? get currentType {
    if (_queue.isEmpty) return null;
    return _queue.first.type;
  }
  
  /* Extrae un ítem completado */
  ProductionItem? popCompleted() {
    if (hasCompleted) {
      return _queue.removeAt(0);
    }
    return null;
  }
  
  /* Obtiene el tamaño de la cola */
  int get length => _queue.length;
  
  /* Cancela la producción actual */
  void cancelCurrent() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0);
    }
  }
}

/* Ítem en cola de producción */
class ProductionItem {
  final UnitType type;
  final double totalTime;
  final int owner;
  
  double progress = 0;
  bool completed = false;
  
  ProductionItem({
    required this.type,
    required this.totalTime,
    required this.owner,
  });
}

/* Unidad completada */
class CompletedUnit {
  final UnitType type;
  final int owner;
  final String buildingId;
  
  CompletedUnit({
    required this.type,
    required this.owner,
    required this.buildingId,
  });
}