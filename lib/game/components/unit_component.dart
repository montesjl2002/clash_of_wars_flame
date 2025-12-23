import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/polar_position.dart';
import '../core/game_constants.dart';

/* Tipos de unidades */
enum UnitType { villager, infantry, archer }

/* Estado de la unidad */
enum UnitState { idle, moving, gathering, attacking, dead }

/* Componente base para todas las unidades */
class UnitComponent extends PositionComponent {
  final String id;
  final UnitType type;
  final int owner;

  PolarPosition polarPosition;
  UnitState state = UnitState.idle;

  int maxHP;
  int currentHP;
  double speed;
  double visionRange;

  PolarPosition? moveTarget;
  PositionComponent? attackTarget;
  PositionComponent? gatherTarget;

  bool selected = false;
  double attackCooldown = 0;

  UnitComponent({
    required this.id,
    required this.type,
    required this.owner,
    required this.polarPosition,
    required this.maxHP,
  })  : currentHP = maxHP,
        speed = GameConstants.unitSpeed,
        visionRange = GameConstants.unitVisionRange {
    // Tamaño
    size = Vector2.all(GameConstants.unitRadius * 2);

    // Ancla centrada
    anchor = Anchor.center;

    // Posición visual inicial
    position = _polarToVector2(polarPosition);
  }

  /* Convierte PolarPosition a Vector2 */
  static Vector2 _polarToVector2(PolarPosition polar) {
    final cartesian = polar.toCartesian();
    return Vector2(cartesian.dx, cartesian.dy);
  }

  /* Actualiza la unidad */
  @override
  void update(double dt) {
    super.update(dt);

    if (state == UnitState.dead) return;

    if (attackCooldown > 0) {
      attackCooldown -= dt;
    }

    switch (state) {
      case UnitState.moving:
        _updateMovement(dt);
        break;
      case UnitState.attacking:
        _updateAttack(dt);
        break;
      case UnitState.gathering:
        _updateGathering(dt);
        break;
      default:
        break;
    }
  }

  /* Actualiza el movimiento */
  void _updateMovement(double dt) {
    if (moveTarget == null) {
      state = UnitState.idle;
      return;
    }

    final targetVec = _polarToVector2(moveTarget!);
    final distance = position.distanceTo(targetVec);

    if (distance < 5.0) {
      position.setFrom(targetVec);
      polarPosition = moveTarget!;
      moveTarget = null;
      state = UnitState.idle;
      return;
    }

    // Movimiento visual
    final direction = (targetVec - position).normalized();
    position += direction * speed * dt;

    // Sincroniza posición lógica
    syncPolarPosition();
  }

  /* Actualiza el ataque */
  void _updateAttack(double dt) {
    if (attackTarget == null || !attackTarget!.isMounted) {
      state = UnitState.idle;
      return;
    }
  }

  /* Actualiza la recolección */
  void _updateGathering(double dt) {
    if (gatherTarget == null || !gatherTarget!.isMounted) {
      state = UnitState.idle;
      return;
    }
  }

  /* Ordena mover a una posición */
  void moveTo(PolarPosition target) {
    moveTarget = target.copy();
    state = UnitState.moving;
    attackTarget = null;
    gatherTarget = null;
  }

  /* Ordena atacar a un objetivo */
  void attackMove(PositionComponent target) {
    attackTarget = target;
    state = UnitState.attacking;
    moveTarget = null;
    gatherTarget = null;
  }

  /* Ordena recolectar de un recurso */
  void gatherFrom(PositionComponent resource) {
    gatherTarget = resource;
    state = UnitState.gathering;
    moveTarget = null;
    attackTarget = null;
  }

  /* Recibe daño */
  void takeDamage(int damage) {
    currentHP -= damage;
    if (currentHP <= 0) {
      currentHP = 0;
      state = UnitState.dead;
      removeFromParent();
    }
  }

  /* Verifica si está viva */
  bool get isAlive => state != UnitState.dead;

  /* Color según el dueño */
  Color get ownerColor =>
      owner == 0 ? GameConstants.playerColor : GameConstants.aiColor;

  /* Render */
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (state == UnitState.dead) return;

    final center = size.toOffset() / 2;

    final paint = Paint()
      ..color = selected ? GameConstants.selectionColor : ownerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, GameConstants.unitRadius, paint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, GameConstants.unitRadius, borderPaint);

    _renderHpBar(canvas, center);
  }

  /* Barra de vida */
  void _renderHpBar(Canvas canvas, Offset center) {
    final hpBarWidth = GameConstants.unitRadius * 2;
    const hpBarHeight = 4.0;
    final hpPercent = currentHP / maxHP;

    final top = center.dy - GameConstants.unitRadius - 8;

    canvas.drawRect(
      Rect.fromLTWH(center.dx - hpBarWidth / 2, top, hpBarWidth, hpBarHeight),
      Paint()..color = Colors.red,
    );

    canvas.drawRect(
      Rect.fromLTWH(center.dx - hpBarWidth / 2, top, hpBarWidth * hpPercent, hpBarHeight),
      Paint()..color = Colors.green,
    );
  }

  /// Sincroniza la posición polar con la posición de Flame (Vector2)
  void syncPolarPosition() {
    polarPosition = PolarPosition.fromCartesian(position.x, position.y);
  }
}
