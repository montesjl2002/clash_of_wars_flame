import 'dart:math';
import 'package:rts_empire_of_war/game/core/polar_position.dart';

import '../components/unit_component.dart';
import '../components/villager_component.dart';
import '../components/building_component.dart';
import '../components/resource_node.dart';
import '../core/game_constants.dart';
import 'world_system.dart';
import 'economy_system.dart';
import 'production_system.dart';

/* Sistema de IA para el jugador computadora */
class AISystem {
  final int aiOwner;
  final WorldSystem worldSystem;
  final EconomySystem economySystem;
  final ProductionSystem productionSystem;
  
  double _updateTimer = 0;
  AIState _state = AIState.economy;
  
  AISystem({
    required this.aiOwner,
    required this.worldSystem,
    required this.economySystem,
    required this.productionSystem,
  });
  
  /* Actualiza la IA */
  void update(double dt) {
    _updateTimer += dt;
    
    if (_updateTimer >= GameConstants.aiUpdateInterval) {
      _updateTimer = 0;
      _makeDecisions();
    }
  }
  
  /* Toma decisiones estratégicas */
  void _makeDecisions() {
    final economy = economySystem.getEconomy(aiOwner);
    final units = worldSystem.getPlayerUnits(aiOwner);
    final buildings = worldSystem.getPlayerBuildings(aiOwner);
    
    final villagers = units.whereType<VillagerComponent>().toList();
    final military = units.where((u) => u.type != UnitType.villager).toList();
    
    _manageVillagers(villagers, economy);
    _manageProduction(buildings, economy);
    _manageMilitary(military, units, buildings);
    
    _evaluateStrategy(economy, military);
  }
  
  /* Gestiona aldeanos */
  void _manageVillagers(List<VillagerComponent> villagers, PlayerEconomy economy) {
    for (final villager in villagers) {
      if (villager.state == UnitState.idle) {
        _assignVillagerTask(villager, economy);
      }
    }
  }
  
  /* Asigna tarea a un aldeano */
  void _assignVillagerTask(VillagerComponent villager, PlayerEconomy economy) {
    ResourceType? neededType;
    
    if (economy.food < 200) {
      neededType = ResourceType.food;
    } else if (economy.wood < 200) {
      neededType = ResourceType.wood;
    } else if (economy.stone < 100) {
      neededType = ResourceType.stone;
    } else {
      neededType = ResourceType.food;
    }
    
    final resource = worldSystem.findNearestResource(villager.position as PolarPosition, neededType);
    if (resource != null) {
      villager.gatherFrom(resource);
    }
  }
  
  /* Gestiona la producción */
  void _manageProduction(List<BuildingComponent> buildings, PlayerEconomy economy) {
    final townCenters = buildings.where((b) => b.type == BuildingType.townCenter).toList();
    final barracks = buildings.where((b) => b.type == BuildingType.barracks).toList();
    
    for (final tc in townCenters) {
      final queue = productionSystem.getQueue(tc.id);
      if (queue != null && queue.length < 2) {
        if (economy.food >= GameConstants.villagerCost &&
            economySystem.hasPopulationSpace(aiOwner, 1)) {
          if (economySystem.consumeResources(aiOwner, food: GameConstants.villagerCost)) {
            productionSystem.queueVillager(tc, aiOwner);
          }
        }
      }
    }
    
    for (final barrack in barracks) {
      final queue = productionSystem.getQueue(barrack.id);
      if (queue != null && queue.length < 3) {
        if (_state == AIState.military || _state == AIState.attack) {
          if (Random().nextBool()) {
            if (economySystem.hasResources(
                  aiOwner,
                  food: GameConstants.infantryCostFood,
                  wood: GameConstants.infantryCostWood,
                ) &&
                economySystem.hasPopulationSpace(aiOwner, 1)) {
              if (economySystem.consumeResources(
                aiOwner,
                food: GameConstants.infantryCostFood,
                wood: GameConstants.infantryCostWood,
              )) {
                productionSystem.queueInfantry(barrack, aiOwner);
              }
            }
          } else {
            if (economySystem.hasResources(
                  aiOwner,
                  food: GameConstants.archerCostFood,
                  wood: GameConstants.archerCostWood,
                ) &&
                economySystem.hasPopulationSpace(aiOwner, 1)) {
              if (economySystem.consumeResources(
                aiOwner,
                food: GameConstants.archerCostFood,
                wood: GameConstants.archerCostWood,
              )) {
                productionSystem.queueArcher(barrack, aiOwner);
              }
            }
          }
        }
      }
    }
  }
  
  /* Gestiona unidades militares */
  void _manageMilitary(
    List<UnitComponent> military,
    List<UnitComponent> allUnits,
    List<BuildingComponent> allBuildings,
  ) {
    if (_state != AIState.attack) return;
    
    final enemyBuildings = allBuildings.where((b) => b.owner != aiOwner).toList();
    if (enemyBuildings.isEmpty) return;
    
    final target = enemyBuildings.first;
    
    for (final unit in military) {
      if (unit.state == UnitState.idle) {
        unit.attackMove(target);
      }
    }
  }
  
  /* Evalúa y cambia estrategia */
  void _evaluateStrategy(PlayerEconomy economy, List<UnitComponent> military) {
    if (military.length >= GameConstants.aiMinArmySize &&
        economy.food > 300 &&
        economy.wood > 200) {
      _state = AIState.attack;
    } else if (military.length < GameConstants.aiMinArmySize ~/ 2) {
      _state = AIState.military;
    } else {
      _state = AIState.economy;
    }
  }
}

/* Estados de la IA */
enum AIState { economy, military, attack }