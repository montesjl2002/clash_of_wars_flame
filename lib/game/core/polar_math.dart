import 'dart:math';
import 'polar_position.dart';

/* Utilidades matemáticas para coordenadas polares */
class PolarMath {
  static final Random _random = Random();
  
  /* Genera posición polar aleatoria dentro de un anillo */
  static PolarPosition randomInRing(double minRadius, double maxRadius) {
    final radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
    final angle = _random.nextDouble() * 2 * pi;
    return PolarPosition(radius, angle);
  }
  
  /* Genera posición polar en un sector específico */
  static PolarPosition randomInSector(double minRadius, double maxRadius, double startAngle, double endAngle) {
    final radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
    final angle = startAngle + _random.nextDouble() * (endAngle - startAngle);
    return PolarPosition(radius, angle);
  }
  
  /* Calcula el anillo en el que está una posición */
  static int getRing(double radius, int numRings, double maxRadius) {
    final ringSize = maxRadius / numRings;
    return min((radius / ringSize).floor(), numRings - 1);
  }
  
  /* Calcula el sector en el que está un ángulo */
  static int getSector(double angle, int numSectors) {
    final normalizedAngle = (angle + pi) % (2 * pi);
    final sectorSize = (2 * pi) / numSectors;
    return (normalizedAngle / sectorSize).floor() % numSectors;
  }
  
  /* Interpola entre dos ángulos considerando el camino más corto */
  static double lerpAngle(double from, double to, double t) {
    var diff = to - from;
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;
    return from + diff * t;
  }
  
  /* Calcula dirección angular hacia un objetivo */
  static double angleToTarget(PolarPosition from, PolarPosition to) {
    final fromCart = from.toCartesian();
    final toCart = to.toCartesian();
    return atan2(toCart.dy - fromCart.dy, toCart.dx - fromCart.dx);
  }
  
  /* Verifica si un punto está dentro de un círculo */
  static bool isInCircle(PolarPosition point, PolarPosition center, double radius) {
    return point.distanceTo(center) <= radius;
  }
  
  /* Clampea un valor entre min y max */
  static double clamp(double value, double min, double max) {
    return value < min ? min : (value > max ? max : value);
  }
  
  /* Genera un ángulo aleatorio */
  static double randomAngle() {
    return _random.nextDouble() * 2 * pi - pi;
  }
  
  /* Genera un radio aleatorio */
  static double randomRadius(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}