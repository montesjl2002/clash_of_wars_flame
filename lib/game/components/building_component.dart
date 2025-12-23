import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/polar_position.dart';
import '../core/game_constants.dart';

/* Tipos de edificios */
enum BuildingType { townCenter, house, barracks, tower }

/* Componente base para edificios */
class BuildingComponent extends PositionComponent {
  final String id;
  final BuildingType type;
  final int owner;

  PolarPosition polarPosition;

  int maxHP;
  int currentHP;
  bool selected = false;

  BuildingComponent({
    required this.id,
    required this.type,
    required this.owner,
    required this.polarPosition,
    required this.maxHP,
  }) : currentHP = maxHP {
    // Tamaño del componente
    size = Vector2.all(GameConstants.buildingRadius * 2);

    // Ancla centrada
    anchor = Anchor.center;

    // Posición en pantalla (desde polar)
    position = _polarToVector2(polarPosition);
  }

  /* Convierte PolarPosition a Vector2 */
  static Vector2 _polarToVector2(PolarPosition polar) {
    final cartesian = polar.toCartesian();
    return Vector2(cartesian.dx, cartesian.dy);
  }

  /* Recibe daño */
  void takeDamage(int damage) {
    currentHP -= damage;
    if (currentHP < 0) currentHP = 0;
  }

  /* Verifica si está destruido */
  bool get isDestroyed => currentHP <= 0;

  /* Color según el dueño */
  Color get ownerColor {
    return owner == 0
        ? GameConstants.playerColor
        : GameConstants.aiColor;
  }

  /* Render */
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size.toOffset() / 2;

    // Cuerpo del edificio
    final paint = Paint()
      ..color = selected ? GameConstants.selectionColor : ownerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      GameConstants.buildingRadius,
      paint,
    );

    // Borde
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      center,
      GameConstants.buildingRadius,
      borderPaint,
    );

    _renderHpBar(canvas, center);
    _renderTypeIndicator(canvas, center);
  }

  /* Barra de vida */
  void _renderHpBar(Canvas canvas, Offset center) {
    final hpBarWidth = GameConstants.buildingRadius * 2;
    const hpBarHeight = 6.0;
    final hpPercent = currentHP / maxHP;

    final bgPaint = Paint()..color = Colors.red;
    final fgPaint = Paint()..color = Colors.green;

    final top = center.dy - GameConstants.buildingRadius - 12;

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - hpBarWidth / 2,
        top,
        hpBarWidth,
        hpBarHeight,
      ),
      bgPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - hpBarWidth / 2,
        top,
        hpBarWidth * hpPercent,
        hpBarHeight,
      ),
      fgPaint,
    );
  }

  /* Indicador del tipo de edificio */
  void _renderTypeIndicator(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    switch (type) {
      case BuildingType.townCenter:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 20, height: 20),
          paint,
        );
        break;

      case BuildingType.house:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 15, height: 15),
          paint,
        );
        break;

      case BuildingType.barracks:
        final path = Path()
          ..moveTo(center.dx, center.dy - 10)
          ..lineTo(center.dx + 10, center.dy + 10)
          ..lineTo(center.dx - 10, center.dy + 10)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case BuildingType.tower:
        canvas.drawCircle(center, 8, paint);
        break;
    }
  }
}
