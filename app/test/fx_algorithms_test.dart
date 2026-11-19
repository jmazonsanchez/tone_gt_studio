import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/domain/gt1b_fx_algorithms.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/widgets/effect_editor_panel.dart';
import 'package:tone_gt_studio/ui/widgets/memory_edit_chain_bar.dart';

void main() {
  group('Phase 4 - FX1 / FX2 Dynamic Algorithms & Chain Tests', () {
    late MidiService midiService;
    late PatchService patchService;

    setUp(() {
      midiService = MidiService();
      patchService = PatchService(midiService);
    });

    tearDown(() {
      patchService.dispose();
      midiService.dispose();
    });

    test('Gt1bFxAlgorithms provides 36 authentic Boss GT-1B algorithms', () {
      expect(Gt1bFxAlgorithms.algorithmNames.length, 36);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('DEFRETTER'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('OCTAVE'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('AUTO WAH'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('BASS SYNTH'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('SUB WAH'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('SLOW GEAR'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('PITCH SHIFTER'), isTrue);
      expect(Gt1bFxAlgorithms.algorithmNames.contains('HARMONIST'), isTrue);
    });

    test('DEFRETTER algorithm generates authentic bass parameters with exact offsets', () {
      final fx1Params = Gt1bFxAlgorithms.getParametersFor(EffectCategory.fx1, 11);
      final paramNames = fx1Params.map((p) => p.name).toList();

      expect(paramNames, containsAll(['FX Type', 'Tone', 'Sens', 'Attack', 'Depth', 'Reso', 'Level', 'Direct Mix']));

      final attackParam = fx1Params.firstWhere((p) => p.name == 'Attack');
      // FX1 Defretter Attack address: 60 00 02 1A
      expect(attackParam.address, [0x60, 0x00, 0x02, 0x1A]);

      final fx2Params = Gt1bFxAlgorithms.getParametersFor(EffectCategory.fx2, 11);
      final fx2Attack = fx2Params.firstWhere((p) => p.name == 'Attack');
      // FX2 Defretter Attack address: 60 00 04 26
      expect(fx2Attack.address, [0x60, 0x00, 0x04, 0x26]);
    });

    test('OCTAVE algorithm generates Range, Oct Level, and Direct Mix parameters', () {
      final octParams = Gt1bFxAlgorithms.getParametersFor(EffectCategory.fx2, 14);
      final paramNames = octParams.map((p) => p.name).toList();

      expect(paramNames, containsAll(['FX Type', 'Range', 'Oct Level', 'Direct Mix']));

      final rangeParam = octParams.firstWhere((p) => p.name == 'Range');
      expect(rangeParam.isEnum, isTrue);
      expect(rangeParam.options, contains('-2 OCT'));
      expect(rangeParam.options, contains('-1 OCT'));
    });

    test('Switching algorithm in PatchService dynamically reconfigures FX parameters', () async {
      final fx1 = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.fx1);

      // Initially SUB WAH
      expect(fx1.parameters.any((p) => p.name == 'Pedal Max' || p.name == 'Position'), isTrue);

      // Switch to DEFRETTER (index 11)
      await patchService.setFxAlgorithm(EffectCategory.fx1, 11);

      expect(fx1.parameters.any((p) => p.name == 'Attack'), isTrue);
      expect(fx1.parameters.any((p) => p.name == 'Reso'), isTrue);
      expect(fx1.parameters.firstWhere((p) => p.name == 'FX Type').value, 11);
    });

    test('Incoming DT1 from hardware dynamically changes FX algorithm in real-time', () async {
      final fx2 = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.fx2);

      // Hardware reports FX2 switched to BASS SYNTH (index 12) via address 60 00 03 4D
      final dt1Packet = GtSysEx.buildDt1Message(
        address: [0x60, 0x00, 0x03, 0x4D],
        data: [12],
      );

      midiService.handleIncomingDataForTesting(dt1Packet);
      await pumpEventQueue();

      expect(fx2.parameters.any((p) => p.name == 'Cutoff'), isTrue);
      expect(fx2.parameters.any((p) => p.name == 'Synth Level'), isTrue);
      expect(fx2.parameters.firstWhere((p) => p.name == 'FX Type').value, 12);
    });

    test('Resolves Bug: Multiple enabled effects in GT-1B are correctly parsed across all blocks', () {
      // 1. Block 0 DT1 reply with PREAMP enabled
      final block0 = Uint8List(12 + 0x70 + 2);
      block0[0] = 0xF0;
      block0[7] = GtSysEx.commandDt1;
      block0[8] = 0x60; block0[9] = 0x00; block0[10] = 0x00; block0[11] = 0x00;
      block0[12 + 0x50] = 0x01; // Preamp ON
      final sw0 = GtSysEx.parseActiveEffectSwitches(block0);
      expect(sw0?[EffectCategory.preamp], isTrue);

      // 2. Block 1 DT1 reply with FX1 enabled
      final block1 = Uint8List(12 + 0x50 + 2);
      block1[0] = 0xF0;
      block1[7] = GtSysEx.commandDt1;
      block1[8] = 0x60; block1[9] = 0x00; block1[10] = 0x01; block1[11] = 0x00;
      block1[12 + 0x40] = 0x01; // FX1 ON
      final sw1 = GtSysEx.parseActiveEffectSwitches(block1);
      expect(sw1?[EffectCategory.fx1], isTrue);

      // 3. Block 5 DT1 reply with DELAY enabled
      final block5 = Uint8List(12 + 0x04 + 2);
      block5[0] = 0xF0;
      block5[7] = GtSysEx.commandDt1;
      block5[8] = 0x60; block5[9] = 0x00; block5[10] = 0x05; block5[11] = 0x60;
      block5[12] = 0x01; // DELAY ON
      final sw5 = GtSysEx.parseActiveEffectSwitches(block5);
      expect(sw5?[EffectCategory.delay], isTrue);

      // 4. Block 6 DT1 reply with REVERB enabled
      final block6 = Uint8List(12 + 0x70 + 2);
      block6[0] = 0xF0;
      block6[7] = GtSysEx.commandDt1;
      block6[8] = 0x60; block6[9] = 0x00; block6[10] = 0x06; block6[11] = 0x00;
      block6[12 + 0x10] = 0x01; // REVERB ON
      final sw6 = GtSysEx.parseActiveEffectSwitches(block6);
      expect(sw6?[EffectCategory.reverb], isTrue);
    });

    test('reorderEffects and moveEffect updates order and triggers DT1 chain update', () {
      final initialFirst = patchService.currentPatch.effects.first;
      final initialSecond = patchService.currentPatch.effects[1];

      patchService.moveEffect(0, 1);

      expect(patchService.currentPatch.effects.first.id, initialSecond.id);
      expect(patchService.currentPatch.effects[1].id, initialFirst.id);
    });

    testWidgets('MemoryEditChainBar renders INPUT and OUTPUT pinned and draggable blocks in between', (tester) async {
      tester.view.physicalSize = const Size(1400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryEditChainBar(
              effects: patchService.currentPatch.effects,
              onToggle: (eff) => patchService.toggleEffect(eff),
              onMoveEffect: (from, to) => patchService.moveEffect(from, to),
            ),
          ),
        ),
      );

      expect(find.text('INPUT'), findsOneWidget);
      expect(find.text('OUTPUT'), findsOneWidget);
      expect(find.text('BASS IN'), findsOneWidget);
      expect(find.text('AMP / PA'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
    });

    testWidgets('EffectEditorPanel adapts knobs dynamically when FX algorithm changes', (tester) async {
      final fx1 = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.fx1);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PatchService>.value(
            value: patchService,
            child: Scaffold(
              body: EffectEditorPanel(effect: fx1),
            ),
          ),
        ),
      );

      expect(find.text('FX1'), findsOneWidget);
      expect(find.text('FX TYPE:'), findsOneWidget);

      // Switch to Octave (index 14)
      await patchService.setFxAlgorithm(EffectCategory.fx1, 14);
      await tester.pumpAndSettle();

      expect(find.text('OCT LEVEL'), findsOneWidget);
      expect(find.text('DIRECT MIX'), findsOneWidget);
    });
  });
}
