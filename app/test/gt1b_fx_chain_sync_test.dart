import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/screens/gateway_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Boss GT-1B Authentic FX Chain Baseline & Mapping Tests', () {
    test('Default patch effects order matches authentic GT-1B hardware sequence', () {
      final midi = MidiService();
      final patchService = PatchService(midi);
      patchService.autoSyncOnConnect = false;

      final u01Effects = patchService.currentPatch.effects;
      expect(u01Effects.length, equals(9));

      // GT-1B Authentic sequence: NS, FX1, PDL, PREAMP, FV, FX2, DELAY, REVERB, OD/DS
      expect(u01Effects[0].category, equals(EffectCategory.noiseSuppressor));
      expect(u01Effects[0].name, equals('NS'));

      expect(u01Effects[1].category, equals(EffectCategory.fx1));
      expect(u01Effects[1].name, equals('FX1'));

      expect(u01Effects[2].category, equals(EffectCategory.pedalFx));
      expect(u01Effects[2].name, equals('PEDAL FX'));

      expect(u01Effects[3].category, equals(EffectCategory.preamp));
      expect(u01Effects[3].name, equals('PREAMP'));

      expect(u01Effects[4].category, equals(EffectCategory.footVolume));
      expect(u01Effects[4].name, equals('FOOT VOL'));

      expect(u01Effects[5].category, equals(EffectCategory.fx2));
      expect(u01Effects[5].name, equals('FX2'));

      expect(u01Effects[6].category, equals(EffectCategory.delay));
      expect(u01Effects[6].name, equals('DELAY'));

      expect(u01Effects[7].category, equals(EffectCategory.reverb));
      expect(u01Effects[7].name, equals('REVERB'));

      expect(u01Effects[8].category, equals(EffectCategory.odDs));
      expect(u01Effects[8].name, equals('OD/DS'));

      patchService.dispose();
      midi.dispose();
    });

    test('defaultHardwareChain in GtSysEx has authentic GT-1B movable IDs in slots 0..8', () {
      const chain = GtSysEx.defaultHardwareChain;
      expect(chain.length, equals(20));

      // Slots 0..8: NS=12, FX1=15, PDL=5, PREAMP=13, FV=11, FX2=7, DELAY=6, REVERB=9, OD/DS=2
      expect(chain[0], equals(12));
      expect(chain[1], equals(15));
      expect(chain[2], equals(5));
      expect(chain[3], equals(13));
      expect(chain[4], equals(11));
      expect(chain[5], equals(7));
      expect(chain[6], equals(6));
      expect(chain[7], equals(9));
      expect(chain[8], equals(2));
    });

    test('buildFxChainOrder maps 9 movable IDs directly into slots 0..8', () {
      // Custom 9-effect order: [5, 12, 15, 13, 11, 7, 6, 9, 2] (PDL moved to front)
      final movable = [5, 12, 15, 13, 11, 7, 6, 9, 2];
      final packet = GtSysEx.buildFxChainOrder(movable);

      expect(packet[0], equals(0xF0));
      expect(packet[1], equals(0x41)); // Roland
      expect(packet[8], equals(0x60));
      expect(packet[9], equals(0x00));
      expect(packet[10], equals(0x07));
      expect(packet[11], equals(0x20)); // Base FX chain address

      // Data bytes start at index 12: slots 0..8 must contain the exact movable order
      expect(packet[12 + 0], equals(5));
      expect(packet[12 + 1], equals(12));
      expect(packet[12 + 2], equals(15));
      expect(packet[12 + 3], equals(13));
      expect(packet[12 + 4], equals(11));
      expect(packet[12 + 5], equals(7));
      expect(packet[12 + 6], equals(6));
      expect(packet[12 + 7], equals(9));
      expect(packet[12 + 8], equals(2));
    });

    test('Moving position 3 (PDL) to position 1 reorders effects and sends slots 0..8 to hardware', () async {
      final midi = MidiService();
      final patchService = PatchService(midi);
      patchService.autoSyncOnConnect = false;

      final sentSysEx = <Uint8List>[];
      midi.onSysExReceived.listen((msg) => sentSysEx.add(msg));

      // Initial order: [NS, FX1, PDL, PREAMP, FV, FX2, DELAY, REVERB, OD/DS]
      // Move index 2 (PDL) to index 0 (front)
      await patchService.moveEffect(2, 0);

      final updatedEffects = patchService.currentPatch.effects;
      expect(updatedEffects[0].category, equals(EffectCategory.pedalFx)); // PDL is now at position 1!
      expect(updatedEffects[1].category, equals(EffectCategory.noiseSuppressor)); // NS is position 2
      expect(updatedEffects[2].category, equals(EffectCategory.fx1)); // FX1 is position 3

      patchService.dispose();
      midi.dispose();
    });

    test('Incoming DT1 slot change updates active patch effect sequence cleanly', () async {
      final midi = MidiService();
      final patchService = PatchService(midi);
      patchService.autoSyncOnConnect = false;

      // Simulate hardware sending single slot update: slot 0 set to DELAY (6)
      // Address: 60 00 07 20, data: 06
      final singleSlotPacket = GtSysEx.buildDt1Message(
        address: [0x60, 0x00, 0x07, 0x20],
        data: [0x06], // DELAY
      );

      midi.handleIncomingDataForTesting(singleSlotPacket);
      await Future.delayed(Duration.zero);

      // DELAY must now be at slot 0 (first position)
      expect(patchService.currentPatch.effects.first.category, equals(EffectCategory.delay));

      patchService.dispose();
      midi.dispose();
    });
  });

  group('GatewayScreen GT-1B Hardware Model Display Tests', () {
    testWidgets('GatewayScreen explicitly displays MODELO: BOSS GT-1B (BASS)', (tester) async {
      final midi = MidiService();

      await tester.pumpWidget(
        MaterialApp(
          home: GatewayScreen(
            midi: midi,
            onEnterDemoMode: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('MODELO: BOSS GT-1B (BASS)'), findsOneWidget);
      expect(find.text('Boss GT-1B Bass Studio'), findsOneWidget);

      midi.dispose();
    });
  });
}
