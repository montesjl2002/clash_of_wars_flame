import 'package:flame/components.dart';

class TerrainLayers extends Component {
  late final Component waterLayer;      // agua profunda / media
  late final Component shoreLayer;      // costa / espuma
  late final Component groundLayer;     // arena / pasto base
  late final Component detailLayer;     // grass_patch, manchas
  late final Component decorationLayer; // árboles, rocas, edificios

  @override
  Future<void> onLoad() async {
    waterLayer = Component();
    shoreLayer = Component();
    groundLayer = Component();
    detailLayer = Component();
    decorationLayer = Component();

    // Orden IMPORTANTE: se dibuja en este orden
    add(waterLayer);
    add(shoreLayer);
    add(groundLayer);
    add(detailLayer);
    add(decorationLayer);
  }
}
