import 'dart:ui';

/* Constantes globales del juego */
class GameConstants {
  /* Tamaño del mundo circular */
  static const double worldRadius = 2000.0;
  
  /* Configuración de cámara */
  static const double minZoom = 0.3;
  static const double maxZoom = 2.0;
  static const double initialZoom = 0.8;
  static const double zoomSpeed = 0.1;
  static const double panSpeed = 300.0;
  static const double rotationSpeed = 1.0;
  
  /* Anillos del mapa */
  static const int numRings = 6;
  static const int sectorsPerRing = 12;
  
  /* Eras del juego */
  static const int maxEra = 3;
  static const int eraAdvanceCost = 500;
  
  /* Economía */
  static const int startingFood = 200;
  static const int startingWood = 200;
  static const int startingStone = 100;
  static const int startingPopulation = 3;
  static const int maxPopulation = 50;
  static const int housePopulationBonus = 5;
  
  /* Recolección */
  static const double gatherRate = 5.0;
  static const double gatherRange = 50.0;
  
  /* Unidades */
  static const double unitRadius = 15.0;
  static const double unitSpeed = 80.0;
  static const double unitVisionRange = 200.0;
  
  /* Aldeanos */
  static const int villagerCost = 50;
  static const double villagerProductionTime = 5.0;
  static const int villagerHP = 25;
  
  /* Infantería */
  static const int infantryCostFood = 60;
  static const int infantryCostWood = 20;
  static const double infantryProductionTime = 8.0;
  static const int infantryHP = 60;
  static const int infantryDamage = 10;
  static const double infantryAttackRange = 40.0;
  static const double infantryAttackSpeed = 1.5;
  
  /* Arqueros */
  static const int archerCostFood = 50;
  static const int archerCostWood = 40;
  static const double archerProductionTime = 10.0;
  static const int archerHP = 40;
  static const int archerDamage = 8;
  static const double archerAttackRange = 150.0;
  static const double archerAttackSpeed = 2.0;
  
  /* Edificios */
  static const double buildingRadius = 40.0;
  
  /* Centro urbano */
  static const int townCenterHP = 500;
  static const int townCenterCost = 0;
  
  /* Casas */
  static const int houseCostWood = 30;
  static const int houseHP = 100;
  
  /* Cuarteles */
  static const int barracksCostWood = 150;
  static const int barracksCostStone = 50;
  static const int barracksHP = 300;
  
  /* Torres */
  static const int towerCostWood = 100;
  static const int towerCostStone = 100;
  static const int towerHP = 400;
  static const int towerDamage = 15;
  static const double towerAttackRange = 250.0;
  static const double towerAttackSpeed = 1.0;
  
  /* Recursos */
  static const double resourceNodeRadius = 30.0;
  static const int foodNodeAmount = 500;
  static const int woodNodeAmount = 400;
  static const int stoneNodeAmount = 300;
  
  /* Combate */
  static const double combatCheckInterval = 0.5;
  
  /* IA */
  static const double aiUpdateInterval = 2.0;
  static const double aiAttackThreshold = 0.6;
  static const int aiMinArmySize = 8;
  
  /* Colores */
  static const Color playerColor = Color(0xFF2196F3);
  static const Color aiColor = Color(0xFFE53935);
  static const Color neutralColor = Color(0xFF808080);
  static const Color foodColor = Color(0xFF4CAF50);
  static const Color woodColor = Color(0xFF795548);
  static const Color stoneColor = Color(0xFF9E9E9E);
  static const Color selectionColor = Color(0xFFFFEB3B);
}