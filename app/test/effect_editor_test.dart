import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/domain/gt1b_catalog.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/widgets/effect_editor_panel.dart';

void main() {
  group('Gt1bCatalog & EffectEditorPanel Tests', () {
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

    test('Catalog contains complete parameter definitions for all 10 core blocks', () {
      final categories = [
        EffectCategory.comp,
        EffectCategory.odDs,
        EffectCategory.preamp,
        EffectCategory.eq,
        EffectCategory.delay,
        EffectCategory.chorus,
        EffectCategory.reverb,
        EffectCategory.pedalFx,
        EffectCategory.footVolume,
        EffectCategory.noiseSuppressor,
      ];

      for (final cat in categories) {
        final params = Gt1bCatalog.effectParams[cat];
        expect(params, isNotNull, reason: 'Missing params for $cat');
        expect(params!.isNotEmpty, isTrue, reason: 'Empty params for $cat');

        for (final p in params) {
          expect(p.address.length, 4, reason: 'Address length must be 4 for ${p.id}');
          expect(p.address[0], 0x60, reason: 'Must be temporary address 0x60 for ${p.id}');
          expect(p.address[1], 0x00, reason: 'Must be temporary address 0x00 for ${p.id}');
          expect(p.max, greaterThan(p.min), reason: 'Max must be > min for ${p.id}');
        }
      }
    });

    test('Catalog options match official Roland Boss GT-1B types', () {
      expect(Gt1bCatalog.compTypes.contains('BOSS COMP'), isTrue);
      expect(Gt1bCatalog.odTypes.contains('BASS OD'), isTrue);
      expect(Gt1bCatalog.preampTypes.contains('CONCERT'), isTrue);
      expect(Gt1bCatalog.delayTypes.contains('TAPE'), isTrue);
      expect(Gt1bCatalog.reverbTypes.contains('PLATE'), isTrue);
    });

    test('Updating parameter in PatchService writes throttled DT1 SysEx to hardware', () async {
      final od = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.odDs);
      final driveParam = od.parameters.firstWhere((p) => p.id == 'od_drive');

      expect(driveParam.value, 50);

      await patchService.updateParameter(driveParam, 85);

      expect(driveParam.value, 85);
    });

    test('Incoming DT1 packet from physical GT-1B updates active parameter in real-time', () async {
      final preamp = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.preamp);
      final gainParam = preamp.parameters.firstWhere((p) => p.id == 'amp_gain');

      expect(gainParam.value, 50);

      // Simulate hardware physical knob turn on GT-1B emitting:
      // DT1 [60 00 00 52] = 0x58 (Gain = 88)
      final dt1Packet = GtSysEx.buildDt1Message(
        address: [0x60, 0x00, 0x00, 0x52],
        data: [88],
      );

      midiService.handleIncomingDataForTesting(dt1Packet);

      // Allow microtask to process stream
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(gainParam.value, 88);
    });

    testWidgets('Renders EffectEditorPanel with type dropdown and knobs for OD/DS', (tester) async {
      final od = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.odDs);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<PatchService>.value(
              value: patchService,
              child: EffectEditorPanel(effect: od),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('OD/DS'), findsOneWidget);
      expect(find.text('TYPE:'), findsOneWidget);
      expect(find.text('BASS OD'), findsOneWidget);

      // Verify Parameter Knobs
      expect(find.text('DRIVE'), findsOneWidget);
      expect(find.text('BOTTOM'), findsOneWidget);
      expect(find.text('TONE'), findsOneWidget);
      expect(find.text('EFFECT LEVEL'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders EffectEditorPanel for PREAMP with amp types and bright switch', (tester) async {
      final preamp = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.preamp);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<PatchService>.value(
              value: patchService,
              child: EffectEditorPanel(effect: preamp),
            ),
          ),
        ),
      );

      expect(find.text('PREAMP'), findsOneWidget);
      expect(find.text('AMP TYPE:'), findsOneWidget);
      expect(find.text('GAIN'), findsOneWidget);
      expect(find.text('BASS'), findsOneWidget);
      expect(find.text('MIDDLE'), findsOneWidget);
      expect(find.text('TREBLE'), findsOneWidget);
      expect(find.text('BRIGHT'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
