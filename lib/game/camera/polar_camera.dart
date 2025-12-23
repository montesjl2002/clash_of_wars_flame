import 'dart:math';
import 'dart:ui';
import '../core/game_constants.dart';
import '../core/polar_position.dart';

/* Cámara para visualización de mundo circular */
class PolarCamera {
  PolarPosition position;
  double zoom;
  double rotation;
  
  Size _viewportSize = Size.zero;
  
  PolarCamera()
      : position = PolarPosition(0, 0),
        zoom = GameConstants.initialZoom,
        rotation = 0;
  
  /* Actualiza el tamaño del viewport */
  void updateViewport(Size size) {
    _viewportSize = size;
  }
  
  /* Convierte posición mundial a posición de pantalla */
  Offset worldToScreen(PolarPosition worldPos) {
    final worldCart = worldPos.toCartesian();
    
    final rotatedX = worldCart.dx * cos(-rotation) - worldCart.dy * sin(-rotation);
    final rotatedY = worldCart.dx * sin(-rotation) + worldCart.dy * cos(-rotation);
    
    final cameraCart = position.toCartesian();
    final relativeX = rotatedX - cameraCart.dx;
    final relativeY = rotatedY - cameraCart.dy;
    
    final screenX = _viewportSize.width / 2 + relativeX * zoom;
    final screenY = _viewportSize.height / 2 + relativeY * zoom;
    
    return Offset(screenX, screenY);
  }
  
  /* Convierte posición de pantalla a posición mundial */
  PolarPosition screenToWorld(Offset screenPos) {
    final relativeX = (screenPos.dx - _viewportSize.width / 2) / zoom;
    final relativeY = (screenPos.dy - _viewportSize.height / 2) / zoom;
    
    final cameraCart = position.toCartesian();
    final worldX = relativeX + cameraCart.dx;
    final worldY = relativeY + cameraCart.dy;
    
    final rotatedX = worldX * cos(rotation) - worldY * sin(rotation);
    final rotatedY = worldX * sin(rotation) + worldY * cos(rotation);
    
    return PolarPosition.fromCartesian(rotatedX, rotatedY);
  }
  
  /* Mueve la cámara */
  void pan(double dx, double dy, double dt) {
    final speed = GameConstants.panSpeed * dt / zoom;
    
    final rotatedDx = dx * cos(rotation) - dy * sin(rotation);
    final rotatedDy = dx * sin(rotation) + dy * cos(rotation);
    
    final currentCart = position.toCartesian();
    final newX = currentCart.dx + rotatedDx * speed;
    final newY = currentCart.dy + rotatedDy * speed;
    
    position = PolarPosition.fromCartesian(newX, newY);
    
    if (position.radius > GameConstants.worldRadius) {
      position.radius = GameConstants.worldRadius;
    }
  }
  
  /* Ajusta el zoom */
  void adjustZoom(double delta) {
    zoom += delta * GameConstants.zoomSpeed;
    zoom = zoom.clamp(GameConstants.minZoom, GameConstants.maxZoom);
  }
  
  /* Rota la cámara */
  void rotate(double delta, double dt) {
    rotation += delta * GameConstants.rotationSpeed * dt;
  }
  
  /* Centra la cámara en una posición */
  void focusOn(PolarPosition target) {
    position = target.copy();
  }
  
  /* Obtiene el tamaño del viewport */
  Size get viewportSize => _viewportSize;
}