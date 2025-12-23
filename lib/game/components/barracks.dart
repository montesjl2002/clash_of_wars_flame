import 'building_component.dart';
import '../core/game_constants.dart';
import '../core/polar_position.dart';

/* Cuartel - produce unidades militares */
class Barracks extends BuildingComponent {
  Barracks({
    required String id,
    required int owner,
    required PolarPosition polarPosition,
  }) : super(
          id: id,
          owner: owner,
          polarPosition: polarPosition,
          type: BuildingType.barracks,
          maxHP: GameConstants.barracksHP,
        );

  /* Verifica si puede producir infantería */
  bool canProduceInfantry(int food, int wood) {
    return food >= GameConstants.infantryCostFood &&
        wood >= GameConstants.infantryCostWood;
  }

  /* Verifica si puede producir arqueros */
  bool canProduceArcher(int food, int wood) {
    return food >= GameConstants.archerCostFood &&
        wood >= GameConstants.archerCostWood;
  }
}
