import 'building_component.dart';
import '../core/game_constants.dart';
import '../core/polar_position.dart';

/* Centro urbano - edificio principal */
class TownCenter extends BuildingComponent {
  TownCenter({
    required String id,
    required int owner,
    required PolarPosition polarPosition,
  }) : super(
          id: id,
          owner: owner,
          polarPosition: polarPosition,
          type: BuildingType.townCenter,
          maxHP: GameConstants.townCenterHP,
        );

  /* Verifica si puede producir aldeanos */
  bool canProduceVillager(int food) {
    return food >= GameConstants.villagerCost;
  }
}
