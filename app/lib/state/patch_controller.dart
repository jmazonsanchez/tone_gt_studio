import 'package:flutter/material.dart';
import '../domain/models/patch_model.dart';
import '../models/effect_block.dart';
import '../models/effect_parameter.dart';
import '../protocol/gt_sysex.dart';
import '../protocol/gt1b_map.dart';
import '../protocol/roland_sysex.dart';
import '../sync/event_router.dart';
import '../sync/sync_engine.dart';
import '../sync/write_queue.dart';

/// Controlador reactivo del preset actual y la cadena de efectos para la interfaz.
class PatchController extends ChangeNotifier {
  final SyncEngine syncEngine;
  final WriteQueue writeQueue;
  final EventRouter eventRouter;

  PatchRef _currentRef = const PatchRef(bank: PatchBank.user, number: 1);
  String _currentName = 'CARGANDO...';
  List<EffectBlock> _effects = [];
  bool _isTunerActive = false;
  bool _isWahActive = false;
  int _wahPosition = 50;
  int _footVolumeLevel = 100;
  bool _isSyncing = false;

  PatchRef get currentRef => _currentRef;
  String get currentName => _currentName;
  List<EffectBlock> get effects => List.unmodifiable(_effects);
  bool get isReadOnly => _currentRef.isReadOnly;
  bool get isTunerActive => _isTunerActive;
  bool get isWahActive => _isWahActive;
  int get wahPosition => _wahPosition;
  int get footVolumeLevel => _footVolumeLevel;
  bool get isSyncing => _isSyncing;

  PatchController({
    required this.syncEngine,
    required this.writeQueue,
    required this.eventRouter,
  }) {
    _effects = _createDefaultEffects();
    _bindEventRouterHandlers();
  }

  void _bindEventRouterHandlers() {
    eventRouter.handlers = EventRouterHandlers(
      onPatchChanged: (ref) {
        if (_currentRef != ref) {
          _currentRef = ref;
          notifyListeners();
          reloadActivePatchFromHardware();
        }
      },
      onTunerToggled: (active) {
        if (_isTunerActive != active) {
          _isTunerActive = active;
          notifyListeners();
        }
      },
      onEffectSwitchChanged: (cat, enabled) {
        _updateEffectSwitchLocal(cat, enabled);
      },
      onFootVolumeChanged: (level) {
        if (_footVolumeLevel != level) {
          _footVolumeLevel = level;
          _updateEffectSwitchLocal(EffectCategory.footVolume, level > 0);
          notifyListeners();
        }
      },
      onWahPositionChanged: (pos) {
        if (_wahPosition != pos) {
          _wahPosition = pos;
          notifyListeners();
        }
      },
      onChainSlotChanged: (slotIdx, chainId) {
        _applySingleChainSlot(slotIdx, chainId);
      },
      onFullChainOrderChanged: (chainIds) {
        _applyChainOrder(chainIds);
      },
      onParameterChanged: (addr, val) {
        _updateParameterLocal(addr, val);
      },
    );
  }

