import '../game/asset_loader.dart';

enum BuildingCategory {
  defensive,
  resource,
  army,
  decoration,
}

/// Información completa de un edificio
class BuildingInfo {
  final String key;           // ID único (debe coincidir con AssetLoader)
  final String name;          // Nombre visible
  final String description;   // Descripción del edificio
  final int gridWidth;        // Ancho en tiles (para la clase Building)
  final int gridHeight;       // Alto en tiles (para la clase Building)
  final int cost;             // Costo en oro
  final int maxQuantity;      // Cantidad máxima permitida (-1 = ilimitado)
  final BuildingCategory category;

  BuildingInfo({
    required this.key,
    required this.name,
    required this.description,
    required this.gridWidth,
    required this.gridHeight,
    required this.cost,
    this.maxQuantity = -1,
    required this.category,
  });

  String get sizeLabel => '${gridWidth}x$gridHeight';
  bool get hasLimit => maxQuantity > 0;
  
  // Validación: verifica que el asset exista en AssetLoader
  bool get hasValidAsset => AssetLoader.hasAsset(key);
}

/// Base de datos centralizada de todos los edificios del juego
class BuildingsDatabase {
  static final List<BuildingInfo> defensiveBuildings = [
    BuildingInfo(
      key: 'archer_tower',
      name: 'Torre Avanzada',
      description: 'Dispara flechas a enemigos terrestres',
      gridWidth: 1,
      gridHeight: 1,
      cost: 200,
      maxQuantity: 10,
      category: BuildingCategory.defensive,
    ),
    /*BuildingInfo(
      key: 'cannon',
      name: 'Cañón',
      description: 'Ataque potente pero lento',
      gridWidth: 1,
      gridHeight: 1,
      cost: 180,
      maxQuantity: 8,
      category: BuildingCategory.defensive,
    ),
    BuildingInfo(
      key: 'wizard_tower',
      name: 'Torre de Mago',
      description: 'Daño en área con magia',
      gridWidth: 1,
      gridHeight: 1,
      cost: 250,
      maxQuantity: 6,
      category: BuildingCategory.defensive,
    ),
    BuildingInfo(
      key: 'air_defense',
      name: 'Defensa Aérea',
      description: 'Especializada en ataques aéreos',
      gridWidth: 1,
      gridHeight: 1,
      cost: 300,
      maxQuantity: 4,
      category: BuildingCategory.defensive,
    ),
    BuildingInfo(
      key: 'fortress',
      name: 'Fortaleza',
      description: 'Defensa pesada con gran resistencia',
      gridWidth: 2,
      gridHeight: 2,
      cost: 500,
      maxQuantity: 3,
      category: BuildingCategory.defensive,
    ),
    BuildingInfo(
      key: 'sea_defense',
      name: 'Defensa Marítima',
      description: 'Protege las costas de ataques navales',
      gridWidth: 1,
      gridHeight: 1,
      cost: 350,
      maxQuantity: 5,
      category: BuildingCategory.defensive,
    ),*/
  ];

  static final List<BuildingInfo> resourceBuildings = [
    BuildingInfo(
      key: 'townhall',
      name: 'Ayuntamiento',
      description: 'Centro de tu aldea. ¡Solo puedes tener uno!',
      gridWidth: 2,
      gridHeight: 2,
      cost: 0,
      maxQuantity: 1,
      category: BuildingCategory.resource,
    ),
    BuildingInfo(
      key: 'gold_mine',
      name: 'Mina de Oro',
      description: 'Genera oro con el tiempo',
      gridWidth: 1,
      gridHeight: 1,
      cost: 150,
      maxQuantity: 6,
      category: BuildingCategory.resource,
    ),
    /*BuildingInfo(
      key: 'elixir_extractor',
      name: 'Extractor de Elixir',
      description: 'Extrae elixir del subsuelo',
      gridWidth: 1,
      gridHeight: 1,
      cost: 150,
      maxQuantity: 6,
      category: BuildingCategory.resource,
    ),
    BuildingInfo(
      key: 'gold_storage',
      name: 'Almacén de Oro',
      description: 'Guarda tu oro de forma segura',
      gridWidth: 1,
      gridHeight: 1,
      cost: 100,
      maxQuantity: 4,
      category: BuildingCategory.resource,
    ),
    BuildingInfo(
      key: 'elixir_storage',
      name: 'Almacén de Elixir',
      description: 'Almacena elixir adicional',
      gridWidth: 1,
      gridHeight: 1,
      cost: 100,
      maxQuantity: 4,
      category: BuildingCategory.resource,
    ),*/
  ];

