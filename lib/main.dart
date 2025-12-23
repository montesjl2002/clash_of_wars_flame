import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/rts_empire_of_war.dart';

/* Punto de entrada principal del juego */
void main() {
  runApp(const RTSApp());
}

/* Widget raíz de la aplicación */
class RTSApp extends StatelessWidget {
  const RTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RTS Empire of War',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: RTSEmpireOfWar(),
        ),
      ),
    );
  }
}