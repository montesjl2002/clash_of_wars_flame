import '../components/unit_component.dart';
import '../components/villager_component.dart';
import '../components/building_component.dart';
import '../components/resource_node.dart';
import '../core/polar_position.dart';
import '../core/polar_math.dart';
import '../core/game_constants.dart';

/* Sistema que gestiona todas las entidades del mundo */
class WorldSystem {
  final List<UnitComponent> units = [];
  final List<BuildingComponent> buildings = [];
  final List<ResourceNode> resources = [];

  int _unitIdCounter = 0;
  int _buildingIdCounter = 0;
  int _resourceIdCounter = 0;

  /* Inicializa el mundo del juego */
  void initialize() {
    _generateResources();
  }

  /* Genera nodos de recursos en el mapa */
  void _generateResources() {
    final numRings = GameConstants.numRings;
    final maxRadius = GameConstants.worldRadius;

    for (int ring = 2; ring < numRings; ring++) {
      final minRadius = (ring * maxRadius) / numRings;
      final maxRingRadius = ((ring + 1) * maxRadius) / numRings;

      final numResources = 8 + ring * 3;

      for (int i = 0; i < numResources; i++) {
        final pos = PolarMath.randomInRing(minRadius, maxRingRadius);
        final type = i % 3 == 0
            ? ResourceType.food
            : i % 3 == 1
                ? ResourceType.wood
                : ResourceType.stone;

        final maxAmount = type == ResourceType.food
            ? GameConstants.foodNodeAmount
            : type == ResourceType.wood
                ? GameConstants.woodNodeAmount
                : GameConstants.stoneNodeAmount;

        resources.add(ResourceNode(
          id: 'resource_${_resourceIdCounter++}',
          type: type,
          polarPosition: pos,
          maxAmount: maxAmount,
        ));
      }
    }
  }

  /* Crea un aldeano */
  VillagerComponent createVillager(int owner, PolarPosition polarPosition) {
    final villager = VillagerComponent(
      id: 'unit_${_unitIdCounter++}',
      owner: owner,
      polarPosition: polarPosition,
    );
    units.add(villager);
    return villager;
  }

  /* Crea infantería */
  UnitComponent createInfantry(int owner, PolarPosition polarPosition) {
    final infantry = UnitComponent(
      id: 'unit_${_unitIdCounter++}',
      type: UnitType.infantry,
      owner: owner,
      polarPosition: polarPosition,
      maxHP: GameConstants.infantryHP,
    );
    units.add(infantry);
    return infantry;
  }

  /* Crea arquero */
  UnitComponent createArcher(int owner, PolarPosition polarPosition) {
    final archer = UnitComponent(
      id: 'unit_${_unitIdCounter++}',
      type: UnitType.archer,
      owner: owner,
      polarPosition: polarPosition,
      maxHP: GameConstants.archerHP,
    );
    units.add(archer);
    return archer;
  }

  /* Crea un edificio */
  BuildingComponent createBuilding(
      BuildingType type, int owner, PolarPosition polarPosition) {
    final building = BuildingComponent(
      id: 'building_${_buildingIdCounter++}',
      type: type,
      owner: owner,
      polarPosition: polarPosition,
      maxHP: _getBuildingMaxHP(type),
    );
    buildings.add(building);
    return building;
  }

  /* HP máximo según tipo de edificio */
  int _getBuildingMaxHP(BuildingType type) {
    switch (type) {
      case BuildingType.townCenter:
        return GameConstants.townCenterHP;
      case BuildingType.house:
        return GameConstants.houseHP;
      case BuildingType.barracks:
        return GameConstants.barracksHP;
      case BuildingType.tower:
        return GameConstants.towerHP;
    }
  }

  /* Actualiza todas las entidades */
  void update(double dt) {
    for (final unit in units) {
      unit.update(dt);
    }

    units.removeWhere((unit) => unit.state == UnitState.dead);
    buildings.removeWhere((building) => building.isDestroyed);
    resources.removeWhere((resource) => resource.isDepleted);
  }

  /* Obtiene unidades del jugador */
  List<UnitComponent> getPlayerUnits(int owner) =>
      units.where((u) => u.owner == owner && u.isAlive).toList();

  /* Obtiene edificios del jugador */
  List<BuildingComponent> getPlayerBuildings(int owner) =>
      buildings.where((b) => b.owner == owner && !b.isDestroyed).toList();

  /* Encuentra recursos cercanos */
  ResourceNode? findNearestResource(PolarPosition position, ResourceType type) {
    ResourceNode? nearest;
    double minDist = double.infinity;

    for (final resource in resources) {
      if (resource.type == type && !resource.isDepleted) {
        final dist = position.distanceTo(resource.polarPosition);
        if (dist < minDist) {
          minDist = dist;
          nearest = resource;
        }
      }
    }

    return nearest;
  }

  /* Encuentra enemigos cercanos */
  List<UnitComponent> findEnemiesInRange(
      PolarPosition position, int owner, double range) {
    return units
        .where((u) =>
            u.owner != owner &&
            u.isAlive &&
            position.distanceTo(u.polarPosition) <= range)
        .toList();
  }

  /* Limpia el mundo */
  void clear() {
    units.clear();
    buildings.clear();
    resources.clear();
    _unitIdCounter = 0;
    _buildingIdCounter = 0;
    _resourceIdCounter = 0;
  }
}