  static final List<BuildingInfo> armyBuildings = [
    BuildingInfo(
      key: 'barracks',
      name: 'Cuartel',
      description: 'Entrena tropas terrestres',
      gridWidth: 1,
      gridHeight: 1,
      cost: 200,
      maxQuantity: 4,
      category: BuildingCategory.army,
    ),
    BuildingInfo(
      key: 'mechanical_workshop',
      name: 'Taller',
      description: 'Entrena tropas moviles',
      gridWidth: 1,
      gridHeight: 1,
      cost: 250,
      maxQuantity: 4,
      category: BuildingCategory.army,
    ),
    BuildingInfo(
      key: 'army_camp',
      name: 'Campamento',
      description: 'Aloja tus tropas entrenadas',
      gridWidth: 2,
      gridHeight: 2,
      cost: 150,
      maxQuantity: 4,
      category: BuildingCategory.army,
    ),
    /*BuildingInfo(
      key: 'laboratory',
      name: 'Laboratorio',
      description: 'Mejora tus tropas',
      gridWidth: 1,
      gridHeight: 1,
      cost: 300,
      maxQuantity: 1,
      category: BuildingCategory.army,
    ),
    BuildingInfo(
      key: 'spell_factory',
      name: 'Fábrica de Hechizos',
      description: 'Crea hechizos poderosos',
      gridWidth: 1,
      gridHeight: 1,
      cost: 350,
      maxQuantity: 1,
      category: BuildingCategory.army,
    ),*/
  ];

  static final List<BuildingInfo> decorations = [
    BuildingInfo(
      key: 'flag',
      name: 'Bandera',
      description: 'Muestra tu emblema',
      gridWidth: 1,
      gridHeight: 1,
      cost: 50,
      maxQuantity: -1,  // Ilimitadas
      category: BuildingCategory.decoration,
    ),
    BuildingInfo(
      key: 'statue',
      name: 'Estatua',
      description: 'Decoración prestigiosa',
      gridWidth: 1,
      gridHeight: 1,
      cost: 100,
      maxQuantity: -1,
      category: BuildingCategory.decoration,
    ),
    BuildingInfo(
      key: 'tree',
      name: 'Árbol',
      description: 'Vegetación decorativa',
      gridWidth: 1,
      gridHeight: 1,
      cost: 25,
      maxQuantity: -1,
      category: BuildingCategory.decoration,
    ),
    BuildingInfo(
      key: 'fountain',
      name: 'Fuente',
      description: 'Hermosa fuente decorativa',
      gridWidth: 1,
      gridHeight: 1,
      cost: 150,
      maxQuantity: -1,
      category: BuildingCategory.decoration,
    ),
  ];
  
  /// Obtiene todos los edificios de una categoría
  static List<BuildingInfo> getBuildingsByCategory(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.defensive: 
        return defensiveBuildings;
      case BuildingCategory.resource:
        return resourceBuildings;
      case BuildingCategory.army: 
        return armyBuildings;
      case BuildingCategory.decoration: 
        return decorations;
    }
  }

  /// Obtiene un edificio por su key
  static BuildingInfo? getBuildingByKey(String key) {
    final allBuildings = getAllBuildings();
    try {
      return allBuildings.firstWhere((b) => b.key == key);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todos los edificios
  static List<BuildingInfo> getAllBuildings() {
    return [
      ...defensiveBuildings,
      ...resourceBuildings,
      ...armyBuildings,
      ...decorations,
    ];
  }
  
  /// Valida que todos los edificios tengan assets cargados
  static List<String> getMissingAssets() {
    final missing = <String>[];
    for (final building in getAllBuildings()) {
      if (!building.hasValidAsset) {
        missing.add(building.key);
      }
    }
    return missing;
  }
}