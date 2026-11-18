import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/effect_block.dart';
import '../models/patch.dart';
import 'midi_service.dart';

class PatchService extends ChangeNotifier {
  final MidiService midiService;
  int _currentPatchIndex = 0;
  bool _isTunerActive = false;

  PatchService(this.midiService) {
    _initializeDefaultPatches();
  }

  int get currentPatchIndex => _currentPatchIndex;
  bool get isTunerActive => _isTunerActive;
  Patch get currentPatch => _patches[_currentPatchIndex];
  List<Patch> get patches => List.unmodifiable(_patches);

  final List<Patch> _patches = [];

  void _initializeDefaultPatches() {
    final List<String> presetNames = [
      'Slap & Funk Bass',
      'Modern Rock Drive',
      'Vintage Warm Tube',
      'Fretless Chorus',
      'Sub Synth & Wah',
      'Heavy Metal Growl',
      'Fingerstyle Clean',
      'Ambient Delay Spac',
      'Motown 60s Thump',
      'Solo Boost & Reverb',
    ];

    for (int i = 0; i < 99; i++) {
      final name = i < presetNames.length ? presetNames[i] : 'User Patch ${i + 1}';
      _patches.add(
        Patch(
          index: i,
          name: name,
          effects: [
            EffectBlock(id: 'comp', name: 'COMP', subtitle: 'Limiter / Comp', category: EffectCategory.comp, accentColor: Colors.blue, isEnabled: true),
            EffectBlock(id: 'od_ds', name: 'OD/DS', subtitle: 'Bass Overdrive', category: EffectCategory.odDs, accentColor: Colors.orange, isEnabled: i % 2 == 1),
            EffectBlock(id: 'preamp', name: 'PREAMP', subtitle: 'Concert 810', category: EffectCategory.preamp, accentColor: Colors.amber, isEnabled: true),
            EffectBlock(id: 'fx1', name: 'FX1', subtitle: 'Sub Wah', category: EffectCategory.fx1, accentColor: Colors.purple, isEnabled: false),
            EffectBlock(id: 'fx2', name: 'FX2', subtitle: 'Bass Octaver', category: EffectCategory.fx2, accentColor: Colors.indigo, isEnabled: false),
            EffectBlock(id: 'delay', name: 'DELAY', subtitle: 'Tape Echo', category: EffectCategory.delay, accentColor: Colors.teal, isEnabled: i % 3 == 0),
            EffectBlock(id: 'chorus', name: 'CHORUS', subtitle: 'Stereo Chorus', category: EffectCategory.chorus, accentColor: Colors.cyan, isEnabled: i % 4 == 0),
            EffectBlock(id: 'reverb', name: 'REVERB', subtitle: 'Plate Reverb', category: EffectCategory.reverb, accentColor: Colors.deepPurple, isEnabled: true),
          ],
        ),
      );
    }
  }

  Future<void> selectPatch(int index) async {
    if (index < 0 || index >= _patches.length) return;
    _currentPatchIndex = index;
    notifyListeners();
    await midiService.changePatch(index);
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
    notifyListeners();
    await midiService.toggleEffect(effect.category, newState);
  }

  Future<void> toggleTuner() async {
    _isTunerActive = !_isTunerActive;
    notifyListeners();
    await midiService.toggleTuner(_isTunerActive);
  }
}
