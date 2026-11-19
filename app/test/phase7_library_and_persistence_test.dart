import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/domain/tsl_serializer.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/widgets/patch_list_modal.dart';
import 'package:tone_gt_studio/ui/widgets/patch_write_modal.dart';

void main() {
  group('Phase 7: Library & Persistence Verification Tests', () {
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

    test('buildPatchWrite generates valid 7F 00 01 04 DT1 for User slot and blocks Presets', () {
      final msgU01 = GtSysEx.buildPatchWrite(0); // U01
      expect(msgU01[0], 0xF0);
      expect(msgU01[7], GtSysEx.commandDt1);
      expect(msgU01[8], 0x7F);
      expect(msgU01[9], 0x00);
      expect(msgU01[10], 0x01);
      expect(msgU01[11], 0x04);
      expect(msgU01[12], 0x00); // High
      expect(msgU01[13], 0x00); // Low

      final msgU99 = GtSysEx.buildPatchWrite(98); // U99
      expect(msgU99[12], 0x00);
      expect(msgU99[13], 98);

      // Throws on preset slot index >= 99 (Read-only protection)
      expect(() => GtSysEx.buildPatchWrite(99), throwsAssertionError);
    });

    test('buildPatchCopy generates valid 7F 00 01 00 packet', () {
      final msg = GtSysEx.buildPatchCopy(120, 5); // From P22 (index 120) to U06 (index 5)
      expect(msg[8], 0x7F);
      expect(msg[9], 0x00);
      expect(msg[10], 0x01);
      expect(msg[11], 0x00);
      expect(msg[12], 0);
      expect(msg[13], 120);
      expect(msg[14], 0);
      expect(msg[15], 5);
    });

    test('buildPatchNameEdit pads name with exactly 16 ASCII bytes', () {
      final msg = GtSysEx.buildPatchNameEdit('FUNK BASS');
      expect(msg[8], 0x60);
      expect(msg[9], 0x00);
      expect(msg[10], 0x00);
      expect(msg[11], 0x00);
      // Data length must be exactly 16 bytes
      final data = msg.sublist(12, 28);
      expect(data.length, 16);
      expect(String.fromCharCodes(data).trim(), 'FUNK BASS');
    });

    test('TslSerializer exports and imports Boss Tone Studio (.tsl) LiveSet format', () {
      final samplePatches = patchService.patches.sublist(0, 5);
      final jsonOutput = TslSerializer.exportLiveSet(
        liveSetName: 'Studio Collection',
        patches: samplePatches,
      );

      expect(jsonOutput, contains('"device": "GT-1B"'));
      expect(jsonOutput, contains('"name": "Studio Collection"'));
      expect(jsonOutput, contains('"patchList"'));

      final imported = TslSerializer.importLiveSet(
        jsonOutput,
        templatePatches: patchService.patches.sublist(0, 5),
      );

      expect(imported.length, 5);
      expect(imported[0].name, samplePatches[0].name);
      expect(imported[0].effects.length, samplePatches[0].effects.length);
    });

    test('TslSerializer exports and imports single portable JSON patch', () {
      final current = patchService.currentPatch;
      final jsonOutput = TslSerializer.exportSinglePatch(current);

      expect(jsonOutput, contains('"device": "GT-1B"'));
      expect(jsonOutput, contains(current.name));

      final imported = TslSerializer.importSinglePatch(jsonOutput, current);
      expect(imported.name, current.name);
      expect(imported.effects.length, current.effects.length);
    });

    test('PatchService.writeCurrentPatchToHardware writes to U slots and blocks Presets', () async {
      // Writing to U05 (index 4) succeeds
      final success = await patchService.writeCurrentPatchToHardware(4, newName: 'SLAP KING');
      expect(success, isTrue);
      expect(patchService.patches[4].name, 'SLAP KING');

      // Writing to P01 (index 99) fails
      final failPreset = await patchService.writeCurrentPatchToHardware(99, newName: 'CANNOT WRITE');
      expect(failPreset, isFalse);
    });

    test('PatchService.copyPatch copies from factory preset to user slot', () async {
      // Copy factory preset P01 (index 99) into U02 (index 1)
      final success = await patchService.copyPatch(99, 1);
      expect(success, isTrue);
      expect(patchService.patches[1].name, patchService.patches[99].name);
    });

    testWidgets('PatchListModal renders with User, Factory and Backup tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: patchService),
            ChangeNotifierProvider.value(value: midiService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PatchListModal(),
            ),
          ),
        ),
      );

      expect(find.text('BIBLIOTECA DE PRESETS GT-1B (198 BANCOS)'), findsOneWidget);
      expect(find.text('USER (U01-U99)'), findsOneWidget);
      expect(find.text('FÁBRICA (P01-P99)'), findsOneWidget);
      expect(find.text('BACKUP & TSL'), findsOneWidget);
      expect(find.text('U01'), findsWidgets);

      // Tap Factory tab
      await tester.tap(find.text('FÁBRICA (P01-P99)'));
      await tester.pumpAndSettle();
      expect(find.text('P01'), findsWidgets);

      // Tap Backup tab
      await tester.tap(find.text('BACKUP & TSL'));
      await tester.pumpAndSettle();
      expect(find.text('EXPORTAR LIVESET BOSS TONE STUDIO (.TSL)'), findsOneWidget);
    });

    testWidgets('PatchWriteModal allows slot selection and renaming', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatchWriteModal(
              patchService: patchService,
              initialTargetIndex: 0,
            ),
          ),
        ),
      );

      expect(find.text('GUARDAR PRESET EN GT-1B'), findsOneWidget);
      expect(find.text('DESTINO EN MEMORIA DE USUARIO (U01-U99)'), findsOneWidget);
      expect(find.text('GUARDAR EN HARDWARE'), findsOneWidget);
    });
  });
}
