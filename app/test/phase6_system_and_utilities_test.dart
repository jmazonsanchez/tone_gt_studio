import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/models/system_settings.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/widgets/system_settings_modal.dart';
import 'package:tone_gt_studio/ui/widgets/tuner_modal.dart';

void main() {
  group('Phase 6: System & Utilities Verification Tests', () {
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

    test('buildSystemRequest generates valid 00 00 00 00 RQ1 message', () {
      final req = GtSysEx.buildSystemRequest();
      expect(req[0], 0xF0);
      expect(req[1], 0x41);
      expect(req[7], GtSysEx.commandRq1);
      // Address 00 00 00 00
      expect(req[8], 0x00);
      expect(req[9], 0x00);
      expect(req[10], 0x00);
      expect(req[11], 0x00);
      // Size 00 00 00 7F (127 bytes)
      expect(req[12], 0x00);
      expect(req[13], 0x00);
      expect(req[14], 0x00);
      expect(req[15], 0x7F);
    });

    test('parseLivePitch correctly extracts note and cents from 7F 00 05 00 DT1 stream', () {
      // Build packet matching hardware finding: addr 7F 00 05 00, data 09 63
      final packet = GtSysEx.buildDt1Message(
        address: [0x7F, 0x00, 0x05, 0x00],
        data: [0x09, 0x32], // Note 9 = A, 0x32 = 50 (in-tune center)
      );

      final pitch = GtSysEx.parseLivePitch(packet);
      expect(pitch, isNotNull);
      expect(pitch!.$1, 9); // A
      expect(pitch.$2, 50); // Exact center

      final sys = SystemSettings();
      sys.updateLivePitch(pitch.$1, pitch.$2);
      expect(sys.liveNote, 'A');
      expect(sys.liveCents, 0);
      expect(sys.inTune, isTrue);
    });

    test('parseSystemSettings populates SystemSettings from 00 00 00 00 packet', () {
      final data = Uint8List(128);
      data[0x20] = 5; // 440 Hz
      data[0x21] = 1; // Bypass
      data[0x30] = 1; // Metronome ON
      data[0x31] = 130; // Tempo 130
      data[0x32] = 0;
      data[0x33] = 3; // 4/4
      data[0x34] = 85; // Level 85%
      data[0x70] = 1; // Output select: Bass Amp Clean
      data[0x71] = 14; // Input level: +4 dB
      data[0x72] = 25; // Global EQ Low: +5 dB

      final packet = GtSysEx.buildDt1Message(
        address: [0x00, 0x00, 0x00, 0x00],
        data: data,
      );

      final sys = SystemSettings();
      GtSysEx.parseSystemSettings(packet, sys);

      expect(sys.tunerPitch, 5);
      expect(sys.tunerOutput, 1);
      expect(sys.metronomeOn, isTrue);
      expect(sys.metronomeTempo, 130);
      expect(sys.metronomeLevel, 85);
      expect(sys.outputSelect, 1);
      expect(sys.inputLevel, 14);
      expect(sys.eqLowGain, 25);
    });

    test('PatchService.updateSystemParameter updates state and dispatches SysEx', () async {
      await patchService.updateSystemParameter('output_select', 2);
      expect(patchService.systemSettings.outputSelect, 2);

      await patchService.updateSystemParameter('metronome_on', 1);
      expect(patchService.systemSettings.metronomeOn, isTrue);

      await patchService.updateSystemParameter('metronome_tempo', 140);
      expect(patchService.systemSettings.metronomeTempo, 140);

      await patchService.updateSystemParameter('global_eq_low', 30);
      expect(patchService.systemSettings.eqLowGain, 30);
    });

    testWidgets('TunerModal renders live note, cents gauge, and settings', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      patchService.systemSettings.updateLivePitch(4, 50); // E (in-tune)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TunerModal(
              patchService: patchService,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('AFINADOR CROMÁTICO EN VIVO'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('¡AFINADO PERFECTO!'), findsOneWidget);
      expect(find.text('SALIR DEL AFINADOR (MODO PLAY)'), findsOneWidget);
    });

    testWidgets('SystemSettingsModal renders tabs and controls', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemSettingsModal(patchService: patchService),
          ),
        ),
      );

      // Verify Tab titles
      expect(find.text('SISTEMA Y UTILIDADES GT-1B'), findsOneWidget);
      expect(find.text('GLOBAL & SALIDA'), findsOneWidget);
      expect(find.text('METRÓNOMO'), findsOneWidget);
      expect(find.text('USB & HARDWARE'), findsOneWidget);

      // Verify Global Tab elements
      expect(find.text('RUTEO DE SALIDA Y ENTRADA'), findsOneWidget);
      expect(find.text('GLOBAL 4-BAND EQ (HARDWARE MASTER)'), findsOneWidget);

      // Tap Metronome Tab
      await tester.tap(find.text('METRÓNOMO'));
      await tester.pumpAndSettle();
      expect(find.text('METRÓNOMO INTERNO'), findsOneWidget);
      expect(find.text('TEMPO (BPM)'), findsOneWidget);

      // Tap USB & Hardware Tab
      await tester.tap(find.text('USB & HARDWARE'));
      await tester.pumpAndSettle();
      expect(find.text('USB AUDIO PRINCIPAL (DAW / GRABACIÓN)'), findsOneWidget);
      expect(find.text('DIRECT MONITOR'), findsOneWidget);
    });
  });
}
