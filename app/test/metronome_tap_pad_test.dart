import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/theme/app_theme.dart';
import 'package:tone_gt_studio/ui/widgets/metronome_tap_pad.dart';
import 'package:tone_gt_studio/ui/widgets/system_metronome_tab.dart';

void main() {
  group('Metronome Visual & 4-Tap Tempo Pad Tests', () {
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

    Widget wrap(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MidiService>.value(value: midiService),
          ChangeNotifierProvider<PatchService>.value(value: patchService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('SystemMetronomeTab renders visual metronome header and tap pad', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      patchService.systemSettings.metronomeOn = true; // should be disabled automatically
      await tester.pumpWidget(wrap(SystemMetronomeTab(patchService: patchService)));
      await tester.pump();

      // Audio click on hardware must be turned off
      expect(patchService.systemSettings.metronomeOn, isFalse);

      expect(find.text('METRÓNOMO VISUAL (EN PANTALLA)'), findsOneWidget);
      expect(find.text('PAD DE TAP TEMPO Y PULSO VISUAL'), findsOneWidget);
      expect(find.text('MÍNIMO 4 GOLPES'), findsOneWidget);
      expect(find.text('AJUSTE MANUAL TEMPO (BPM)'), findsOneWidget);
      expect(find.text('COMPÁS (BEAT)'), findsOneWidget);
    });

    testWidgets('Tap pad requires at least 4 taps before changing tempo', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var mockTime = DateTime(2026, 1, 1, 12, 0, 0);
      patchService.systemSettings.metronomeTempo = 120;
      await tester.pumpWidget(wrap(SystemMetronomeTab(
        patchService: patchService,
        clock: () => mockTime,
      )));
      await tester.pump();

      final padFinder = find.byType(MetronomeTapPad);
      expect(padFinder, findsOneWidget);

      // Tap 1
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('GOLPES: 1 / 4'), findsOneWidget);
      expect(patchService.systemSettings.metronomeTempo, 120);

      // Tap 2 (after 500ms)
      mockTime = mockTime.add(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('GOLPES: 2 / 4'), findsOneWidget);
      expect(patchService.systemSettings.metronomeTempo, 120);

      // Tap 3 (after 500ms)
      mockTime = mockTime.add(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('GOLPES: 3 / 4'), findsOneWidget);
      expect(patchService.systemSettings.metronomeTempo, 120);

      // Tap 4 (after 500ms) -> Interval is exactly 500ms -> 120 BPM
      mockTime = mockTime.add(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('✓ SINCRONIZADO'), findsOneWidget);
      expect(find.textContaining('¡TEMPO SINCRONIZADO:'), findsOneWidget);
      expect(patchService.systemSettings.metronomeTempo, 120);
    });

    testWidgets('Tapping 4 times with 600ms interval synchronizes tempo to 100 BPM', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var mockTime = DateTime(2026, 1, 1, 12, 0, 0);
      patchService.systemSettings.metronomeTempo = 140;
      await tester.pumpWidget(wrap(SystemMetronomeTab(
        patchService: patchService,
        clock: () => mockTime,
      )));
      await tester.pump();

      final padFinder = find.byType(MetronomeTapPad);

      // 4 taps with 600ms gap (60000 / 600 = 100 BPM)
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));

      mockTime = mockTime.add(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 550));
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));

      mockTime = mockTime.add(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 550));
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));

      mockTime = mockTime.add(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 550));
      await tester.tap(padFinder);
      await tester.pump(const Duration(milliseconds: 50));

      expect(patchService.systemSettings.metronomeTempo, 100);
      expect(patchService.masterBpm, 100);
    });

    testWidgets('Visual metronome switch pauses and resumes animation', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrap(SystemMetronomeTab(patchService: patchService)));
      await tester.pump();

      expect(find.text('PULSO VISUAL ACTIVO (SIN SONIDO EN SALIDA)'), findsOneWidget);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pump();

      expect(find.text('PULSO VISUAL PAUSADO'), findsOneWidget);
    });
  });
}
