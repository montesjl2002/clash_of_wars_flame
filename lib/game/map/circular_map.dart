import 'dart:ui';
import '../core/game_constants.dart';
import '../core/polar_position.dart';
import '../core/polar_math.dart';

/* Mapa circular del juego */
class CircularMap {
  final List<Ring> rings = [];
  
  CircularMap() {
    _initializeRings();
  }
  
  /* Inicializa los anillos del mapa */
  void _initializeRings() {
    final ringSize = GameConstants.worldRadius / GameConstants.numRings;
    
    for (int i = 0; i < GameConstants.numRings; i++) {
      final innerRadius = i * ringSize;
      final outerRadius = (i + 1) * ringSize;
      
      rings.add(Ring(
        index: i,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        sectors: GameConstants.sectorsPerRing,
      ));
    }
  }
  
  /* Obtiene el anillo en una posición */
  Ring? getRingAt(PolarPosition position) {
    final ringIndex = PolarMath.getRing(
      position.radius,
      GameConstants.numRings,
      GameConstants.worldRadius,
    );
    
    if (ringIndex >= 0 && ringIndex < rings.length) {
      return rings[ringIndex];
    }
    
    return null;
  }
  
  /* Obtiene el sector en una posición */
  int getSectorAt(PolarPosition position) {
    return PolarMath.getSector(position.angle, GameConstants.sectorsPerRing);
  }
}

/* Anillo del mapa */
class Ring {
  final int index;
  final double innerRadius;
  final double outerRadius;
  final int sectors;
  
  Ring({
    required this.index,
    required this.innerRadius,
    required this.outerRadius,
    required this.sectors,
  });
  
  /* Obtiene el color del anillo */
  Color get color {
    final intensity = 0.1 + (index / GameConstants.numRings) * 0.2;
    return Color.fromRGBO(
      (intensity * 255).toInt(),
      (intensity * 255).toInt(),
      (intensity * 255).toInt(),
      1.0,
    );
  }
}