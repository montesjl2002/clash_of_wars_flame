import 'package:vector_math/vector_math.dart';

import 'building_component.dart';
import 'unit_component.dart';
import '../core/game_constants.dart';
import '../core/polar_position.dart';

/* Torre - edificio defensivo */
class Tower extends BuildingComponent {
  double attackCooldown = 0;

  Tower({
    required String id,
    required int owner,
    required PolarPosition polarPosition,
  }) : super(
          id: id,
          owner: owner,
          polarPosition: polarPosition,
          type: BuildingType.tower,
          maxHP: GameConstants.towerHP,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (attackCooldown > 0) {
      attackCooldown -= dt;
    }
  }

  /* Ataca a una unidad enemiga */
  bool attack(UnitComponent target) {
    if (attackCooldown > 0) return false;

    // position ahora es Vector2 (PositionComponent)
    final distance = position.distanceTo(target.position as Vector2);

    if (distance > GameConstants.towerAttackRange) return false;

    target.takeDamage(GameConstants.towerDamage);
    attackCooldown = GameConstants.towerAttackSpeed;
    return true;
  }
}