  /// Recarga en vivo la información del preset activo desde el buffer temporal (H7).
  Future<void> reloadActivePatchFromHardware() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final data = await syncEngine.readActivePatch();
      if (data != null) {
        _currentName = data.name.isNotEmpty ? data.name : _currentRef.displayNumber;
        _footVolumeLevel = data.footVolumeLevel;
        _wahPosition = data.wahPosition;
        _isWahActive = data.switches[EffectCategory.pedalFx] ?? false;

        // Actualizar estados de switches
        for (final effect in _effects) {
          if (data.switches.containsKey(effect.category)) {
            effect.isEnabled = data.switches[effect.category]!;
          }
        }

        // Orden de la cadena (Memory Edit)
        if (data.fxChain.isNotEmpty) {
          _applyChainOrder(data.fxChain);
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Conmuta un efecto desde la UI enviando el cambio a la WriteQueue.
  void toggleEffect(EffectBlock effect) {
    final newState = !effect.isEnabled;
    effect.isEnabled = newState;
    if (effect.category == EffectCategory.pedalFx) {
      _isWahActive = newState;
    }
    notifyListeners();

    // Obtener dirección del switch
    final addr = _getSwitchAddress(effect.category);
    if (addr != null) {
      writeQueue.queueWrite(addr, [newState ? 0x01 : 0x00]);
    }
  }

  /// Cambia el preset activo desde la UI (0 a 197).
  Future<void> selectPatch(PatchRef ref) async {
    if (_currentRef == ref) return;
    _currentRef = ref;
    notifyListeners();

    // Enviar cambio de preset a través de Roland DT1 (00 01 00 00)
    final rawIndex = ref.rawIndex;
    final data = [(rawIndex >> 7) & 0x7F, rawIndex & 0x7F];
    writeQueue.queueWrite(Gt1bMap.currentPatchNo, data);

    // Recargar estado del nuevo preset
    await reloadActivePatchFromHardware();
  }

  /// Conmuta el afinador desde la UI.
  void toggleTuner() {
    _isTunerActive = !_isTunerActive;
    notifyListeners();

    writeQueue.queueWrite(Gt1bMap.runningMode, [_isTunerActive ? 0x01 : 0x00]);
  }

  /// Ajusta el nivel del pedal de volumen (0 a 100).
  void setFootVolumeLevel(int level) {
    _footVolumeLevel = level;
    _updateEffectSwitchLocal(EffectCategory.footVolume, level > 0);
    notifyListeners();

    writeQueue.queueWrite(Gt1bMap.footVolumeLevel, [level.clamp(0, 100)]);
  }

  /// Ajusta la posición de barrido del WAH (0 a 100).
  void setWahPosition(int pos) {
    _wahPosition = pos;
    notifyListeners();

    writeQueue.queueWrite(Gt1bMap.pedalFxWahPosition, [pos.clamp(0, 100)]);
  }

  /// Reordena un efecto en la cadena local y lo envía a la pedalera.
  void moveEffect(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _effects.length || newIndex < 0 || newIndex >= _effects.length) {
      return;
    }
    final item = _effects.removeAt(oldIndex);
    _effects.insert(newIndex, item);
    notifyListeners();

    // GT-1B authentic 20-slot chain: slots 7..15 hold the 9 movable effects
    final chainBytes = List<int>.from(GtSysEx.defaultHardwareChain);
    for (int i = 0; i < _effects.length && i < 9; i++) {
      final chainId = GtSysEx.categoryToChainId[_effects[i].category] ?? 0;
      chainBytes[7 + i] = chainId;
    }
    writeQueue.queueWrite(Gt1bMap.fxChainBase, chainBytes);
  }

  void _updateEffectSwitchLocal(EffectCategory category, bool isEnabled) {
    bool changed = false;
    for (final effect in _effects) {
      if (effect.category == category && effect.isEnabled != isEnabled) {
        effect.isEnabled = isEnabled;
        changed = true;
      }
    }
    if (category == EffectCategory.pedalFx) {
      _isWahActive = isEnabled;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void _updateParameterLocal(List<int> addr, int val) {
    for (final effect in _effects) {
      for (final param in effect.parameters) {
        if (RolandSysEx.addressMatches(param.address, addr)) {
          if (param.value != val) {
            param.value = val;
            notifyListeners();
          }
          return;
        }
      }
    }
  }

  void _applyChainOrder(List<int> chainIds) {
    final currentList = List<EffectBlock>.from(_effects);
    final ordered = <EffectBlock>[];

    for (final id in chainIds) {
      final category = GtSysEx.chainIdToCategory[id];
      if (category != null) {
        final effect = currentList.where((e) => e.category == category).firstOrNull;
        if (effect != null && !ordered.contains(effect)) {
          ordered.add(effect);
        }
      }
    }

    for (final effect in currentList) {
      if (!ordered.contains(effect)) {
        ordered.add(effect);
      }
    }

    _effects = ordered;
    notifyListeners();
  }

  void _applySingleChainSlot(int slotIndex, int chainId) {
    final category = GtSysEx.chainIdToCategory[chainId];
    if (category == null) return;

    final effectIdx = _effects.indexWhere((e) => e.category == category);
    final targetIdx = (slotIndex >= 7 && slotIndex <= 15) ? (slotIndex - 7) : slotIndex;
    if (effectIdx >= 0 && targetIdx >= 0 && targetIdx < _effects.length) {
      final effect = _effects.removeAt(effectIdx);
      _effects.insert(targetIdx, effect);
      notifyListeners();
    }
  }

  List<int>? _getSwitchAddress(EffectCategory cat) {
    switch (cat) {
      case EffectCategory.comp:
        return Gt1bMap.compSwitch;
      case EffectCategory.odDs:
        return Gt1bMap.odDsSwitch;
      case EffectCategory.preamp:
        return Gt1bMap.preampSwitch;
      case EffectCategory.eq:
        return Gt1bMap.eqSwitch;
      case EffectCategory.fx1:
        return Gt1bMap.fx1Switch;
      case EffectCategory.fx2:
        return Gt1bMap.fx2Switch;
      case EffectCategory.delay:
        return Gt1bMap.delaySwitch;
      case EffectCategory.chorus:
        return Gt1bMap.chorusSwitch;
      case EffectCategory.reverb:
        return Gt1bMap.reverbSwitch;
      case EffectCategory.pedalFx:
        return Gt1bMap.pedalFxSwitch;
      case EffectCategory.footVolume:
        return Gt1bMap.footVolumeLevel;
      case EffectCategory.noiseSuppressor:
        return Gt1bMap.ns1Switch;
    }
  }

  List<EffectBlock> _createDefaultEffects() {
    return [
      EffectBlock(
        id: 'comp',
        name: 'COMP',
        subtitle: 'Limiter / Comp',
        category: EffectCategory.comp,
        accentColor: const Color(0xFF1E88E5),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'comp_tone', name: 'Tone', address: [0x60, 0x00, 0x00, 0x24], value: 50),
          EffectParameter(id: 'comp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x25], value: 65),
        ],
      ),
      EffectBlock(
        id: 'od_ds',
        name: 'OD/DS',
        subtitle: 'Bass Overdrive',
        category: EffectCategory.odDs,
        accentColor: const Color(0xFFFB8C00),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'od_drive', name: 'Drive', address: [0x60, 0x00, 0x00, 0x32], value: 45),
          EffectParameter(id: 'od_tone', name: 'Tone', address: [0x60, 0x00, 0x00, 0x34], value: 50),
          EffectParameter(id: 'od_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x37], value: 60),
        ],
      ),
      EffectBlock(
        id: 'preamp',
        name: 'PREAMP',
        subtitle: 'Concert 810',
        category: EffectCategory.preamp,
        accentColor: const Color(0xFFD81B60),
        isEnabled: true,
        parameters: [
          EffectParameter(id: 'amp_gain', name: 'Gain', address: [0x60, 0x00, 0x00, 0x52], value: 50),
          EffectParameter(id: 'amp_bass', name: 'Bass', address: [0x60, 0x00, 0x00, 0x54], value: 55),
          EffectParameter(id: 'amp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x58], value: 70),
        ],
      ),
      EffectBlock(
        id: 'eq',
        name: 'EQ',
        subtitle: 'Parametric Equalizer',
        category: EffectCategory.eq,
        accentColor: const Color(0xFF009688),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'eq_low_gain', name: 'Low Gain', address: [0x60, 0x00, 0x01, 0x32], value: 20),
          EffectParameter(id: 'eq_level', name: 'Level', address: [0x60, 0x00, 0x01, 0x3B], value: 50),
        ],
      ),
      EffectBlock(
        id: 'fx1',
        name: 'FX1',
        subtitle: 'Sub Wah / Filter',
        category: EffectCategory.fx1,
        accentColor: const Color(0xFF8E24AA),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'fx1_sens', name: 'Sens', address: [0x60, 0x00, 0x04, 0x12], value: 60),
        ],
      ),
      EffectBlock(
        id: 'fx2',
        name: 'FX2',
        subtitle: 'Bass Octaver / Mod',
        category: EffectCategory.fx2,
        accentColor: const Color(0xFF3949AB),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'fx2_direct', name: 'Direct', address: [0x60, 0x00, 0x05, 0x12], value: 70),
        ],
      ),
      EffectBlock(
        id: 'delay',
        name: 'DELAY',
        subtitle: 'Warm Digital Delay',
        category: EffectCategory.delay,
        accentColor: const Color(0xFF00ACC1),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'dly_time', name: 'Time', address: [0x60, 0x00, 0x05, 0x62], value: 35),
          EffectParameter(id: 'dly_feedback', name: 'Feedback', address: [0x60, 0x00, 0x05, 0x64], value: 30),
        ],
      ),
      EffectBlock(
        id: 'chorus',
        name: 'CHORUS',
        subtitle: 'Bass Chorus 2x2',
        category: EffectCategory.chorus,
        accentColor: const Color(0xFF43A047),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'cho_rate', name: 'Rate', address: [0x60, 0x00, 0x06, 0x02], value: 40),
        ],
      ),
      EffectBlock(
        id: 'reverb',
        name: 'REV',
        subtitle: 'Plate Reverb',
        category: EffectCategory.reverb,
        accentColor: const Color(0xFF5E35B1),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'rev_time', name: 'Time', address: [0x60, 0x00, 0x06, 0x12], value: 25),
        ],
      ),
      EffectBlock(
        id: 'pedal_fx',
        name: 'WAH',
        subtitle: 'Bass Auto/Pedal Wah',
        category: EffectCategory.pedalFx,
        accentColor: const Color(0xFFE53935),
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'wah_level', name: 'Level', address: [0x60, 0x00, 0x06, 0x2A], value: 50),
        ],
      ),
      EffectBlock(
        id: 'foot_volume',
        name: 'FV',
        subtitle: 'Foot Volume Level',
        category: EffectCategory.footVolume,
        accentColor: const Color(0xFF546E7A),
        isEnabled: true,
        parameters: [
          EffectParameter(id: 'fv_level', name: 'Level', address: [0x60, 0x00, 0x06, 0x33], value: 100),
        ],
      ),
      EffectBlock(
        id: 'ns',
        name: 'NS',
        subtitle: 'Noise Suppressor',
        category: EffectCategory.noiseSuppressor,
        accentColor: const Color(0xFF7CB342),
        isEnabled: true,
        parameters: [
          EffectParameter(id: 'ns_threshold', name: 'Threshold', address: [0x60, 0x00, 0x06, 0x64], value: 45),
        ],
      ),
    ];
  }
}
