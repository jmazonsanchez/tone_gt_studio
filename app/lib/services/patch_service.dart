import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/effect_block.dart';
import '../models/effect_parameter.dart';
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
      'Ambient Delay Space',
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
            EffectBlock(
              id: 'comp',
              name: 'COMP',
              subtitle: 'Limiter / Comp',
              category: EffectCategory.comp,
              accentColor: Colors.blue,
              isEnabled: true,
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
              accentColor: Colors.orange,
              isEnabled: i % 2 == 1,
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
              accentColor: Colors.amber,
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
              subtitle: 'Sub Wah',
              category: EffectCategory.fx1,
              accentColor: Colors.purple,
              isEnabled: false,
              parameters: [
                EffectParameter(id: 'fx1_sens', name: 'Sens', address: [0x60, 0x00, 0x04, 0x12], value: 60),
                EffectParameter(id: 'fx1_peak', name: 'Peak', address: [0x60, 0x00, 0x04, 0x14], value: 50),
              ],
            ),
            EffectBlock(
              id: 'fx2',
              name: 'FX2',
              subtitle: 'Bass Octaver',
              category: EffectCategory.fx2,
              accentColor: Colors.indigo,
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
              accentColor: Colors.teal,
              isEnabled: i % 3 == 0,
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
              accentColor: Colors.cyan,
              isEnabled: i % 4 == 0,
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
              accentColor: Colors.deepPurple,
              isEnabled: true,
              parameters: [
                EffectParameter(id: 'rev_time', name: 'Time', address: [0x60, 0x00, 0x06, 0x12], value: 45),
                EffectParameter(id: 'rev_level', name: 'Level', address: [0x60, 0x00, 0x06, 0x18], value: 40),
              ],
            ),
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
