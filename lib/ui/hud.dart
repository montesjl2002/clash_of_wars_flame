import 'package:flutter/material.dart';
import '../data/building_data.dart';
import '../game/clash_of_war_game.dart';
import '../game/building.dart';
import 'dart:ui' as ui;
import 'package:flame/flame.dart';

import '../terrain/map_editor.dart';

class HudOverlay extends StatefulWidget {
  final ClashOfWarGame game;
  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay>
    with SingleTickerProviderStateMixin {
  bool _showBuildMenu = false;
  late TabController _tabController;
  int _currentGold = 0;
  int _minedGold = 0;
  String? _currentMapId;
  bool _hasValidMap = true; // NUEVO: control de mapa válido

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentGold = widget.game.currentGold;
    _currentMapId = widget.game.getCurrentMapId();
    _hasValidMap = widget.game.hasValidMap(); // NUEVO
    
    widget.game.onBuildingPlaced = () {
      if (mounted) setState(() {});
    };
    
    widget.game.onGoldChanged = (gold) {
      if (mounted) {
        setState(() {
          _currentGold = gold;
        });
      }
    };
    
    widget.game.onMapChanged = (mapId) {
      if (mounted) {
        setState(() {
          _currentMapId = mapId;
        });
      }
    };
    
    // NUEVO: escuchar cambios en el estado del mapa
    widget.game.onMapStatusChanged = (hasMap) {
      if (mounted) {
        setState(() {
          _hasValidMap = hasMap;
        });
      }
    };
    
    // Actualizar oro minado cada segundo
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _minedGold = widget.game.getTotalMinedGold();
        });
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // OVERLAY SI NO HAY MAPA - Pantalla negra con mensaje
          if (!_hasValidMap)
            _buildNoMapOverlay(),
          
          // UI NORMAL (solo visible si hay mapa)
          if (_hasValidMap) ...[
            Positioned(top: 8, left: 8, child: _buildGoldWidget()),
            Positioned(top: 8, right: 8, child: _buildTopRightButtons()),
            Positioned(bottom: 8, right: 8, child: _buildShopButton()),
            Positioned(bottom: 8, left: 8, child: _buildConstructionButton()),
            
            // Indicador del mapa actual
            if (_currentMapId != null && _currentMapId != 'empty')
              Positioned(
                top: 70,
                right: 8,
                child: _buildMapIndicator(),
              ),
            
            // Mostrar oro minado disponible
            if (_minedGold > 0)
              Positioned(
                top: 70,
                left: 8,
                child: _buildMinedGoldIndicator(),
              ),
            
            if (_showBuildMenu)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildConstructionMenu(),
              ),
          ],
        ],
      ),
    );
  }

  // NUEVO: Overlay cuando no hay mapa
  Widget _buildNoMapOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 100,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            const Text(
              '🗺️ No hay mapa creado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Crea un mapa para comenzar a jugar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _openMapEditor,
              icon: const Icon(Icons.edit_location, size: 32),
              label: const Text(
                'Crear Mapa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Estilo Unity Terrain Painter',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldWidget() {
    return GestureDetector(
      onTap: _collectAllGold,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade700, Colors.amber.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white38, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.yellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatNumber(_currentGold),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            if (_minedGold > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            _currentMapId ?? 'Sin mapa',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinedGoldIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, color: Colors.yellow, size: 20),
          const SizedBox(width: 6),
          Text(
            '+${_formatNumber(_minedGold)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '(Tap para recolectar)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _collectAllGold() {
    final mines = widget.game.buildingManager
        .getAllBuildings()
        .where((b) => b.isGoldMine())
        .toList();
    
    for (final mine in mines) {
      widget.game.collectGoldFromMine(mine);
    }
    
    setState(() {
      _minedGold = 0;
    });
  }

  Widget _buildTopRightButtons() {
    return Row(
      children: [
        // NUEVO: Botón para abrir el editor de mapas
        _buildRoundButton(
          Icons.edit_location,
          Colors.purple.shade600,
          _openMapEditor,
          tooltip: 'Editor de Mapas',
        ),
        const SizedBox(width: 8),
        // Botón para limpiar edificios
        _buildRoundButton(
          Icons.delete_forever,
          Colors.red.shade600,
          _clearBuildings,
          tooltip: 'Limpiar Edificios',
        ),
        const SizedBox(width: 8),
        _buildRoundButton(
          Icons.settings,
          Colors.grey.shade700,
          () {},
          tooltip: 'Configuración',
        ),
      ],
    );
  }

  Widget _buildRoundButton(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Future<void> _openMapEditor() async {
    // Cancelar cualquier construcción en progreso
    widget.game.cancelPlacement();
    setState(() => _showBuildMenu = false);
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapEditorScreen(),
      ),
    );
    
    if (result != null && result['mapData'] != null) {
      final mapData = result['mapData'] as List<List<int>>;
      final mapId = result['mapId'] as String;
      
      await widget.game.loadMapFromEditor(mapData, mapId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mapa cargado: $mapId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearBuildings() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar'),
        content: const Text('¿Estás seguro de eliminar todos los edificios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await widget.game.buildingManager.clearSavedProgress();
    widget.game.isoGrid.occupiedCells = List.generate(
      widget.game.isoGrid.rows,
      (_) => List.filled(widget.game.isoGrid.cols, false),
    );
    
    final buildingsToRemove = widget.game.children
        .whereType<Building>()
        .toList();
    
    for (final building in buildingsToRemove) {
      building.removeFromParent();
    }
    
    widget.game.buildingManager.clearAll();
    
    setState(() {});
  }

  Widget _buildShopButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade500, Colors.green.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildConstructionButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showBuildMenu = !_showBuildMenu;
          if (!_showBuildMenu) {
            widget.game.cancelPlacement();
          }
        });
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown.shade600, Colors.brown.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber.shade700, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _showBuildMenu ? Icons.close : Icons.construction,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildConstructionMenu() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade800, Colors.brown.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Colors.amber.shade700, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: Colors.brown.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
              ),
              border: Border(
                right: BorderSide(color: Colors.amber.shade700, width: 2),
              ),
            ),
            child: Column(
              children: [
                _buildVerticalTab(0, Icons.shield),
                _buildVerticalTab(1, Icons.inventory_2),
                _buildVerticalTab(2, Icons.military_tech),
                _buildVerticalTab(3, Icons.park),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBuildingGrid(BuildingsDatabase.defensiveBuildings),
                _buildBuildingGrid(BuildingsDatabase.resourceBuildings),
                _buildBuildingGrid(BuildingsDatabase.armyBuildings),
                _buildBuildingGrid(BuildingsDatabase.decorations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTab(int index, IconData icon) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: Container(
        width: 60,
        height: (MediaQuery.of(context).size.height * 0.45 - 20) / 4,
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown.shade700 : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.amber.shade600 : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? Colors.amber.shade400 : Colors.grey.shade400,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingGrid(List<BuildingInfo> buildings) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: buildings.map((building) {
          final placedCount = widget.game.getBuildingCount(building.key);
          final isMaxed = building.hasLimit && placedCount >= building.maxQuantity;
          final canAfford = _currentGold >= building.cost;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildBuildingCard(building, isMaxed, canAfford, placedCount),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBuildingCard(
    BuildingInfo building,
    bool isMaxed,
    bool canAfford,
    int placedCount,
  ) {
    final isDisabled = isMaxed || !canAfford;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              widget.game.selectBuildingFromInfo(building);
              setState(() => _showBuildMenu = false);
            },
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: 90,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDisabled
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [Colors.brown.shade600, Colors.brown.shade700],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDisabled ? Colors.grey.shade600 : Colors.amber.shade800,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (building.hasLimit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      margin: const EdgeInsets.only(top: 4, bottom: 2),
                      decoration: BoxDecoration(
                        color: isMaxed ? Colors.red.shade700 : Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$placedCount/${building.maxQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: FutureBuilder<ui.Image?>(
                        future: _loadImage(building.key),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return RawImage(image: snapshot.data, fit: BoxFit.contain);
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      building.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    building.sizeLabel,
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 8),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: canAfford ? Colors.amber.shade700 : Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          _formatNumber(building.cost),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isMaxed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ui.Image?> _loadImage(String key) async {
    try {
      return Flame.images.fromCache(key);
    } catch (e) {
      return null;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}