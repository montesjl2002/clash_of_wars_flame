import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TrainingQueue extends Component {
  final List<Map<String, dynamic>> queue = [];
  double timer = 0.0;

  void enqueue(String type, {double time = 3.0}) {
    queue.add({'type': type, 'time': time});
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (queue.isEmpty) return;
    timer += dt;
    final current = queue.first;
    if (timer >= (current['time'] as double)) {
      // spawn troop (for prototype, just print)
      debugPrint('Trained: ${current['type']}');
      queue.removeAt(0);
      timer = 0.0;
    }
  }
}
