import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../domain/gt1b_catalog.dart';
import '../domain/gt1b_fx_algorithms.dart';
import '../domain/gt1b_type_defaults.dart';
import '../models/assign_model.dart';
import '../models/effect_block.dart';
import '../models/effect_parameter.dart';
import '../models/patch.dart';
import '../protocol/gt_sysex.dart';
import '../protocol/gt1b_addresses.dart';
import 'midi_service.dart';

class PatchService extends ChangeNotifier {
  final MidiService midiService;
  StreamSubscription<Uint8List>? _sysExSubscription;
  int _currentPatchIndex = 0;
  bool _isTunerActive = false;
  bool _isWahActive = false;
  int _wahPosition = 50;
  int _footVolumeLevel = 100;

  // Master settings (Block 7)
  int _patchLevel = 100;
  int _masterBpm = 120;
  int _masterKey = 0;
  int _masterEqLow = 20;
  int _masterEqMidFreq = 14;
  int _masterEqMidQ = 1;
  int _masterEqMidGain = 20;
  int _masterEqHigh = 20;

  // Phase 5: Control, EXP and Assign Matrices 1-8
  CtlExpSetting _ctlExpSetting = const CtlExpSetting();
  final List<AssignSetting> _assigns = List.generate(
    8,
    (i) => AssignSetting(index: i + 1),
  );

  List<int> _hardwareFxChain = [
    0, 1, 4, 8, 10, 14, 17, 5, 2, 6, 11, 15, 12, 13, 7, 9, 18, 3, 19, 16
  ];

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatusText = '';
  bool _wasConnected = false;

  PatchService(this.midiService) {
    _initializeDefaultPatches();
    midiService.addListener(_onMidiStateChanged);
    _sysExSubscription = midiService.onSysExReceived.listen(_handleIncomingHardwareSysEx);
  }

  @override
  void dispose() {
    _sysExSubscription?.cancel();
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
    // 2. Fetch full active patch settings, all effect blocks, algorithms and chain
    await syncFullActivePatch();
    // 3. Fetch all 99 preset names from the physical pedal in background
    await syncAllPatchesFromPedal();
  }

  int get currentPatchIndex => _currentPatchIndex;
  bool get isCurrentPatchReadOnly => _currentPatchIndex >= 99;
  bool get isTunerActive => _isTunerActive;
  bool get isWahActive => _isWahActive;
  int get wahPosition => _wahPosition;
  int get footVolumeLevel => _footVolumeLevel;
  int get patchLevel => _patchLevel;
  int get masterBpm => _masterBpm;
  int get masterKey => _masterKey;
  int get masterEqLow => _masterEqLow;
  int get masterEqMidFreq => _masterEqMidFreq;
  int get masterEqMidQ => _masterEqMidQ;
  int get masterEqMidGain => _masterEqMidGain;
  int get masterEqHigh => _masterEqHigh;

  CtlExpSetting get ctlExpSetting => _ctlExpSetting;
  List<AssignSetting> get assigns => List.unmodifiable(_assigns);

  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncStatusText => _syncStatusText;

  Patch get currentPatch => _patches[_currentPatchIndex];
  List<Patch> get patches => List.unmodifiable(_patches);

  final List<Patch> _patches = [];

  void _initializeDefaultPatches() {
    // 99 Presets de Usuario (U01 a U99, índices 0 a 98)
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
    // 99 Presets de Fábrica (P01 a P99, índices 99 a 197) (H9, H11, D4)
    for (int i = 0; i < 99; i++) {
      final numberStr = (i + 1).toString().padLeft(2, '0');
      _patches.add(
        Patch(
          index: 99 + i,
          name: 'Preset P$numberStr',
          effects: _createDefaultEffects(99 + i),
        ),
      );
    }
  }

