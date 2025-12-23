import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/polar_position.dart';
import '../core/game_constants.dart';

/* Tipos de recursos */
enum ResourceType { food, wood, stone }

/* Nodo de recurso que se puede recolectar */
class ResourceNode extends PositionComponent {
  final String id;
  final ResourceType type;

  PolarPosition polarPosition;

  int amount;
  final int maxAmount;

  ResourceNode({
    required this.id,
    required this.type,
    required this.polarPosition,
    required this.maxAmount,
  }) : amount = maxAmount {
    // Tamaño
    size = Vector2.all(GameConstants.resourceNodeRadius * 2);

    // Ancla centrada
    anchor = Anchor.center;

    // Posición visual (desde polar)
    position = _polarToVector2(polarPosition);
  }

  /* Convierte PolarPosition a Vector2 */
  static Vector2 _polarToVector2(PolarPosition polar) {
    final cartesian = polar.toCartesian();
    return Vector2(cartesian.dx, cartesian.dy);
  }

  /* Recolecta recursos del nodo */
  int gather(int requested) {
    if (amount <= 0) return 0;

    final gathered = requested > amount ? amount : requested;
    amount -= gathered;
    return gathered;
  }

  /* Verifica si está agotado */
  bool get isDepleted => amount <= 0;

  /* Color según el tipo */
  Color get resourceColor {
    switch (type) {
      case ResourceType.food:
        return GameConstants.foodColor;
      case ResourceType.wood:
        return GameConstants.woodColor;
      case ResourceType.stone:
        return GameConstants.stoneColor;
    }
  }

  /* Render */
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (isDepleted) return;

    final center = size.toOffset() / 2;

    final paint = Paint()
      ..color = resourceColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      GameConstants.resourceNodeRadius,
      paint,
    );

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      center,
      GameConstants.resourceNodeRadius,
      borderPaint,
    );

    // Indicador de cantidad restante
    final amountPercent = amount / maxAmount;
    final innerRadius =
        GameConstants.resourceNodeRadius * amountPercent * 0.8;

    final innerPaint = Paint()
      ..color = resourceColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      innerRadius,
      innerPaint,
    );
  }
}
