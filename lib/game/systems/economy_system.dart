import '../core/game_constants.dart';

/* Sistema que gestiona la economía del jugador */
class EconomySystem {
  final Map<int, PlayerEconomy> _economies = {};
  
  /* Inicializa la economía de un jugador */
  void initializePlayer(int owner) {
    _economies[owner] = PlayerEconomy(
      food: GameConstants.startingFood,
      wood: GameConstants.startingWood,
      stone: GameConstants.startingStone,
      population: GameConstants.startingPopulation,
      maxPopulation: GameConstants.maxPopulation,
    );
  }
  
  /* Obtiene la economía de un jugador */
  PlayerEconomy getEconomy(int owner) {
    return _economies[owner] ?? PlayerEconomy();
  }
  
  /* Añade recursos */
  void addResources(int owner, {int food = 0, int wood = 0, int stone = 0}) {
    final economy = _economies[owner];
    if (economy != null) {
      economy.food += food;
      economy.wood += wood;
      economy.stone += stone;
    }
  }
  
  /* Intenta consumir recursos */
  bool consumeResources(int owner, {int food = 0, int wood = 0, int stone = 0}) {
    final economy = _economies[owner];
    if (economy == null) return false;
    
    if (economy.food >= food &&
        economy.wood >= wood &&
        economy.stone >= stone) {
      economy.food -= food;
      economy.wood -= wood;
      economy.stone -= stone;
      return true;
    }
    
    return false;
  }
  
  /* Verifica si hay suficientes recursos */
  bool hasResources(int owner, {int food = 0, int wood = 0, int stone = 0}) {
    final economy = _economies[owner];
    if (economy == null) return false;
    
    return economy.food >= food &&
        economy.wood >= wood &&
        economy.stone >= stone;
  }
  
  /* Añade población */
  void addPopulation(int owner, int amount) {
    final economy = _economies[owner];
    if (economy != null) {
      economy.population += amount;
    }
  }
  
  /* Añade límite de población */
  void addPopulationCap(int owner, int amount) {
    final economy = _economies[owner];
    if (economy != null) {
      economy.maxPopulation += amount;
    }
  }
  
  /* Verifica si hay espacio de población */
  bool hasPopulationSpace(int owner, int required) {
    final economy = _economies[owner];
    if (economy == null) return false;
    
    return economy.population + required <= economy.maxPopulation;
  }
  
  /* Limpia el sistema */
  void clear() {
    _economies.clear();
  }
}

/* Datos de economía de un jugador */
class PlayerEconomy {
  int food;
  int wood;
  int stone;
  int population;
  int maxPopulation;
  
  PlayerEconomy({
    this.food = 0,
    this.wood = 0,
    this.stone = 0,
    this.population = 0,
    this.maxPopulation = 50,
  });
  
  @override
  String toString() {
    return 'Economy(F:$food W:$wood S:$stone P:$population/$maxPopulation)';
  }
}