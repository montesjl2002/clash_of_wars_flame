import 'dart:ui';
import 'package:rts_empire_of_war/game/core/polar_position.dart';

import '../components/unit_component.dart';
import '../components/building_component.dart';
import '../components/resource_node.dart';
import '../camera/polar_camera.dart';
import '../components/villager_component.dart';
import 'world_system.dart';

/* Sistema que gestiona la entrada del usuario */
class InputSystem {
  final PolarCamera camera;
  final WorldSystem worldSystem;
  final int playerOwner;
  
  Offset? _selectionStart;
  Offset? _selectionEnd;
  final List<UnitComponent> _selectedUnits = [];
  
  InputSystem({
    required this.camera,
    required this.worldSystem,
    required this.playerOwner,
  });
  
  /* Inicia selección */
  void startSelection(Offset screenPos) {
    _selectionStart = screenPos;
    _selectionEnd = screenPos;
  }
  
  /* Actualiza selección */
  void updateSelection(Offset screenPos) {
    _selectionEnd = screenPos;
  }
  
  /* Finaliza selección */
  void endSelection() {
    if (_selectionStart == null || _selectionEnd == null) return;
    
    _clearSelection();
    
    final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    
    for (final unit in worldSystem.units) {
      if (unit.owner != playerOwner || !unit.isAlive) continue;
      
      final screenPos = camera.worldToScreen(unit.position as PolarPosition);
      if (rect.contains(screenPos)) {
        unit.selected = true;
        _selectedUnits.add(unit);
      }
    }
    
    _selectionStart = null;
    _selectionEnd = null;
  }
  
  /* Limpia la selección actual */
  void _clearSelection() {
    for (final unit in _selectedUnits) {
      unit.selected = false;
    }
    _selectedUnits.clear();
  }
  
  /* Ordena mover unidades seleccionadas */
  void orderMove(Offset screenPos) {
    if (_selectedUnits.isEmpty) return;
    
    final worldPos = camera.screenToWorld(screenPos);
    
    for (final unit in _selectedUnits) {
      unit.moveTo(worldPos);
    }
  }
  
  /* Ordena atacar con unidades seleccionadas */
  void orderAttack(Offset screenPos) {
    if (_selectedUnits.isEmpty) return;
    
    final worldPos = camera.screenToWorld(screenPos);
    
    UnitComponent? targetUnit;
    BuildingComponent? targetBuilding;
    double minDist = 50.0;
    
    for (final unit in worldSystem.units) {
      if (unit.owner == playerOwner || !unit.isAlive) continue;
      
      final dist = worldPos.distanceTo(unit.position as PolarPosition);
      if (dist < minDist) {
        minDist = dist;
        targetUnit = unit;
      }
    }
    
    for (final building in worldSystem.buildings) {
      if (building.owner == playerOwner || building.isDestroyed) continue;
      
      final dist = worldPos.distanceTo(building.position as PolarPosition);
      if (dist < minDist) {
        minDist = dist;
        targetUnit = null;
        targetBuilding = building;
      }
    }
    
    if (targetUnit != null) {
      for (final unit in _selectedUnits) {
        unit.attackMove(targetUnit);
      }
    } else if (targetBuilding != null) {
      for (final unit in _selectedUnits) {
        unit.attackMove(targetBuilding);
      }
    }
  }
  
  /* Ordena recolectar con unidades seleccionadas */
  void orderGather(Offset screenPos) {
    if (_selectedUnits.isEmpty) return;
    
    final worldPos = camera.screenToWorld(screenPos);
    
    ResourceNode? targetResource;
    double minDist = 50.0;
    
    for (final resource in worldSystem.resources) {
      if (resource.isDepleted) continue;
      
      final dist = worldPos.distanceTo(resource.position as PolarPosition);
      if (dist < minDist) {
        minDist = dist;
        targetResource = resource;
      }
    }
    
    if (targetResource != null) {
      for (final unit in _selectedUnits) {
        if (unit is VillagerComponent) {
          unit.gatherFrom(targetResource);
        }
      }
    }
  }
  
  /* Obtiene la caja de selección actual */
  Rect? get selectionBox {
    if (_selectionStart == null || _selectionEnd == null) return null;
    return Rect.fromPoints(_selectionStart!, _selectionEnd!);
  }
  
  /* Obtiene unidades seleccionadas */
  List<UnitComponent> get selectedUnits => _selectedUnits;
  
  /* Limpia el sistema */
  void clear() {
    _clearSelection();
    _selectionStart = null;
    _selectionEnd = null;
  }
}