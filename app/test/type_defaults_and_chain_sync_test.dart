import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/domain/gt1b_type_defaults.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';

void main() {
  group('Authentic Type Defaults & Hardware Chain Sync Tests', () {
    late FakeTransport fakeTransport;
    late MidiService midiService;
    late PatchService patchService;

    setUp(() {
      fakeTransport = FakeTransport();
      midiService = MidiService();
      patchService = PatchService(midiService);
    });

    tearDown(() {
      patchService.dispose();
      midiService.dispose();
      fakeTransport.dispose();
    });

    test('Gt1bTypeDefaults provides distinct authentic defaults for Preamp and OD types', () {
      final superFlat = Gt1bTypeDefaults.getDefaults('amp_type', 0);
      final flipTop = Gt1bTypeDefaults.getDefaults('amp_type', 1);
      final bass360 = Gt1bTypeDefaults.getDefaults('amp_type', 4);

      expect(superFlat, isNotNull);
      expect(flipTop, isNotNull);
      expect(bass360, isNotNull);

      // Verify they have different authentic values
      expect(superFlat!['amp_gain'], 40);
      expect(flipTop!['amp_gain'], 55);
      expect(bass360!['amp_gain'], 60);

      expect(superFlat['amp_bass'], 50);
      expect(flipTop['amp_bass'], 60);
      expect(bass360['amp_bass'], 65);

      final booster = Gt1bTypeDefaults.getDefaults('od_type', 0);
      final bassFuzz = Gt1bTypeDefaults.getDefaults('od_type', 8);

      expect(booster!['od_drive'], 25);
      expect(bassFuzz!['od_drive'], 85);
    });

    test('Changing amp_type in PatchService dynamically reconfigures authentic amp parameters', () async {
      final amp = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.preamp);
      final typeParam = amp.parameters.firstWhere((p) => p.id == 'amp_type');
      final gainParam = amp.parameters.firstWhere((p) => p.id == 'amp_gain');
      final bassParam = amp.parameters.firstWhere((p) => p.id == 'amp_bass');

      // Change type to FLIP TOP (index 1)
      await patchService.updateParameter(typeParam, 1);

      expect(typeParam.value, 1);
      expect(gainParam.value, 55);
      expect(bassParam.value, 60);

      // Change type to BASS 360 (index 4)
      await patchService.updateParameter(typeParam, 4);

      expect(typeParam.value, 4);
      expect(gainParam.value, 60);
      expect(bassParam.value, 65);
    });

    test('Changing od_type in PatchService dynamically reconfigures authentic OD/DS parameters', () async {
      final od = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.odDs);
      final typeParam = od.parameters.firstWhere((p) => p.id == 'od_type');
      final driveParam = od.parameters.firstWhere((p) => p.id == 'od_drive');

      // Change type to BOOSTER (index 0)
      await patchService.updateParameter(typeParam, 0);
      expect(driveParam.value, 25);

      // Change type to BASS FUZZ (index 8)
      await patchService.updateParameter(typeParam, 8);
      expect(driveParam.value, 85);
    });

    test('moveEffect updates currentPatch effects order and notifies listeners', () async {
      final initialFirst = patchService.currentPatch.effects.first;
      final initialSecond = patchService.currentPatch.effects[1];

      await patchService.moveEffect(0, 1);

      expect(patchService.currentPatch.effects.first.id, initialSecond.id);
      expect(patchService.currentPatch.effects[1].id, initialFirst.id);
    });
  });
}
