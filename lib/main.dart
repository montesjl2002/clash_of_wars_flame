import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'game/clash_of_war_game.dart';
import 'ui/hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forzar orientación horizontal
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final game = ClashOfWarGame();
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(game: game),
    ),
  );
}

class GameScreen extends StatefulWidget {
  final ClashOfWarGame game;
  
  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Vector2? _lastTapPosition;
  bool _isScaling = false;
  int _pointerCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerDown: (event) {
              _pointerCount++;
              print('👆 Pointer down - Total pointers: $_pointerCount');
              
              if (_pointerCount == 1 && widget.game.currentPlacement != null) {
                // Guardar posición del tap para colocación
                _lastTapPosition = Vector2(event.position.dx, event.position.dy);
                print('📍 Tap guardado para colocación: $_lastTapPosition');
              }
            },
            onPointerUp: (event) {
              _pointerCount--;
              print('👇 Pointer up - Total pointers: $_pointerCount');
              
              // Solo procesar si fue un tap simple (no fue un gesto de escala/pan)
              if (_pointerCount == 0 && !_isScaling && _lastTapPosition != null) {
                if (widget.game.currentPlacement != null) {
                  print('🎯 Tap detectado - Intentando colocar edificio');
                  final position = _lastTapPosition!;
                  _lastTapPosition = null;
                  
                  // Llamar al método completo del juego
                  widget.game.handlePointerUp(position);
                }
              }
              
              if (_pointerCount == 0) {
                _isScaling = false;
              }
            },
            onPointerMove: (event) {
              // Si hay movimiento, marcar como gesture de escala/pan
              if (_pointerCount > 0) {
                _isScaling = true;
              }
            },
            child: GestureDetector(
              // Pan/Zoom gestures
              onScaleStart: (details) {
                print('🎮 onScaleStart');
                widget.game.handleZoomStart();
              },
              onScaleUpdate: (details) {
                // Zoom con 2 dedos
                if (details.scale != 1.0) {
                  widget.game.handleCameraZoom(
                    details.scale,
                    Vector2(
                      details.focalPoint.dx,
                      details.focalPoint.dy,
                    ),
                  );
                }
                
                // Pan con 1 o más dedos O mover edificio en colocación
                if (details.focalPointDelta.dx.abs() > 1 || details.focalPointDelta.dy.abs() > 1) {
                  if (widget.game.currentPlacement == null) {
                    // Mover cámara
                    widget.game.handleCameraPan(Vector2(
                      details.focalPointDelta.dx,
                      details.focalPointDelta.dy,
                    ));
                  } else {
                    // Mover preview del edificio
                    final pos = Vector2(
                      details.focalPoint.dx,
                      details.focalPoint.dy,
                    );
                    widget.game.handlePointerMove(pos);
                  }
                }
              },
              onScaleEnd: (details) {
                print('🎮 onScaleEnd');
              },
              
              child: GameWidget<ClashOfWarGame>(
                game: widget.game,
              ),
            ),
          ),
          HudOverlay(game: widget.game),
        ],
      ),
    );
  }
}