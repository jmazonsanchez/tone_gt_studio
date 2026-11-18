import 'package:flutter/material.dart';
import '../models/effect_block.dart';
import '../models/effect_parameter.dart';
import '../models/patch.dart';
import '../protocol/gt_sysex.dart';
import '../protocol/gt1b_addresses.dart';
import 'midi_service.dart';

class PatchService extends ChangeNotifier {
  final MidiService midiService;
  int _currentPatchIndex = 0;
  bool _isTunerActive = false;
  bool _isWahActive = false;
  int _wahPosition = 50;

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatusText = '';
  bool _wasConnected = false;

  PatchService(this.midiService) {
    _initializeDefaultPatches();
    midiService.addListener(_onMidiStateChanged);
  }

  @override
  void dispose() {
    midiService.removeListener(_onMidiStateChanged);
    super.dispose();
  }

  void _onMidiStateChanged() {
    if (midiService.isConnected && !_wasConnected) {
      _wasConnected = true;
      _autoSyncFromHardware();
    } else if (!midiService.isConnected) {
      _wasConnected = false;
    }
  }

  Future<void> _autoSyncFromHardware() async {
    // 1. Ask GT-1B what patch is currently selected physically
    await syncCurrentPatchNumber();
    // 2. Fetch the active patch settings, effect states and WAH status
    await syncActivePatchFromPedal();
    await syncWahStateFromPedal();
    // 3. Fetch all 99 preset names from the physical pedal in background
    await syncAllPatchesFromPedal();
  }

  int get currentPatchIndex => _currentPatchIndex;
  bool get isTunerActive => _isTunerActive;
  bool get isWahActive => _isWahActive;
  int get wahPosition => _wahPosition;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncStatusText => _syncStatusText;

  Patch get currentPatch => _patches[_currentPatchIndex];
  List<Patch> get patches => List.unmodifiable(_patches);

  final List<Patch> _patches = [];

  void _initializeDefaultPatches() {
    for (int i = 0; i < 99; i++) {
      final numberStr = (i + 1).toString().padLeft(2, '0');
      _patches.add(
        Patch(
          index: i,
          name: 'Patch U$numberStr',
          effects: _createDefaultEffects(i),
        ),
      );
    }
  }

