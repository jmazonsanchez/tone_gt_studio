import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/layout/responsive_breakpoints.dart';
import 'package:tone_gt_studio/ui/widgets/master_workbench_view.dart';
import 'package:tone_gt_studio/ui/widgets/stage_center_panel.dart';

void main() {
  group('MasterWorkbenchView & Option 1 Integration Tests', () {
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

    testWidgets('MasterWorkbenchView renders all 3 finger-friendly console stations', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: MasterWorkbenchView(
                patchService: patchService,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('ESTACIÓN DE TRABAJO MASTER'), findsOneWidget);
      expect(find.text('VOLVER A EFECTOS'), findsOneWidget);

      // Verify Station 1: Patch Level
      expect(find.text('PATCH LEVEL'), findsOneWidget);

      // Verify Station 2: Tempo & Key + Giant Tap Tempo
      expect(find.text('TEMPO & TONO'), findsOneWidget);
      expect(find.text('TAP TEMPO'), findsOneWidget);
      expect(find.text('Toca el ritmo'), findsOneWidget);

      // Verify Station 3: Master 4-Band EQ
      expect(find.text('MASTER 4-BAND EQ'), findsOneWidget);
      expect(find.text('LOW GAIN'), findsOneWidget);
      expect(find.text('MID GAIN'), findsOneWidget);
      expect(find.text('HIGH GAIN'), findsOneWidget);
      expect(find.text('FREQ:'), findsOneWidget);
      expect(find.text('Q:'), findsOneWidget);
    });

    testWidgets('Tapping OUTPUT in signal chain selects Master Workbench and allows closing', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 600,
              child: StageCenterPanel(
                patchService: patchService,
                effects: patchService.currentPatch.effects,
                onToggleEffect: (e) => patchService.toggleEffect(e),
                onMoveEffect: (f, t) => patchService.moveEffect(f, t),
                breakpoint: StageBreakpoint.medium,
              ),
            ),
          ),
        ),
      );

      // Initially, active effect workbench is shown, Master Workbench is not shown
      expect(find.text('ESTACIÓN DE TRABAJO MASTER'), findsNothing);

      // Find and tap OUTPUT terminal node in signal chain
      final outputNode = find.text('OUTPUT');
      expect(outputNode, findsOneWidget);
      await tester.tap(outputNode);
      await tester.pump();

      // Now Master Workbench is visible!
      expect(find.text('ESTACIÓN DE TRABAJO MASTER'), findsOneWidget);
      expect(find.text('TAP TEMPO'), findsOneWidget);

      // Tap VOLVER A EFECTOS to return to effect slot
      await tester.tap(find.text('VOLVER A EFECTOS'));
      await tester.pump();

      expect(find.text('ESTACIÓN DE TRABAJO MASTER'), findsNothing);
    });

    testWidgets('Tapping Giant Tap Tempo updates BPM', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int currentTime = 1000000;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: MasterWorkbenchView(
                patchService: patchService,
                onClose: () {},
                clock: () => DateTime.fromMillisecondsSinceEpoch(currentTime),
              ),
            ),
          ),
        ),
      );

      final tapTempoBtn = find.text('TAP TEMPO');
      expect(tapTempoBtn, findsOneWidget);

      // Tap 1
      await tester.tap(tapTempoBtn);
      currentTime += 500; // 500ms = 120 BPM
      await tester.pump();

      // Tap 2
      await tester.tap(tapTempoBtn);
      currentTime += 500;
      await tester.pump();

      // Tap 3
      await tester.tap(tapTempoBtn);
      await tester.pump();

      expect(patchService.masterBpm, 120);
    });
  });
}
