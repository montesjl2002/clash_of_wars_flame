import 'dart:math';
import 'dart:ui';

/* Representa una posición en coordenadas polares */
class PolarPosition {
  double radius;
  double angle;
  
  PolarPosition(this.radius, this.angle);
  
  /* Crea desde coordenadas cartesianas */
  factory PolarPosition.fromCartesian(double x, double y) {
    final radius = sqrt(x * x + y * y);
    final angle = atan2(y, x);
    return PolarPosition(radius, angle);
  }
  
  /* Convierte a coordenadas cartesianas */
  Offset toCartesian() {
    return Offset(
      radius * cos(angle),
      radius * sin(angle),
    );
  }
  
  /* Copia la posición */
  PolarPosition copy() {
    return PolarPosition(radius, angle);
  }
  
  /* Calcula distancia a otra posición polar */
  double distanceTo(PolarPosition other) {
    final c1 = toCartesian();
    final c2 = other.toCartesian();
    final dx = c2.dx - c1.dx;
    final dy = c2.dy - c1.dy;
    return sqrt(dx * dx + dy * dy);
  }
  
  /* Normaliza el ángulo entre -PI y PI */
  void normalizeAngle() {
    while (angle > pi) angle -= 2 * pi;
    while (angle < -pi) angle += 2 * pi;
  }
  
  /* Mueve hacia otra posición */
  void moveTowards(PolarPosition target, double distance) {
    final targetCart = target.toCartesian();
    final currentCart = toCartesian();
    
    final dx = targetCart.dx - currentCart.dx;
    final dy = targetCart.dy - currentCart.dy;
    final dist = sqrt(dx * dx + dy * dy);
    
    if (dist > 0) {
      final ratio = min(distance / dist, 1.0);
      final newX = currentCart.dx + dx * ratio;
      final newY = currentCart.dy + dy * ratio;
      
      radius = sqrt(newX * newX + newY * newY);
      angle = atan2(newY, newX);
    }
  }
  
  @override
  String toString() => 'PolarPos(r: ${radius.toStringAsFixed(1)}, θ: ${angle.toStringAsFixed(2)})';
}