  List<EffectBlock> _createDefaultEffects(int patchIdx) {
    return [
      EffectBlock(
        id: 'comp',
        name: 'COMP',
        subtitle: 'Limiter / Comp',
        category: EffectCategory.comp,
        accentColor: const Color(0xFF1E88E5), // Blue boutique
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
        accentColor: const Color(0xFFFB8C00), // Amber Gold
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
        accentColor: const Color(0xFFD81B60), // Crimson Red
        isEnabled: true,
        parameters: [
          EffectParameter(id: 'amp_gain', name: 'Gain', address: [0x60, 0x00, 0x00, 0x52], value: 50),
          EffectParameter(id: 'amp_bass', name: 'Bass', address: [0x60, 0x00, 0x00, 0x54], value: 55),
          EffectParameter(id: 'amp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x58], value: 70),
        ],
      ),
      EffectBlock(
        id: 'fx1',
        name: 'FX1',
        subtitle: 'Sub Wah / Filter',
        category: EffectCategory.fx1,
        accentColor: const Color(0xFF8E24AA), // Purple
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'fx1_sens', name: 'Sens', address: [0x60, 0x00, 0x04, 0x12], value: 60),
          EffectParameter(id: 'fx1_peak', name: 'Peak', address: [0x60, 0x00, 0x04, 0x14], value: 50),
        ],
      ),
      EffectBlock(
        id: 'fx2',
        name: 'FX2',
        subtitle: 'Bass Octaver / Mod',
        category: EffectCategory.fx2,
        accentColor: const Color(0xFF3949AB), // Cobalt Indigo
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'fx2_direct', name: 'Direct', address: [0x60, 0x00, 0x05, 0x12], value: 70),
          EffectParameter(id: 'fx2_oct', name: '-1 Oct', address: [0x60, 0x00, 0x05, 0x14], value: 50),
        ],
      ),
      EffectBlock(
        id: 'delay',
        name: 'DELAY',
        subtitle: 'Tape Echo',
        category: EffectCategory.delay,
        accentColor: const Color(0xFF00897B), // Teal
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'dly_time', name: 'Time', address: [0x60, 0x00, 0x05, 0x62], value: 40, unit: 'ms'),
          EffectParameter(id: 'dly_feedback', name: 'F.Back', address: [0x60, 0x00, 0x10, 0x72], value: 35),
          EffectParameter(id: 'dly_level', name: 'Level', address: [0x60, 0x00, 0x05, 0x66], value: 50),
        ],
      ),
      EffectBlock(
        id: 'chorus',
        name: 'CHORUS',
        subtitle: 'Stereo Chorus',
        category: EffectCategory.chorus,
        accentColor: const Color(0xFF00ACC1), // Cyan
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'cho_rate', name: 'Rate', address: [0x60, 0x00, 0x07, 0x12], value: 40),
          EffectParameter(id: 'cho_depth', name: 'Depth', address: [0x60, 0x00, 0x07, 0x14], value: 60),
          EffectParameter(id: 'cho_level', name: 'Level', address: [0x60, 0x00, 0x07, 0x18], value: 50),
        ],
      ),
      EffectBlock(
        id: 'reverb',
        name: 'REVERB',
        subtitle: 'Plate Reverb',
        category: EffectCategory.reverb,
        accentColor: const Color(0xFF5E35B1), // Deep Violet
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'rev_time', name: 'Time', address: [0x60, 0x00, 0x06, 0x12], value: 45),
          EffectParameter(id: 'rev_level', name: 'Level', address: [0x60, 0x00, 0x06, 0x18], value: 40),
        ],
      ),
      EffectBlock(
        id: 'pedal_fx',
        name: 'PEDAL FX',
        subtitle: 'Wah / Foot Bend',
        category: EffectCategory.pedalFx,
        accentColor: const Color(0xFFFF5722), // Deep Flame Orange
        isEnabled: false,
        parameters: [
          EffectParameter(id: 'pdl_pos', name: 'Pedal Pos', address: [0x60, 0x00, 0x06, 0x27], value: 50),
          EffectParameter(id: 'pdl_level', name: 'Effect Level', address: [0x60, 0x00, 0x06, 0x2A], value: 80),
        ],
      ),
    ];
  }

  /// Query GT-1B setup buffer to determine which patch is currently selected physically (00 01 00 00)
  Future<void> syncCurrentPatchNumber() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildCurrentPatchNumberRequest();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final patchIdx = GtSysEx.parseCurrentPatchNumber(reply);
        if (patchIdx != null && patchIdx >= 0 && patchIdx < _patches.length) {
          _currentPatchIndex = patchIdx;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing current patch number: $e');
    }
  }

  /// Synchronize all 99 user patch names from Boss GT-1B hardware via SysEx RQ1
  Future<void> syncAllPatchesFromPedal() async {
    if (_isSyncing || !midiService.isConnected) return;
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatusText = 'Leyendo presets de la GT-1B...';
    notifyListeners();

    try {
      int consecutiveFails = 0;
      for (int i = 0; i < 99; i++) {
        if (!midiService.isConnected) break;

        _syncProgress = (i + 1) / 99.0;
        _syncStatusText = 'Leyendo U${(i + 1).toString().padLeft(2, '0')}/U99...';
        notifyListeners();

        final req = GtSysEx.buildPatchNameRequest(i);
        final reply = await midiService.sendSysExRequest(
          req,
          timeout: const Duration(milliseconds: 350),
        );

        if (reply != null) {
          consecutiveFails = 0;
          final name = GtSysEx.parsePatchName(reply);
          if (name != null && name.isNotEmpty) {
            _patches[i] = _patches[i].copyWith(name: name);
          }
        } else {
          consecutiveFails++;
          if (consecutiveFails > 8) {
            debugPrint('Demasiados timeouts al leer patches. Deteniendo sincronización.');
            break;
          }
        }
        await Future.delayed(const Duration(milliseconds: 30));
      }

      await syncActivePatchFromPedal();
      await syncWahStateFromPedal();
    } finally {
      _isSyncing = false;
      _syncProgress = 1.0;
      _syncStatusText = '¡Presets de tu pedalera cargados!';
      notifyListeners();
    }
  }

  /// Synchronize currently active patch settings (Name and Effect switches) from temporary buffer (60 00 00 00)
  Future<void> syncActivePatchFromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildActivePatchDataRequest();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 500),
      );

      if (reply != null) {
        final activeName = GtSysEx.parsePatchName(reply);
        if (activeName != null && activeName.isNotEmpty) {
          _patches[_currentPatchIndex] = _patches[_currentPatchIndex].copyWith(name: activeName);
        }

        final switches = GtSysEx.parseActiveEffectSwitches(reply);
        if (switches != null) {
          for (final effect in currentPatch.effects) {
            if (switches.containsKey(effect.category)) {
              effect.isEnabled = switches[effect.category]!;
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing active patch: $e');
    }
  }

  /// Query live WAH / Pedal FX state (60 00 06 20)
  Future<void> syncWahStateFromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildRq1Message(
        address: Gt1bAddresses.pedalFxSwitch,
        size: [0x00, 0x00, 0x00, 0x01],
      );
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 350),
      );
      if (reply != null && reply.length >= 13) {
        _isWahActive = reply[12] != 0x00;
        final wahBlock = currentPatch.effects.where((e) => e.category == EffectCategory.pedalFx).firstOrNull;
        if (wahBlock != null) {
          wahBlock.isEnabled = _isWahActive;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing WAH state: $e');
    }
  }

  /// Toggle WAH / Expression Footswitch
  Future<void> toggleWah() async {
    _isWahActive = !_isWahActive;
    final wahBlock = currentPatch.effects.where((e) => e.category == EffectCategory.pedalFx).firstOrNull;
    if (wahBlock != null) {
      wahBlock.isEnabled = _isWahActive;
    }
    notifyListeners();
    final msg = GtSysEx.buildPedalFxToggle(_isWahActive);
    await midiService.sendSysEx(msg);
  }

  /// Sweep WAH position in real time (0..100)
  Future<void> setWahPosition(int pos) async {
    _wahPosition = pos.clamp(0, 100);
    notifyListeners();
    final msg = GtSysEx.buildPedalFxWahPosition(_wahPosition);
    await midiService.sendSysEx(msg);
  }

  Future<void> selectPatch(int index) async {
    if (index < 0 || index >= _patches.length) return;
    _currentPatchIndex = index;
    notifyListeners();
    await midiService.changePatch(index);

    // Give the GT-1B DSP 150ms to load buffer, then sync effect states & WAH
    await Future.delayed(const Duration(milliseconds: 150));
    await syncActivePatchFromPedal();
    await syncWahStateFromPedal();
  }

  Future<void> nextPatch() async {
    if (_currentPatchIndex < _patches.length - 1) {
      await selectPatch(_currentPatchIndex + 1);
    }
  }

  Future<void> previousPatch() async {
    if (_currentPatchIndex > 0) {
      await selectPatch(_currentPatchIndex - 1);
    }
  }

  Future<void> toggleEffect(EffectBlock effect) async {
    final newState = !effect.isEnabled;
    effect.isEnabled = newState;
    if (effect.category == EffectCategory.pedalFx) {
      _isWahActive = newState;
    }
    notifyListeners();
    await midiService.toggleEffect(effect.category, newState);
  }

  Future<void> updateParameter(EffectParameter param, int newValue) async {
    param.value = newValue.clamp(param.min, param.max);
    notifyListeners();
    await midiService.sendParameterValue(param.address, param.value);
  }

  Future<void> toggleTuner() async {
    _isTunerActive = !_isTunerActive;
    notifyListeners();
    await midiService.toggleTuner(_isTunerActive);
  }
}
