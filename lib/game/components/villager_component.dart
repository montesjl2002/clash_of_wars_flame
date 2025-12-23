import '../core/polar_position.dart';
import 'unit_component.dart';
import '../core/game_constants.dart';
import 'resource_node.dart';

/* Aldeano - unidad básica de recolección */
class VillagerComponent extends UnitComponent {
  int carriedFood = 0;
  int carriedWood = 0;
  int carriedStone = 0;

  double gatherTimer = 0;

  VillagerComponent({
    required String id,
    required int owner,
    required PolarPosition polarPosition,
  }) : super(
          id: id,
          owner: owner,
          polarPosition: polarPosition,
          type: UnitType.villager,
          maxHP: GameConstants.villagerHP,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (state == UnitState.gathering && gatherTarget != null) {
      _processGathering(dt);
    }
  }

  /* Procesa la recolección de recursos */
  void _processGathering(double dt) {
    if (gatherTarget is! ResourceNode) return;

    final resource = gatherTarget as ResourceNode;

    // Distancia usando Vector2 (Flame)
    final distance = position.distanceTo(resource.position);

    if (distance > GameConstants.gatherRange) {
      // Moverse hacia el recurso
      final direction = (resource.position - position).normalized();
      position += direction * speed * dt;

      // Sincroniza posición lógica
      polarPosition = PolarPosition.fromCartesian(
        position.x,
        position.y,
      );
      return;
    }

    // Recolectar
    gatherTimer += dt;
    if (gatherTimer >= 1.0) {
      gatherTimer = 0;

      final gathered =
          resource.gather(GameConstants.gatherRate.toInt());

      switch (resource.type) {
        case ResourceType.food:
          carriedFood += gathered;
          break;
        case ResourceType.wood:
          carriedWood += gathered;
          break;
        case ResourceType.stone:
          carriedStone += gathered;
          break;
      }

      // Capacidad máxima
      if (carriedFood + carriedWood + carriedStone >= 10) {
        state = UnitState.idle;
      }
    }
  }

  /* Deposita recursos recolectados */
  int depositResources() {
    final total = carriedFood + carriedWood + carriedStone;
    carriedFood = 0;
    carriedWood = 0;
    carriedStone = 0;
    return total;
  }

  /* Verifica si tiene recursos */
  bool get hasResources =>
      carriedFood > 0 || carriedWood > 0 || carriedStone > 0;
}
