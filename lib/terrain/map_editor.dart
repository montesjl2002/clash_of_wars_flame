import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../terrain/terrain_type.dart';

class MapEditorScreen extends StatefulWidget {
  const MapEditorScreen({super.key});

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  static const int gridSize = 100;
  
  List<List<TerrainType>> map = List.generate(
    gridSize,
    (_) => List.filled(gridSize, TerrainType.deepWater),
  );
  
  TerrainType selectedTool = TerrainType.grass;
  int brushSize = 3;
  
  TransformationController transformationController = TransformationController();
  double cellSize = 8.0;
  bool isDrawing = false;
  String mapName = 'mi_mapa';
  
  List<String> savedMaps = [];
  
  @override
  void initState() {
    super.initState();
    _loadLastMap();
    _loadMapList();
  }
  
  // ========================================================================
  // CARGA Y GUARDADO - OPTIMIZADO
  // ========================================================================
  
  Future<void> _loadLastMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString('editor_map_data');
      final savedName = prefs.getString('editor_map_name');
      
      if (mapJson != null) {
        setState(() {
          map = _decodeMap(mapJson);
          mapName = savedName ?? 'mi_mapa';
        });
        debugPrint('✅ Mapa cargado: $mapName');
      }
    } catch (e) {
      debugPrint('Error cargando mapa: $e');
    }
  }
  
  Future<void> _loadMapList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapListJson = prefs.getString('saved_maps_list');
      
      if (mapListJson != null) {
        final List<dynamic> decoded = jsonDecode(mapListJson);
        setState(() {
          savedMaps = decoded.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando lista de mapas: $e');
    }
  }
  
  Future<void> _saveMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = _encodeMap(map);
      
      // Guardar mapa actual
      await prefs.setString('editor_map_data', mapData);
      await prefs.setString('editor_map_name', mapName);
      
      // Guardar en biblioteca de mapas
      final mapKey = 'map_$mapName';
      await prefs.setString(mapKey, mapData);
      
      // Actualizar lista de mapas guardados
      if (!savedMaps.contains(mapName)) {
        savedMaps.add(mapName);
        await prefs.setString('saved_maps_list', jsonEncode(savedMaps));
      }
      
      if (mounted) {
        _showSnackBar('✔ Mapa guardado: $mapName', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al guardar: $e', Colors.red);
      }
    }
  }
  
  Future<void> _loadMap(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapKey = 'map_$name';
      final mapJson = prefs.getString(mapKey);
      
      if (mapJson != null) {
        setState(() {
          map = _decodeMap(mapJson);
          mapName = name;
        });
        
        // Actualizar mapa actual
        await prefs.setString('editor_map_data', mapJson);
        await prefs.setString('editor_map_name', name);
        
        if (mounted) {
          _showSnackBar('✔ Mapa cargado: $name', Colors.blue);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al cargar: $e', Colors.red);
      }
    }
  }
  
  Future<void> _deleteMap(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapKey = 'map_$name';
      
      await prefs.remove(mapKey);
      savedMaps.remove(name);
      await prefs.setString('saved_maps_list', jsonEncode(savedMaps));
      
      setState(() {});
      
      if (mounted) {
        _showSnackBar('🗑️ Mapa eliminado: $name', Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al eliminar: $e', Colors.red);
      }
    }
  }
  
  Future<void> _exportAndLoad() async {
    await _saveMap();
    
    final mapData = map.map((row) => 
      row.map((type) => type.index).toList()
    ).toList();
    
    // IMPORTANTE: También guardar como mapa actual del juego
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_map_data', jsonEncode(mapData));
      await prefs.setString('current_map_id', mapName);
      debugPrint('💾 Mapa guardado como actual: $mapName');
    } catch (e) {
      debugPrint('Error guardando mapa actual: $e');
    }
    
    if (mounted) {
      Navigator.pop(context, {
        'mapData': mapData,
        'mapId': mapName,
      });
    }
  }
  
  // ========================================================================
  // PINTADO CIRCULAR - OPTIMIZADO
  // ========================================================================
  
  void _paintAt(Offset localPosition) {
    final matrix = transformationController.value;
    final inverse = Matrix4.inverted(matrix);
    final transformedPosition = MatrixUtils.transformPoint(inverse, localPosition);
    
    final centerX = (transformedPosition.dx / cellSize).floor();
    final centerY = (transformedPosition.dy / cellSize).floor();
    
    if (!_isValidCell(centerX, centerY)) return;
    
    setState(() {
      _paintCircularBrush(centerX, centerY);
    });
  }
  
  void _paintCircularBrush(int centerX, int centerY) {
    final radius = brushSize.toDouble();
    final radiusSquared = radius * radius;
    
    for (int dy = -brushSize; dy <= brushSize; dy++) {
      for (int dx = -brushSize; dx <= brushSize; dx++) {
        final distSquared = dx * dx + dy * dy;
        
        // Verificar si está dentro del círculo
        if (distSquared <= radiusSquared) {
          final nx = centerX + dx;
          final ny = centerY + dy;
          
          if (_isValidCell(nx, ny)) {
            map[ny][nx] = selectedTool;
          }
        }
      }
    }
  }
  
  // ========================================================================
  // UTILIDADES - OPTIMIZADAS Y REUTILIZABLES
  // ========================================================================
  
  bool _isValidCell(int x, int y) {
    return x >= 0 && x < gridSize && y >= 0 && y < gridSize;
  }
  
  String _encodeMap(List<List<TerrainType>> mapData) {
    return jsonEncode(mapData.map((row) => 
      row.map((type) => type.index).toList()
    ).toList());
  }
  
  List<List<TerrainType>> _decodeMap(String mapJson) {
    final List<dynamic> decoded = jsonDecode(mapJson);
    return decoded.map((row) => 
      (row as List).map((type) => TerrainType.values[type as int]).toList()
    ).toList();
  }
  
  void _fillAll(TerrainType type) {
    setState(() {
      map = List.generate(gridSize, (_) => List.filled(gridSize, type));
    });
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Color _getTerrainColor(TerrainType type) {
    switch (type) {
      case TerrainType.deepWater:
        return const Color(0xFF1a4d7a);
      case TerrainType.midWater:
        return const Color(0xFF2e75b6);
      case TerrainType.shore:
        return const Color(0xFF5fa3d0);
      case TerrainType.sand:
        return const Color(0xFFf4d58d);
      case TerrainType.grass:
        return const Color(0xFF7cb342);
    }
  }
  
  String _getTerrainName(TerrainType type) {
    switch (type) {
      case TerrainType.deepWater:
        return 'Agua Profunda';
      case TerrainType.midWater:
        return 'Agua Media';
      case TerrainType.shore:
        return 'Costa';
      case TerrainType.sand:
        return 'Arena';
      case TerrainType.grass:
        return 'Pasto';
    }
  }
  
  IconData _getTerrainIcon(TerrainType type) {
    switch (type) {
      case TerrainType.deepWater:
        return Icons.water;
      case TerrainType.midWater:
        return Icons.water_drop;
      case TerrainType.shore:
        return Icons.beach_access;
      case TerrainType.sand:
        return Icons.landscape;
      case TerrainType.grass:
        return Icons.grass;
    }
  }
  
  // ========================================================================
  // UI - INTERFAZ DE USUARIO
  // ========================================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          _buildToolPanel(),
          _buildMapCanvas(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('🎨 Editor de Mapas'),
      backgroundColor: Colors.blueGrey[800],
      actions: [
        IconButton(
          icon: const Icon(Icons.folder_open),
          tooltip: 'Cargar Mapa',
          onPressed: _showLoadDialog,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Guardar Progreso',
          onPressed: _saveMap,
        ),
        IconButton(
          icon: const Icon(Icons.check_circle),
          tooltip: 'Guardar y Cargar en Juego',
          onPressed: _exportAndLoad,
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Cambiar Nombre',
          onPressed: _showNameDialog,
        ),
      ],
    );
  }
  
  Widget _buildToolPanel() {
    return Container(
      width: 280,
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'HERRAMIENTAS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final type in TerrainType.values)
                  _buildToolButton(type),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                _buildBrushSizeControl(),
                const Divider(color: Colors.white24),
                _buildMapNameDisplay(),
                const Divider(color: Colors.white24),
                _buildQuickActions(),
              ],
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }
  
  Widget _buildBrushSizeControl() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Radio: $brushSize',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: brushSize.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            label: brushSize.toString(),
            onChanged: (value) {
              setState(() => brushSize = value.toInt());
            },
          ),
          Center(
            child: Container(
              width: brushSize * 8.0,
              height: brushSize * 8.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getTerrainColor(selectedTool).withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapNameDisplay() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOMBRE DEL MAPA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mapName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.map,
                  color: Colors.blue[300],
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'ACCIONES RÁPIDAS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildQuickActionButton(
          'Llenar con Agua',
          Icons.water,
          Colors.blue,
          () => _fillAll(TerrainType.deepWater),
        ),
        _buildQuickActionButton(
          'Llenar con Pasto',
          Icons.grass,
          Colors.green,
          () => _fillAll(TerrainType.grass),
        ),
        _buildQuickActionButton(
          'Llenar con Arena',
          Icons.beach_access,
          Colors.orange,
          () => _fillAll(TerrainType.sand),
        ),
      ],
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black26,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTROLES:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Click/Arrastrar: Pintar (circular)\n'
            '• Scroll: Zoom\n'
            '• ✓ : Guardar y Cargar',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapCanvas() {
    return Expanded(
      child: Container(
        color: Colors.grey[850],
        child: InteractiveViewer(
          transformationController: transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          constrained: false,
          child: GestureDetector(
            onPanStart: (details) {
              isDrawing = true;
              _paintAt(details.localPosition);
            },
            onPanUpdate: (details) {
              if (isDrawing) _paintAt(details.localPosition);
            },
            onPanEnd: (_) => isDrawing = false,
            onTapDown: (details) => _paintAt(details.localPosition),
            child: CustomPaint(
              size: Size(gridSize * cellSize, gridSize * cellSize),
              painter: MapGridPainter(map, cellSize, _getTerrainColor),
            ),
          ),
        ),
      ),
    );
  }
  
  // ========================================================================
  // DIÁLOGOS
  // ========================================================================
  
  void _showNameDialog() {
    final controller = TextEditingController(text: mapName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del Mapa'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre (sin espacios)',
            hintText: 'isla_tropical',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                mapName = controller.text
                    .replaceAll(' ', '_')
                    .toLowerCase();
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  void _showLoadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📂 Cargar Mapa'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: savedMaps.isEmpty
              ? const Center(
                  child: Text('No hay mapas guardados'),
                )
              : ListView.builder(
                  itemCount: savedMaps.length,
                  itemBuilder: (context, index) {
                    final name = savedMaps[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.map, color: Colors.blue),
                        title: Text(name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteMap(name);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _loadMap(name);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  // ========================================================================
  // WIDGETS AUXILIARES
  // ========================================================================
  
  Widget _buildToolButton(TerrainType type) {
    final isSelected = selectedTool == type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => setState(() => selectedTool = type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected 
            ? _getTerrainColor(type) 
            : Colors.blueGrey[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
        ),
        child: Row(
          children: [
            Icon(_getTerrainIcon(type), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getTerrainName(type),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      ),
    );
  }
}

// ============================================================================
// PAINTER DEL MAPA
// ============================================================================

class MapGridPainter extends CustomPainter {
  final List<List<TerrainType>> map;
  final double cellSize;
  final Color Function(TerrainType) getColor;
  
  MapGridPainter(this.map, this.cellSize, this.getColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar celdas
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );
        
        final paint = Paint()
          ..color = getColor(map[y][x])
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(rect, paint);
      }
    }
    
    // Dibujar grid cada 10 celdas
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    
    for (int i = 0; i <= map.length; i += 10) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(MapGridPainter oldDelegate) => true;
}