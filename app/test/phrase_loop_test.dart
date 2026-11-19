import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/models/phrase_loop.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/protocol/roland_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/theme/app_theme.dart';
import 'package:tone_gt_studio/ui/widgets/phrase_loop_modal.dart';

void main() {
  group('PhraseLoop Protocol & Models Tests', () {
    test('PhraseLoopSettings defaults and labels', () {
      final settings = PhraseLoopSettings();
      expect(settings.playLevel, equals(100));
      expect(settings.recMode, equals(LooperRecMode.recPlay));
      expect(settings.startTimerSeconds, equals(3));
      expect(settings.maxDurationSeconds, equals(0));
      expect(settings.recModeLabel, equals('REC → PLAY'));

      settings.playLevel = 80;
      settings.recMode = LooperRecMode.recDub;
      settings.startTimerSeconds = 5;
      settings.maxDurationSeconds = 16;

      expect(settings.playLevel, equals(80));
      expect(settings.recMode, equals(LooperRecMode.recDub));
      expect(settings.startTimerSeconds, equals(5));
      expect(settings.maxDurationSeconds, equals(16));
      expect(settings.recModeLabel, equals('REC → DUB'));
    });

    test('buildPhraseLoopToggle generates valid SysEx DT1 packet', () {
      final onPacket = GtSysEx.buildPhraseLoopToggle(enable: true);
      final offPacket = GtSysEx.buildPhraseLoopToggle(enable: false);

      expect(onPacket.first, equals(0xF0));
      expect(onPacket.last, equals(0xF7));
      // Address 00 00 01 00, data 01
      final onParsed = RolandSysEx.parseDt1(onPacket);
      expect(onParsed, isNotNull);
      expect(onParsed!.address, equals([0x00, 0x00, 0x01, 0x00]));
      expect(onParsed.data, equals([0x01]));

      final offParsed = RolandSysEx.parseDt1(offPacket);
      expect(offParsed, isNotNull);
      expect(offParsed!.address, equals([0x00, 0x00, 0x01, 0x00]));
      expect(offParsed.data, equals([0x00]));
    });

    test('buildPhraseLoopLevel generates valid SysEx DT1 packet', () {
      final levelPacket = GtSysEx.buildPhraseLoopLevel(95);
      final parsed = RolandSysEx.parseDt1(levelPacket);
      expect(parsed, isNotNull);
      expect(parsed!.address, equals([0x00, 0x00, 0x01, 0x04]));
      expect(parsed.data, equals([95]));
    });

    test('buildPhraseLoopRecMode generates valid SysEx DT1 packet', () {
      final playPacket = GtSysEx.buildPhraseLoopRecMode(1);
      final dubPacket = GtSysEx.buildPhraseLoopRecMode(0);

      final playParsed = RolandSysEx.parseDt1(playPacket);
      expect(playParsed, isNotNull);
      expect(playParsed!.address, equals([0x00, 0x00, 0x01, 0x02]));
      expect(playParsed.data, equals([0x01]));

      final dubParsed = RolandSysEx.parseDt1(dubPacket);
      expect(dubParsed, isNotNull);
      expect(dubParsed!.address, equals([0x00, 0x00, 0x01, 0x02]));
      expect(dubParsed.data, equals([0x00]));
    });
  });

  group('PatchService PhraseLoop Engine Tests', () {
    late MidiService midi;
    late PatchService patchService;

    setUp(() {
      midi = MidiService();
      patchService = PatchService(midi);
    });

    tearDown(() {
      patchService.dispose();
      midi.dispose();
    });

    test('Immediate startLooperWithTimer (0 seconds) begins recording', () async {
      expect(patchService.looperStatus, equals(LooperStatus.stopped));

      patchService.updateLooperStartTimer(0);
      expect(patchService.phraseLoopSettings.startTimerSeconds, equals(0));

      await patchService.startLooperWithTimer();
      expect(patchService.looperStatus, equals(LooperStatus.recording));

      // Switch to playback
      patchService.switchToPlayback();
      expect(patchService.looperStatus, equals(LooperStatus.playing));

      // Switch to overdub
      patchService.switchToOverdub();
      expect(patchService.looperStatus, equals(LooperStatus.overdubbing));

      // Stop
      patchService.stopLooper();
      expect(patchService.looperStatus, equals(LooperStatus.stopped));

      // Clear
      patchService.clearLooper();
      expect(patchService.looperStatus, equals(LooperStatus.stopped));
      expect(patchService.looperElapsedSeconds, equals(0.0));
    });

    test('Looper countdown begins when timer > 0', () async {
      patchService.updateLooperStartTimer(3);
      await patchService.startLooperWithTimer();

      expect(patchService.looperStatus, equals(LooperStatus.countdown));
      expect(patchService.looperCountdownRemaining, equals(3));

      // Stop cancels countdown
      patchService.stopLooper();
      expect(patchService.looperStatus, equals(LooperStatus.stopped));
      expect(patchService.looperCountdownRemaining, equals(0));
    });

    test('Settings updates modify state and notify listeners', () {
      var notified = false;
      patchService.addListener(() => notified = true);

      patchService.updateLooperLevel(85);
      expect(patchService.phraseLoopSettings.playLevel, equals(85));
      expect(notified, isTrue);

      notified = false;
      patchService.updateLooperRecMode(LooperRecMode.recDub);
      expect(patchService.phraseLoopSettings.recMode, equals(LooperRecMode.recDub));
      expect(notified, isTrue);

      notified = false;
      patchService.updateLooperDurationTimer(8);
      expect(patchService.phraseLoopSettings.maxDurationSeconds, equals(8));
      expect(notified, isTrue);
    });
  });

  group('PhraseLoopModal Widget Tests', () {
    late MidiService midi;
    late PatchService patchService;

    setUp(() {
      midi = MidiService();
      patchService = PatchService(midi);
    });

    tearDown(() {
      patchService.dispose();
      midi.dispose();
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: patchService,
            builder: (context, _) => PhraseLoopModal(
              patchService: patchService,
              onClose: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('Renders PhraseLoopModal header, timers, rec mode, and transport buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('PHRASE LOOP (LOOPER 32s GT-1B)'), findsOneWidget);
      expect(find.text('LOOPER LISTO (VACÍO)'), findsOneWidget);
      expect(find.text('TEMPORIZADOR DE ENCENDIDO (PRE-ROLL)'), findsOneWidget);
      expect(find.text('DURACIÓN DE GRABACIÓN AUTOMÁTICA'), findsOneWidget);

      // Verify timer chips exist
      expect(find.text('0s (Directo)'), findsOneWidget);
      expect(find.text('3s'), findsOneWidget);
      expect(find.text('Libre (32s)'), findsOneWidget);
      expect(find.text('8s'), findsOneWidget);

      // Verify transport buttons
      expect(find.text('ENCENDER Y GRABAR (3s Timer)'), findsOneWidget);
      expect(find.text('DETENER (STOP)'), findsOneWidget);
      expect(find.text('BORRAR LOOP'), findsOneWidget);
      expect(find.text('PLAY LEVEL: '), findsOneWidget);
      expect(find.text('REC → PLAY'), findsOneWidget);
    });

    testWidgets('Tapping Immediate chip and ENCENDER Y GRABAR starts recording directly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 0s (Directo) chip
      await tester.tap(find.text('0s (Directo)'));
      await tester.pumpAndSettle();
      expect(patchService.phraseLoopSettings.startTimerSeconds, equals(0));
      expect(find.text('ENCENDER Y GRABAR'), findsOneWidget);

      // Tap ENCENDER Y GRABAR
      await tester.tap(find.text('ENCENDER Y GRABAR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(patchService.looperStatus, equals(LooperStatus.recording));
      expect(find.text('GRABANDO EN VIVO (REC)'), findsOneWidget);
      expect(find.text('CERRAR Y REPRODUCIR (PLAY)'), findsOneWidget);

      // Tap CERRAR Y REPRODUCIR (PLAY)
      await tester.tap(find.text('CERRAR Y REPRODUCIR (PLAY)'));
      await tester.pump();
      expect(patchService.looperStatus, equals(LooperStatus.playing));
      expect(find.text('REPRODUCIENDO LOOP (PLAY)'), findsOneWidget);

      // Tap DETENER (STOP)
      await tester.tap(find.text('DETENER (STOP)'));
      await tester.pump();
      expect(patchService.looperStatus, equals(LooperStatus.stopped));
    });
  });
}
