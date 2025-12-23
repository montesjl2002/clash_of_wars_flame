import '../components/unit_component.dart';
import '../components/building_component.dart';
import '../core/game_constants.dart';

/* Sistema que gestiona el combate */
class CombatSystem {
  double _updateTimer = 0;

  /* Actualiza el sistema de combate */
  void update(
    double dt,
    List<UnitComponent> units,
    List<BuildingComponent> buildings,
  ) {
    _updateTimer += dt;

    if (_updateTimer >= GameConstants.combatCheckInterval) {
      _updateTimer = 0;
      _processCombat(units, buildings);
    }
  }

  /* Procesa el combate entre unidades */
  void _processCombat(
    List<UnitComponent> units,
    List<BuildingComponent> buildings,
  ) {
    for (final unit in units) {
      if (!unit.isAlive) continue;

      if (unit.state == UnitState.attacking && unit.attackTarget != null) {
        _processUnitAttack(unit);
      } else {
        _autoAcquireTarget(unit, units);
      }
    }

    _processTowerAttacks(buildings, units);
  }

  /* Procesa el ataque de una unidad */
  void _processUnitAttack(UnitComponent unit) {
    if (unit.attackCooldown > 0) return;

    final target = unit.attackTarget;
    if (target == null) return;

    double range;
    double attackSpeed;
    int damage;

    switch (unit.type) {
      case UnitType.infantry:
        range = GameConstants.infantryAttackRange;
        attackSpeed = GameConstants.infantryAttackSpeed;
        damage = GameConstants.infantryDamage;
        break;
      case UnitType.archer:
        range = GameConstants.archerAttackRange;
        attackSpeed = GameConstants.archerAttackSpeed;
        damage = GameConstants.archerDamage;
        break;
      default:
        return;
    }

    // Calcula distancia usando Vector2
    final distance = unit.position.distanceTo(target.position);

    // Si está fuera de rango → moverse hacia el objetivo
    if (distance > range) {
      final direction = (target.position - unit.position).normalized();
      unit.position += direction * unit.speed * GameConstants.combatCheckInterval;

      // Sincroniza la posición lógica (polarPosition)
      unit.syncPolarPosition();
      return;
    }

    // Ataca
    unit.attackCooldown = attackSpeed;

    if (target is UnitComponent) {
      if (!target.isAlive) {
        unit.attackTarget = null;
        unit.state = UnitState.idle;
        return;
      }
      target.takeDamage(damage);
    } else if (target is BuildingComponent) {
      if (target.isDestroyed) {
        unit.attackTarget = null;
        unit.state = UnitState.idle;
        return;
      }
      target.takeDamage(damage);
    }
  }

  /* Adquiere automáticamente un objetivo enemigo */
  void _autoAcquireTarget(
    UnitComponent unit,
    List<UnitComponent> units,
  ) {
    if (unit.type == UnitType.villager) return;

    UnitComponent? nearestEnemy;
    double minDist = GameConstants.unitVisionRange;

    for (final other in units) {
      if (other.owner != unit.owner && other.isAlive) {
        final dist = unit.position.distanceTo(other.position);
        if (dist < minDist) {
          minDist = dist;
          nearestEnemy = other;
        }
      }
    }

    if (nearestEnemy != null) {
      unit.attackMove(nearestEnemy);
    }
  }

  /* Procesa ataques de torres */
  void _processTowerAttacks(
    List<BuildingComponent> buildings,
    List<UnitComponent> units,
  ) {
    for (final building in buildings) {
      if (building.type != BuildingType.tower || building.isDestroyed) continue;

      UnitComponent? target;
      double minDist = GameConstants.towerAttackRange;

      for (final unit in units) {
        if (unit.owner != building.owner && unit.isAlive) {
          final dist = building.position.distanceTo(unit.position);
          if (dist < minDist) {
            minDist = dist;
            target = unit;
          }
        }
      }

      if (target != null) {
        target.takeDamage(GameConstants.towerDamage);
      }
    }
  }
}
