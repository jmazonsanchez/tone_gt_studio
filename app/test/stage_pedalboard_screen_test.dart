import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/screens/stage_pedalboard_screen.dart';
import 'package:tone_gt_studio/ui/widgets/stage_header_bar.dart';

void main() {
  group('StagePedalboardScreen Widget Tests', () {
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

    Widget createTestWidget() {
      return MaterialApp(
        home: AnimatedBuilder(
          animation: patchService,
          builder: (context, _) => StagePedalboardScreen(
            midi: midiService,
            patchService: patchService,
            isDemoMode: true,
            onExitDemo: () {},
            onConnectRequest: () {},
          ),
        ),
      );
    }

    testWidgets('Renders all 3 landscape zones and header bar', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // Verify Header elements
      expect(find.text('MODO DEMO'), findsOneWidget);
      expect(find.descendant(of: find.byType(StageHeaderBar), matching: find.text('U01')), findsOneWidget);

      // Verify Zone 1 (Left panel Master configuration)
      expect(find.text('CONFIGURACIÓN MASTER'), findsOneWidget);
      expect(find.text('PATCH LEVEL'), findsOneWidget);

      // Verify Zone 2 (Center panel: chain bar & pedals)
      expect(find.text('MEMORY EDIT'), findsOneWidget);

      // Verify Zone 3 (Right panel: EXP & Foot Volume)
      expect(find.text('EXP / VOLUMEN'), findsOneWidget);
      expect(find.text('FOOT VOL'), findsWidgets);
      expect(find.text('WAH TOE'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays FABRICA badge for factory presets (index >= 99)', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // Switch to patch 99 (P01)
      patchService.selectPatch(99);
      // Advance fake timer to clear the 150ms debounce
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('P01'), findsOneWidget);
      expect(find.text('FABRICA'), findsOneWidget);
    });

    testWidgets('Tapping next patch advances patch index', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      expect(patchService.currentPatchIndex, 0);
      expect(find.descendant(of: find.byType(StageHeaderBar), matching: find.text('U01')), findsOneWidget);

      // Tap next button
      await tester.tap(find.byKey(const Key('next-patch-btn')));
      // Advance fake timer to clear debounce
      await tester.pump(const Duration(milliseconds: 200));

      expect(patchService.currentPatchIndex, 1);
      expect(find.descendant(of: find.byType(StageHeaderBar), matching: find.text('U02')), findsOneWidget);
    });
  });
}