  List<EffectParameter> _paramsFor(EffectCategory category) {
    final defs = Gt1bCatalog.effectParams[category] ?? [];
    return defs.map((d) => EffectParameter.fromDef(d)).toList();
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
        parameters: _paramsFor(EffectCategory.comp),
      ),
      EffectBlock(
        id: 'od_ds',
        name: 'OD/DS',
        subtitle: 'Bass Overdrive',
        category: EffectCategory.odDs,
        accentColor: const Color(0xFFFB8C00), // Amber Gold
        isEnabled: false,
        parameters: _paramsFor(EffectCategory.odDs),
      ),
      EffectBlock(
        id: 'preamp',
        name: 'PREAMP',
        subtitle: 'Bass Preamp / Amp',
        category: EffectCategory.preamp,
        accentColor: const Color(0xFFD81B60), // Crimson Red
        isEnabled: true,
        parameters: _paramsFor(EffectCategory.preamp),
      ),
      EffectBlock(
        id: 'fx1',
        name: 'FX1',
        subtitle: 'Sub Wah / Filter',
        category: EffectCategory.fx1,
        accentColor: const Color(0xFF8E24AA), // Purple
        isEnabled: false,
        parameters: Gt1bFxAlgorithms.getParametersFor(EffectCategory.fx1, 3), // SUB WAH
      ),
      EffectBlock(
        id: 'fx2',
        name: 'FX2',
        subtitle: 'Bass Octaver / Mod',
        category: EffectCategory.fx2,
        accentColor: const Color(0xFF3949AB), // Cobalt Indigo
        isEnabled: false,
        parameters: Gt1bFxAlgorithms.getParametersFor(EffectCategory.fx2, 14), // OCTAVE
      ),
      EffectBlock(
        id: 'delay',
        name: 'DELAY',
        subtitle: 'Digital / Analog Delay',
        category: EffectCategory.delay,
        accentColor: const Color(0xFF00897B), // Teal
        isEnabled: false,
        parameters: _paramsFor(EffectCategory.delay),
      ),
      EffectBlock(
        id: 'chorus',
        name: 'CHORUS',
        subtitle: 'Stereo Chorus',
        category: EffectCategory.chorus,
        accentColor: const Color(0xFF00ACC1), // Cyan
        isEnabled: false,
        parameters: _paramsFor(EffectCategory.chorus),
      ),
      EffectBlock(
        id: 'reverb',
        name: 'REVERB',
        subtitle: 'Plate / Hall Reverb',
        category: EffectCategory.reverb,
        accentColor: const Color(0xFF5E35B1), // Deep Violet
        isEnabled: false,
        parameters: _paramsFor(EffectCategory.reverb),
      ),
      EffectBlock(
        id: 'pedal_fx',
        name: 'PEDAL FX',
        subtitle: 'Wah / Foot Bend',
        category: EffectCategory.pedalFx,
        accentColor: const Color(0xFFFF5722), // Deep Flame Orange
        isEnabled: false,
        parameters: _paramsFor(EffectCategory.pedalFx),
      ),
      EffectBlock(
        id: 'eq',
        name: 'EQ',
        subtitle: 'Parametric Equalizer',
        category: EffectCategory.eq,
        accentColor: const Color(0xFF009688), // Teal Green
        isEnabled: false,
        parameters: _paramsFor(EffectCategory.eq),
      ),
      EffectBlock(
        id: 'foot_volume',
        name: 'FOOT VOL',
        subtitle: 'Foot Volume Level',
        category: EffectCategory.footVolume,
        accentColor: const Color(0xFF8D6E63), // Copper Bronze
        isEnabled: true,
        parameters: _paramsFor(EffectCategory.footVolume),
      ),
      EffectBlock(
        id: 'ns',
        name: 'NS',
        subtitle: 'Noise Suppressor',
        category: EffectCategory.noiseSuppressor,
        accentColor: const Color(0xFF607D8B), // Slate Steel
        isEnabled: true,
        parameters: _paramsFor(EffectCategory.noiseSuppressor),
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

  /// Synchronize all 198 patch names (99 User + 99 Preset) from Boss GT-1B hardware (H9, H11)
  Future<void> syncAllPatchesFromPedal() async {
    if (_isSyncing || !midiService.isConnected) return;
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatusText = 'Leyendo presets de la GT-1B...';
    notifyListeners();

    try {
      int consecutiveFails = 0;
      // 1. Leer 99 User Patches (U01 a U99)
      for (int i = 0; i < 99; i++) {
        if (!midiService.isConnected) break;

        _syncProgress = (i + 1) / 198.0;
        _syncStatusText = 'Leyendo U${(i + 1).toString().padLeft(2, '0')}/U99...';
        notifyListeners();

        final req = GtSysEx.buildPatchNameRequest(i, isFactoryPreset: false);
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
          if (consecutiveFails > 8) break;
        }
        await Future.delayed(const Duration(milliseconds: 25));
      }

      // 2. Leer 99 Factory Presets (P01 a P99)
      consecutiveFails = 0;
      for (int i = 0; i < 99; i++) {
        if (!midiService.isConnected) break;

        _syncProgress = (99 + i + 1) / 198.0;
        _syncStatusText = 'Leyendo P${(i + 1).toString().padLeft(2, '0')}/P99...';
        notifyListeners();

        final req = GtSysEx.buildPatchNameRequest(i, isFactoryPreset: true);
        final reply = await midiService.sendSysExRequest(
          req,
          timeout: const Duration(milliseconds: 350),
        );

        if (reply != null) {
          consecutiveFails = 0;
          final name = GtSysEx.parsePatchName(reply);
          if (name != null && name.isNotEmpty) {
            _patches[99 + i] = _patches[99 + i].copyWith(name: name);
          }
        } else {
          consecutiveFails++;
          if (consecutiveFails > 8) break;
        }
        await Future.delayed(const Duration(milliseconds: 25));
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
        GtSysEx.parseActivePatchParameters(reply, currentPatch.effects);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing active patch: $e');
    }
  }

  /// Synchronize Block 1 (EQ, FX1 switch, FX1 algorithm type & parameters) from buffer (60 00 01 00)
  Future<void> syncEffectsBlock1FromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildEffectsBlock1Request();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final switches = GtSysEx.parseActiveEffectSwitches(reply);
        if (switches != null) {
          for (final effect in currentPatch.effects) {
            if (switches.containsKey(effect.category)) {
              effect.isEnabled = switches[effect.category]!;
            }
          }
        }
        final fxTypes = GtSysEx.parseFxTypes(reply);
        if (fxTypes != null && fxTypes.containsKey(EffectCategory.fx1)) {
          _applyFxAlgorithm(EffectCategory.fx1, fxTypes[EffectCategory.fx1]!);
        }
        GtSysEx.parseActivePatchParameters(reply, currentPatch.effects);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing block 1: $e');
    }
  }

  /// Synchronize Block 3 (FX2 switch, FX2 algorithm type & parameters) from buffer (60 00 03 4C)
  Future<void> syncEffectsBlock3FromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildEffectsBlock3Request();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final switches = GtSysEx.parseActiveEffectSwitches(reply);
        if (switches != null && switches.containsKey(EffectCategory.fx2)) {
          final fx2 = currentPatch.effects.where((e) => e.category == EffectCategory.fx2).firstOrNull;
          if (fx2 != null) fx2.isEnabled = switches[EffectCategory.fx2]!;
        }
        final fxTypes = GtSysEx.parseFxTypes(reply);
        if (fxTypes != null && fxTypes.containsKey(EffectCategory.fx2)) {
          _applyFxAlgorithm(EffectCategory.fx2, fxTypes[EffectCategory.fx2]!);
        }
        GtSysEx.parseActivePatchParameters(reply, currentPatch.effects);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing block 3: $e');
    }
  }

  /// Synchronize Block 5 (DELAY switch & parameters) from buffer (60 00 05 60)
  Future<void> syncEffectsBlock5FromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildEffectsBlock5Request();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final switches = GtSysEx.parseActiveEffectSwitches(reply);
        if (switches != null && switches.containsKey(EffectCategory.delay)) {
          final dly = currentPatch.effects.where((e) => e.category == EffectCategory.delay).firstOrNull;
          if (dly != null) {
            dly.isEnabled = switches[EffectCategory.delay]!;
          }
        }
        GtSysEx.parseActivePatchParameters(reply, currentPatch.effects);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing block 5: $e');
    }
  }

  /// Full synchronization of the active patch settings, effect blocks, algorithms and chain
  Future<void> syncFullActivePatch() async {
    if (!midiService.isConnected) return;
    await syncActivePatchFromPedal();
    await syncEffectsBlock1FromPedal();
    await syncEffectsBlock3FromPedal();
    await syncEffectsBlock5FromPedal();
    await syncEffectsBlock6FromPedal();
    await syncEffectsBlock7FromPedal();
    await syncFxChainFromPedal();
    await syncWahStateFromPedal();
    await syncCtlExpAndAssignsFromPedal();
  }

  /// Synchronize Block 7 (Master Level, Master EQ, BPM, Key) from buffer (60 00 07 10)
  Future<void> syncEffectsBlock7FromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildEffectsBlock7Request();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final masterMap = <String, int>{};
        GtSysEx.parseActivePatchParameters(reply, currentPatch.effects, masterValues: masterMap);
        _applyMasterMap(masterMap);
      }
    } catch (e) {
      debugPrint('Error syncing block 7: $e');
    }
  }

  /// Synchronize Control (CTL1), Expression (EXP/EXP SW), and Assign matrices from pedal
  Future<void> syncCtlExpAndAssignsFromPedal() async {
    if (!midiService.isConnected) return;
    try {
      // CTL1 / EXP SW block: 60 00 07 50, size 32 bytes
      final ctlReq = GtSysEx.buildRq1Message(
        address: [0x60, 0x00, 0x07, 0x50],
        size: [0x00, 0x00, 0x00, 0x20],
      );
      final ctlReply = await midiService.sendSysExRequest(ctlReq, timeout: const Duration(milliseconds: 400));
      if (ctlReply != null && ctlReply.length >= 12 + 0x14) {
        final d = ctlReply.sublist(12);
        _ctlExpSetting = _ctlExpSetting.copyWith(
          ctl1Func: d[0x00],
          ctl1Mode: d[0x03],
          expSwFunc: d[0x10],
        );
      }

      // EXP Pedal: 60 00 08 10, size 4 bytes
      final expReq = GtSysEx.buildRq1Message(
        address: [0x60, 0x00, 0x08, 0x10],
        size: [0x00, 0x00, 0x00, 0x04],
      );
      final expReply = await midiService.sendSysExRequest(expReq, timeout: const Duration(milliseconds: 400));
      if (expReply != null && expReply.length >= 12 + 3) {
        final d = expReply.sublist(12);
        _ctlExpSetting = _ctlExpSetting.copyWith(
          expFunc: d[0],
          expMin: d[1],
          expMax: d[2],
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing ctl/exp/assigns: $e');
    }
  }

  /// Apply FX algorithm dynamically to an active effect block
  void _applyFxAlgorithm(EffectCategory category, int algorithmIndex) {
    for (final effect in currentPatch.effects) {
      if (effect.category == category) {
        effect.parameters = Gt1bFxAlgorithms.getParametersFor(category, algorithmIndex);
        notifyListeners();
        break;
      }
    }
  }

  /// Select and set a new FX algorithm for FX1 or FX2 and send DT1 to pedal
  Future<void> setFxAlgorithm(EffectCategory category, int algorithmIndex) async {
    _applyFxAlgorithm(category, algorithmIndex);
    final address = category == EffectCategory.fx1
        ? [0x60, 0x00, 0x01, 0x41]
        : [0x60, 0x00, 0x03, 0x4D];
    await midiService.sendParameterValue(address, algorithmIndex);
  }

  /// Synchronize secondary effect switches (Chorus, Reverb, Wah, Foot Vol, NS) from buffer (60 00 06 00)
  Future<void> syncEffectsBlock6FromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildEffectsBlock6Request();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final switches = GtSysEx.parseActiveEffectSwitches(reply);
        if (switches != null) {
          for (final effect in currentPatch.effects) {
            if (switches.containsKey(effect.category)) {
              effect.isEnabled = switches[effect.category]!;
            }
          }
          if (switches.containsKey(EffectCategory.pedalFx)) {
            _isWahActive = switches[EffectCategory.pedalFx]!;
          }
        }
        GtSysEx.parseActivePatchParameters(reply, currentPatch.effects);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing block 6: $e');
    }
  }

  /// Synchronize the exact FX Chain connection line order directly from GT-1B (60 00 07 20)
  Future<void> syncFxChainFromPedal() async {
    if (!midiService.isConnected) return;
    try {
      final req = GtSysEx.buildFxChainRequest();
      final reply = await midiService.sendSysExRequest(
        req,
        timeout: const Duration(milliseconds: 400),
      );
      if (reply != null) {
        final chainIds = GtSysEx.parseFxChainOrder(reply);
        if (chainIds != null && chainIds.isNotEmpty) {
          _applyFxChainOrder(chainIds);
        }
      }
    } catch (e) {
      debugPrint('Error syncing FX chain: $e');
    }
  }

  /// Reorder the current patch effects to match hardware chain IDs
  void _applyFxChainOrder(List<int> chainIds) {
    _hardwareFxChain = List<int>.from(chainIds);
    final patch = _patches[_currentPatchIndex];
    final currentEffects = List<EffectBlock>.from(patch.effects);

    final orderedEffects = <EffectBlock>[];
    for (final id in chainIds) {
      final category = GtSysEx.chainIdToCategory[id];
      if (category != null) {
        final effect = currentEffects.where((e) => e.category == category).firstOrNull;
        if (effect != null && !orderedEffects.contains(effect)) {
          orderedEffects.add(effect);
        }
      }
    }

    for (final effect in currentEffects) {
      if (!orderedEffects.contains(effect)) {
        orderedEffects.add(effect);
      }
    }

    _patches[_currentPatchIndex] = patch.copyWith(effects: orderedEffects);
    notifyListeners();
  }

  /// Reorder a single effect slot in the current chain (H8, D5)
  void _applySingleChainSlot(int slotIndex, int chainId) {
    if (slotIndex >= 0 && slotIndex < _hardwareFxChain.length) {
      _hardwareFxChain[slotIndex] = chainId;
    }
    final category = GtSysEx.chainIdToCategory[chainId];
    if (category == null) return;
    final currentEffects = List<EffectBlock>.from(currentPatch.effects);
    final idx = currentEffects.indexWhere((e) => e.category == category);
    if (idx >= 0 && slotIndex < currentEffects.length) {
      final item = currentEffects.removeAt(idx);
      currentEffects.insert(slotIndex, item);
      _patches[_currentPatchIndex] = currentPatch.copyWith(effects: currentEffects);
      notifyListeners();
    }
  }

  /// Live hardware SysEx handler for real-time bidirectional synchronization
  void _handleIncomingHardwareSysEx(Uint8List packet) {
    if (packet.isEmpty) return;

    // 1. Standard MIDI Program Change (0xC0 [patchIndex])
    if (packet.length >= 2 && (packet[0] & 0xF0) == 0xC0) {
      final patchIdx = packet[1];
      if (patchIdx >= 0 && patchIdx < _patches.length && patchIdx != _currentPatchIndex) {
        _currentPatchIndex = patchIdx;
        notifyListeners();
        syncFullActivePatch();
      }
      return;
    }

    // 2. Roland SysEx DT1 Packet (F0 41 ... 12 [addr0 addr1 addr2 addr3] [data...] [checksum] F7)
    if (packet.length < 14) return;
    if (packet[0] != 0xF0 || packet[7] != GtSysEx.commandDt1) return;

    final a0 = packet[8];
    final a1 = packet[9];
    final a2 = packet[10];
    final a3 = packet[11];
    final val = packet[12];

    // A. Current Patch Number (00 01 00 00)
    if (a0 == 0x00 && a1 == 0x01 && a2 == 0x00 && a3 == 0x00) {
      final patchIdx = GtSysEx.parseCurrentPatchNumber(packet);
      if (patchIdx != null && patchIdx >= 0 && patchIdx < _patches.length && patchIdx != _currentPatchIndex) {
        _currentPatchIndex = patchIdx;
        notifyListeners();
        syncFullActivePatch();
      }
      return;
    }

    // B. Tuner Running Mode (7F 00 00 02)
    if (a0 == 0x7F && a1 == 0x00 && a2 == 0x00 && a3 == 0x02) {
      final tunerActive = val == 0x01;
      if (_isTunerActive != tunerActive) {
        _isTunerActive = tunerActive;
        notifyListeners();
      }
      return;
    }

    // C. FX Chain Order Changed in Hardware (60 00 07 20)
    if (a0 == 0x60 && a1 == 0x00 && a2 == 0x07 && a3 == 0x20 && packet.length >= 32) {
      final chainIds = GtSysEx.parseFxChainOrder(packet);
      if (chainIds != null && chainIds.isNotEmpty) {
        _applyFxChainOrder(chainIds);
      }
      return;
    }
    // Slot individual modificado en Memory Edit (60 00 07 20 + n) (H8, D5)
    if (a0 == 0x60 && a1 == 0x00 && a2 == 0x07 && a3 >= 0x20 && a3 <= 0x33) {
      final slotIndex = a3 - 0x20;
      _applySingleChainSlot(slotIndex, val);
      return;
    }

    // D. Individual Effect Switches (Temporary Buffer 60 00 ...)
    if (a0 == 0x60 && a1 == 0x00) {
      // COMP SW: 60 00 00 20
      if (a2 == 0x00 && a3 == 0x20) {
        _updateEffectEnabled(EffectCategory.comp, val != 0);
        return;
      }
      // OD/DS SW: 60 00 00 30
      if (a2 == 0x00 && a3 == 0x30) {
        _updateEffectEnabled(EffectCategory.odDs, val != 0);
        return;
      }
      // PREAMP SW: 60 00 00 50
      if (a2 == 0x00 && a3 == 0x50) {
        _updateEffectEnabled(EffectCategory.preamp, val != 0);
        return;
      }
      // EQ SW: 60 00 01 30
      if (a2 == 0x01 && a3 == 0x30) {
        _updateEffectEnabled(EffectCategory.eq, val != 0);
        return;
      }
      // FX1 SW: 60 00 01 40
      if (a2 == 0x01 && a3 == 0x40) {
        _updateEffectEnabled(EffectCategory.fx1, val != 0);
        return;
      }
      // FX1 FX TYPE: 60 00 01 41
      if (a2 == 0x01 && a3 == 0x41) {
        _applyFxAlgorithm(EffectCategory.fx1, val);
        return;
      }
      // FX2 SW: 60 00 03 4C
      if (a2 == 0x03 && a3 == 0x4C) {
        _updateEffectEnabled(EffectCategory.fx2, val != 0);
        return;
      }
      // FX2 FX TYPE: 60 00 03 4D
      if (a2 == 0x03 && a3 == 0x4D) {
        _applyFxAlgorithm(EffectCategory.fx2, val);
        return;
      }
      // DELAY SW: 60 00 05 60
      if (a2 == 0x05 && a3 == 0x60) {
        _updateEffectEnabled(EffectCategory.delay, val != 0);
        return;
      }
      // CHORUS SW: 60 00 06 00
      if (a2 == 0x06 && a3 == 0x00) {
        _updateEffectEnabled(EffectCategory.chorus, val != 0);
        return;
      }
      // REVERB SW: 60 00 06 10
      if (a2 == 0x06 && a3 == 0x10) {
        _updateEffectEnabled(EffectCategory.reverb, val != 0);
        return;
      }
      // WAH / PEDAL FX SW: 60 00 06 20
      if (a2 == 0x06 && a3 == 0x20) {
        _isWahActive = val != 0;
        _updateEffectEnabled(EffectCategory.pedalFx, val != 0);
        notifyListeners();
        return;
      }
      // WAH POSITION: 60 00 06 27
      if (a2 == 0x06 && a3 == 0x27) {
        _wahPosition = val;
        notifyListeners();
        return;
      }
      // FOOT VOLUME LEVEL: 60 00 06 33 (H10, D6 - nivel continuo 0..100)
      if (a2 == 0x06 && a3 == 0x33) {
        _footVolumeLevel = val;
        _updateEffectEnabled(EffectCategory.footVolume, val > 0);
        notifyListeners();
        return;
      }
      // NOISE SUPPRESSOR SW: 60 00 06 63
      if (a2 == 0x06 && a3 == 0x63) {
        _updateEffectEnabled(EffectCategory.noiseSuppressor, val != 0);
        return;
      }

      // Master Live Parameters (60 00 07 10..18)
      if (a2 == 0x07 && a3 >= 0x10 && a3 <= 0x18) {
        if (a3 == 0x10) _patchLevel = val;
        if (a3 == 0x11) _masterEqLow = val;
        if (a3 == 0x12) _masterEqMidFreq = val;
        if (a3 == 0x13) _masterEqMidQ = val;
        if (a3 == 0x14) _masterEqMidGain = val;
        if (a3 == 0x15) _masterEqHigh = val;
        if (a3 == 0x18) _masterKey = val;
        notifyListeners();
        return;
      }

      // E. Live Knob Parameter Updates (e.g. Gain, Tone, Level, Time, etc.)
      for (final effect in currentPatch.effects) {
        for (final param in effect.parameters) {
          if (param.address.length >= 4 &&
              param.address[0] == a0 &&
              param.address[1] == a1 &&
              param.address[2] == a2 &&
              param.address[3] == a3) {
            if (param.value != val) {
              param.value = val;
              notifyListeners();
            }
            return;
          }
        }
      }
    }
  }

  void _updateEffectEnabled(EffectCategory category, bool isEnabled) {
    bool changed = false;
    for (final effect in currentPatch.effects) {
      if (effect.category == category && effect.isEnabled != isEnabled) {
        effect.isEnabled = isEnabled;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
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

    // Give the GT-1B DSP 150ms to load buffer, then sync all active blocks & WAH
    await Future.delayed(const Duration(milliseconds: 150));
    await syncFullActivePatch();
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

    if (param.id == 'fx1_type') {
      _applyFxAlgorithm(EffectCategory.fx1, param.value);
    } else if (param.id == 'fx2_type') {
      _applyFxAlgorithm(EffectCategory.fx2, param.value);
    } else if (param.isEnum) {
      _applyTypeDefaults(param.id, param.value);
    }

    await midiService.sendParameterValue(param.address, param.value);
  }

  void _applyTypeDefaults(String typeParamId, int typeIndex) {
    final defaults = Gt1bTypeDefaults.getDefaults(typeParamId, typeIndex);
    if (defaults == null) return;

    for (final effect in currentPatch.effects) {
      for (final p in effect.parameters) {
        if (defaults.containsKey(p.id)) {
          p.value = defaults[p.id]!;
          if (midiService.isConnected) {
            midiService.sendParameterValue(p.address, p.value);
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> toggleTuner() async {
    _isTunerActive = !_isTunerActive;
    notifyListeners();
    await midiService.toggleTuner(_isTunerActive);
  }

  /// Reorder effect blocks in the active patch's signal chain (Memory Edit)
  void reorderEffects(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    moveEffect(oldIndex, newIndex);
  }

  /// Shift an effect block left/earlier or right/later in the chain and send to hardware
  Future<void> moveEffect(int fromIndex, int toIndex) async {
    final patch = _patches[_currentPatchIndex];
    if (fromIndex < 0 || fromIndex >= patch.effects.length) return;
    if (toIndex < 0 || toIndex >= patch.effects.length) return;

    final updatedList = List<EffectBlock>.from(patch.effects);
    final item = updatedList.removeAt(fromIndex);
    updatedList.insert(toIndex, item);

    _patches[_currentPatchIndex] = patch.copyWith(effects: updatedList);
    notifyListeners();

    // Transmit updated chain order to hardware GT-1B
    if (midiService.isConnected) {
      await _syncFxChainToHardware(updatedList);
    }
  }

  Future<void> _syncFxChainToHardware(List<EffectBlock> updatedList) async {
    final oldHardwareChain = List<int>.from(_hardwareFxChain);
    final visibleChainIds = <int>[];
    for (final eff in updatedList) {
      final cid = GtSysEx.categoryToChainId[eff.category];
      if (cid != null) visibleChainIds.add(cid);
    }
    final newHardwareChain = List<int>.from(_hardwareFxChain);
    int visibleIdx = 0;
    for (int i = 0; i < newHardwareChain.length; i++) {
      if (GtSysEx.chainIdToCategory.containsKey(newHardwareChain[i])) {
        if (visibleIdx < visibleChainIds.length) {
          newHardwareChain[i] = visibleChainIds[visibleIdx++];
        }
      }
    }
    _hardwareFxChain = newHardwareChain;

    for (int i = 0; i < 20; i++) {
      if (i >= oldHardwareChain.length || oldHardwareChain[i] != newHardwareChain[i]) {
        await midiService.sendParameterValue([0x60, 0x00, 0x07, 0x20 + i], newHardwareChain[i]);
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }

    final msg = GtSysEx.buildFxChainOrder(_hardwareFxChain);
    await midiService.sendSysEx(msg);
  }

  void _applyMasterMap(Map<String, int> map) {
    if (map.containsKey('patch_level')) _patchLevel = map['patch_level']!;
    if (map.containsKey('master_eq_low')) _masterEqLow = map['master_eq_low']!;
    if (map.containsKey('master_eq_mid_freq')) _masterEqMidFreq = map['master_eq_mid_freq']!;
    if (map.containsKey('master_eq_mid_q')) _masterEqMidQ = map['master_eq_mid_q']!;
    if (map.containsKey('master_eq_mid_gain')) _masterEqMidGain = map['master_eq_mid_gain']!;
    if (map.containsKey('master_eq_high')) _masterEqHigh = map['master_eq_high']!;
    if (map.containsKey('master_bpm')) _masterBpm = map['master_bpm']!;
    if (map.containsKey('master_key')) _masterKey = map['master_key']!;
    notifyListeners();
  }

  Future<void> updateMasterParameter(String key, int value) async {
    List<int> address;
    switch (key) {
      case 'patch_level':
        _patchLevel = value.clamp(0, 100);
        address = [0x60, 0x00, 0x07, 0x10];
        break;
      case 'master_eq_low':
        _masterEqLow = value.clamp(0, 40);
        address = [0x60, 0x00, 0x07, 0x11];
        break;
      case 'master_eq_mid_freq':
        _masterEqMidFreq = value.clamp(0, 27);
        address = [0x60, 0x00, 0x07, 0x12];
        break;
      case 'master_eq_mid_q':
        _masterEqMidQ = value.clamp(0, 5);
        address = [0x60, 0x00, 0x07, 0x13];
        break;
      case 'master_eq_mid_gain':
        _masterEqMidGain = value.clamp(0, 40);
        address = [0x60, 0x00, 0x07, 0x14];
        break;
      case 'master_eq_high':
        _masterEqHigh = value.clamp(0, 40);
        address = [0x60, 0x00, 0x07, 0x15];
        break;
      case 'master_bpm':
        _masterBpm = value.clamp(40, 250);
        address = [0x60, 0x00, 0x07, 0x16];
        break;
      case 'master_key':
        _masterKey = value.clamp(0, 11);
        address = [0x60, 0x00, 0x07, 0x18];
        break;
      default:
        return;
    }
    notifyListeners();

    if (key == 'master_bpm') {
      final msg = GtSysEx.buildDt1Message(
        address: address,
        data: [(value >> 7) & 0x7F, value & 0x7F],
      );
      await midiService.sendSysEx(msg);
    } else {
      await midiService.sendParameterValue(address, value);
    }
  }

  Future<void> updateCtlExp(CtlExpSetting setting) async {
    _ctlExpSetting = setting;
    notifyListeners();
    if (midiService.isConnected) {
      await midiService.sendParameterValue([0x60, 0x00, 0x07, 0x50], setting.ctl1Func);
      await midiService.sendParameterValue([0x60, 0x00, 0x07, 0x53], setting.ctl1Mode);
      await midiService.sendParameterValue([0x60, 0x00, 0x08, 0x10], setting.expFunc);
      await midiService.sendParameterValue([0x60, 0x00, 0x08, 0x11], setting.expMin);
      await midiService.sendParameterValue([0x60, 0x00, 0x08, 0x12], setting.expMax);
      await midiService.sendParameterValue([0x60, 0x00, 0x07, 0x60], setting.expSwFunc);
    }
  }

  Future<void> updateAssign(int index, AssignSetting setting) async {
    if (index < 0 || index >= _assigns.length) return;
    _assigns[index] = setting;
    notifyListeners();

    if (midiService.isConnected) {
      final baseAddresses = [
        [0x60, 0x00, 0x08, 0x30],
        [0x60, 0x00, 0x08, 0x50],
        [0x60, 0x00, 0x08, 0x70],
        [0x60, 0x00, 0x09, 0x10],
        [0x60, 0x00, 0x09, 0x30],
        [0x60, 0x00, 0x09, 0x50],
        [0x60, 0x00, 0x09, 0x70],
        [0x60, 0x00, 0x0A, 0x10],
      ];
      final base = baseAddresses[index];
      await midiService.sendParameterValue(base, setting.isEnabled ? 1 : 0);
      final targetMsg = GtSysEx.buildDt1Message(
        address: [base[0], base[1], base[2], base[3] + 1],
        data: [(setting.target >> 7) & 0x7F, setting.target & 0x7F],
      );
      await midiService.sendSysEx(targetMsg);
      final minMsg = GtSysEx.buildDt1Message(
        address: [base[0], base[1], base[2], base[3] + 3],
        data: [(setting.targetMin >> 7) & 0x7F, setting.targetMin & 0x7F],
      );
      await midiService.sendSysEx(minMsg);
      final maxMsg = GtSysEx.buildDt1Message(
        address: [base[0], base[1], base[2], base[3] + 5],
        data: [(setting.targetMax >> 7) & 0x7F, setting.targetMax & 0x7F],
      );
      await midiService.sendSysEx(maxMsg);
      await midiService.sendParameterValue([base[0], base[1], base[2], base[3] + 7], setting.source);
      await midiService.sendParameterValue([base[0], base[1], base[2], base[3] + 8], setting.sourceMode);
    }
  }
}
