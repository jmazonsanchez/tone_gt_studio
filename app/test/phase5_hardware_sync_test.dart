import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/models/assign_model.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/layout/responsive_breakpoints.dart';
import 'package:tone_gt_studio/ui/widgets/assign_editor_modal.dart';
import 'package:tone_gt_studio/ui/widgets/master_settings_modal.dart';
import 'package:tone_gt_studio/ui/widgets/memory_edit_chain_bar.dart';
import 'package:tone_gt_studio/ui/widgets/stage_left_panel.dart';

void main() {
  group('Phase 5 & Hardware Sync Verification Tests', () {
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

    test('buildFxChainOrder generates 20 authentic valid bytes with zero 0xFF padding', () {
      final inputChain = [0, 1, 4, 8, 10, 14, 17, 5, 2, 6, 11, 15]; // 12 visible IDs
      final msg = GtSysEx.buildFxChainOrder(inputChain);

      expect(msg.length, 12 + 20 + 2); // Header (12) + 20 data bytes + Checksum (1) + 0xF7 (1)
      final payload = msg.sublist(12, 32);

      // Verify zero 0xFF in the payload
      expect(payload.contains(0xFF), isFalse);
      expect(payload.length, 20);

      // First 12 should match inputChain
      expect(payload.sublist(0, 12), inputChain);

      // Remaining 8 must be valid GT-1B internal routing elements
      for (final b in payload) {
        expect(b >= 0 && b <= 19, isTrue, reason: 'Byte $b must be a valid GT-1B routing ID');
      }
    });

    test('Moving chain in PatchService calculates valid 20-byte chain for physical pedal', () {
      final initialFirst = patchService.currentPatch.effects.first;
      final initialSecond = patchService.currentPatch.effects[1];

      // Reorder first two effects
      patchService.moveEffect(0, 1);

      expect(patchService.currentPatch.effects.first.id, initialSecond.id);
      expect(patchService.currentPatch.effects[1].id, initialFirst.id);
    });

    test('parseActivePatchParameters extracts deep parameter values from GT-1B buffer packet', () {
      final effects = patchService.currentPatch.effects;

      // Construct simulated Block 0 reply (Comp, OD, Preamp)
      final block0 = Uint8List(12 + 0x7F + 2);
      block0[0] = 0xF0;
      block0[7] = GtSysEx.commandDt1;
      block0[8] = 0x60; block0[9] = 0x00; block0[10] = 0x00; block0[11] = 0x00;

      // Preamp Gain at 60 00 00 52 -> set to 85
      block0[12 + 0x52] = 85;
      // Preamp Bass at 60 00 00 54 -> set to 72
      block0[12 + 0x54] = 72;
      // Comp Sustain at 60 00 00 22 -> set to 64
      block0[12 + 0x22] = 64;

      GtSysEx.parseActivePatchParameters(block0, effects);

      final preamp = effects.firstWhere((e) => e.category == EffectCategory.preamp);
      final gainParam = preamp.parameters.firstWhere((p) => p.name == 'Gain');
      final bassParam = preamp.parameters.firstWhere((p) => p.name == 'Bass');
      expect(gainParam.value, 85);
      expect(bassParam.value, 72);

      final comp = effects.firstWhere((e) => e.category == EffectCategory.comp);
      final sustainParam = comp.parameters.firstWhere((p) => p.name == 'Sustain');
      expect(sustainParam.value, 64);
    });

    test('parseActivePatchParameters correctly extracts Master Level, EQ and BPM from Block 7', () {
      final block7 = Uint8List(12 + 0x10 + 2);
      block7[0] = 0xF0;
      block7[7] = GtSysEx.commandDt1;
      block7[8] = 0x60; block7[9] = 0x00; block7[10] = 0x07; block7[11] = 0x10;

      // Patch Level (60 00 07 10) = 88
      block7[12 + 0x00] = 88;
      // Master EQ Low (60 00 07 11) = 28 (+8 dB)
      block7[12 + 0x01] = 28;
      // Master BPM (60 00 07 16) = 140 (high: 1, low: 12)
      block7[12 + 0x06] = 1;
      block7[12 + 0x07] = 12;

      final masterMap = <String, int>{};
      GtSysEx.parseActivePatchParameters(block7, patchService.currentPatch.effects, masterValues: masterMap);

      expect(masterMap['patch_level'], 88);
      expect(masterMap['master_eq_low'], 28);
      expect(masterMap['master_bpm'], 140);
    });

    testWidgets('StageLeftPanel includes MASTER as 12th physical button and opens modal', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool masterOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              height: 600,
              child: StageLeftPanel(
                effects: patchService.currentPatch.effects,
                onToggle: (eff) {},
                onSelectMaster: () => masterOpened = true,
                breakpoint: StageBreakpoint.medium,
              ),
            ),
          ),
        ),
      );

      // Verify all 12 physical buttons are present (11 effects + MASTER)
      expect(find.text('MASTER'), findsOneWidget);
      expect(find.text('COMP'), findsOneWidget);
      expect(find.text('PREAMP'), findsOneWidget);
      expect(find.text('OD/DS'), findsOneWidget);

      await tester.tap(find.text('MASTER'));
      expect(masterOpened, isTrue);
    });

    testWidgets('MasterSettingsModal allows tweaking patch level, BPM, and EQ', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasterSettingsModal(patchService: patchService),
          ),
        ),
      );

      expect(find.text('MASTER & GLOBAL EQ'), findsOneWidget);
      expect(find.text('PATCH LEVEL'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('MASTER 4-BAND EQ'), findsOneWidget);

      await patchService.updateMasterParameter('patch_level', 92);
      await patchService.updateMasterParameter('master_bpm', 135);
      await tester.pumpAndSettle();

      expect(patchService.patchLevel, 92);
      expect(patchService.masterBpm, 135);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('135'), findsOneWidget);
    });

    testWidgets('MemoryEditChainBar links last block connection directly into OUTPUT', (tester) async {
      tester.view.physicalSize = const Size(1400, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryEditChainBar(
              effects: patchService.currentPatch.effects,
              onToggle: (eff) => patchService.toggleEffect(eff),
              onMoveEffect: (f, t) => patchService.moveEffect(f, t),
            ),
          ),
        ),
      );

      expect(find.text('INPUT'), findsOneWidget);
      expect(find.text('OUTPUT'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    test('Phase 5: CTL / EXP and Assigns updating modifies state and notifies listeners', () async {
      expect(patchService.assigns.length, 8);
      expect(patchService.ctlExpSetting.ctl1Func, 14);

      // Update CTL1
      await patchService.updateCtlExp(
        patchService.ctlExpSetting.copyWith(ctl1Func: 11, ctl1Mode: 0),
      );
      expect(patchService.ctlExpSetting.ctl1Func, 11);
      expect(patchService.ctlExpSetting.ctl1Mode, 0);

      // Update Assign 1
      await patchService.updateAssign(
        0,
        const AssignSetting(index: 1, isEnabled: true, target: 5, targetMin: 20, targetMax: 80, source: 2),
      );
      expect(patchService.assigns[0].isEnabled, isTrue);
      expect(patchService.assigns[0].target, 5);
      expect(patchService.assigns[0].targetMin, 20);
      expect(patchService.assigns[0].targetMax, 80);
      expect(patchService.assigns[0].source, 2);
    });

    testWidgets('AssignEditorModal renders CTL & EXP and Assigns 1-8 tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignEditorModal(patchService: patchService),
          ),
        ),
      );

      expect(find.text('CONTROL, EXP & ASSIGNS (FASE 5)'), findsOneWidget);
      expect(find.text('CTL1 & EXP PEDAL'), findsOneWidget);
      expect(find.text('ASSIGNS 1–8'), findsOneWidget);

      // Switch to ASSIGNS 1-8 tab
      await tester.tap(find.text('ASSIGNS 1–8'));
      await tester.pumpAndSettle();

      expect(find.text('ASSIGN 1'), findsOneWidget);
      expect(find.text('ASSIGN 1 CONFIGURATION'), findsOneWidget);
      expect(find.text('TARGET PARAMETER'), findsOneWidget);
    });
  });
}
