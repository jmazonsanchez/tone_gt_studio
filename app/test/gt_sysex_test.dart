import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/protocol/gt1b_addresses.dart';
import 'package:tone_gt_studio/models/effect_block.dart';

void main() {
  group('Roland / Boss GT-1B SysEx Protocol Tests', () {
    test('Roland Checksum calculation matches specification', () {
      final checksum1 = GtSysEx.calculateChecksum([0x7F, 0x00, 0x00, 0x02, 0x01]);
      expect(checksum1, equals(0x7E));

      final checksum2 = GtSysEx.calculateChecksum([0x00, 0x01, 0x00, 0x00, 0x00, 0x04]);
      expect(checksum2, equals(0x7B));
    });

    test('Tuner Toggle DT1 Message formatting (7F 00 00 02)', () {
      final msg = GtSysEx.buildTunerToggle(enable: true);

      expect(msg.first, equals(0xF0));
      expect(msg[1], equals(0x41));
      expect(msg[2], equals(0x00));
      expect(msg.sublist(3, 7), equals([0x00, 0x00, 0x00, 0x3E]));
      expect(msg[7], equals(0x12));
      expect(msg.sublist(8, 12), equals(Gt1bAddresses.runningMode));
      expect(msg[12], equals(0x01));
      expect(msg[13], equals(0x7E));
      expect(msg.last, equals(0xF7));
      expect(msg.length, equals(15));
    });

    test('Patch Change via SysEx DT1 generates verified hardware packet', () {
      final patchU01 = GtSysEx.buildPatchChange(0);
      expect(patchU01, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x7F, 0xF7
      ]));

      final patchU02 = GtSysEx.buildPatchChange(1);
      expect(patchU02, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x7E, 0xF7
      ]));

      final patchU05 = GtSysEx.buildPatchChange(4);
      expect(patchU05, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x04, 0x7B, 0xF7
      ]));
    });

    test('Patch Name RQ1 Request generates valid packet', () {
      // U01 request: Address 10 00 00 00, Size 00 00 00 10
      // Sum = 0x10 + 0x10 = 0x20 = 32 -> Checksum = 128 - 32 = 96 = 0x60
      final reqU01 = GtSysEx.buildPatchNameRequest(0);
      expect(reqU01, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x11,
        0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x60, 0xF7
      ]));

      // U02 request: Address 10 01 00 00, Size 00 00 00 10 -> Checksum 0x5F
      final reqU02 = GtSysEx.buildPatchNameRequest(1);
      expect(reqU02, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x11,
        0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x5F, 0xF7
      ]));
    });

    test('parsePatchName extracts clean ASCII string from hardware DT1 reply', () {
      // Live GT-1B reply for U01: "ADORACION!      "
      final sampleReply = Uint8List.fromList([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x10, 0x00, 0x00, 0x00,
        0x41, 0x44, 0x4F, 0x52, 0x41, 0x43, 0x49, 0x4F, 0x4E, 0x21, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
        0x7D, 0xF7
      ]);

      final name = GtSysEx.parsePatchName(sampleReply);
      expect(name, equals('ADORACION!'));
      expect(GtSysEx.parsePatchIndex(sampleReply), equals(0));
    });

    test('parseActiveEffectSwitches correctly identifies enabled blocks', () {
      // Mock buffer of 100 bytes starting at address 60 00 00 00
      final buffer = List<int>.filled(100, 0);
      buffer[0] = 0xF0;
      buffer[1] = 0x41;
      buffer[7] = 0x12; // DT1
      buffer[8] = 0x60;
      buffer[9] = 0x00;

      // Base payload at index 12
      buffer[12 + 0x20] = 0x01; // COMP ON
      buffer[12 + 0x30] = 0x00; // OD/DS OFF
      buffer[12 + 0x50] = 0x01; // PREAMP ON
      buffer[99] = 0xF7;

      final switches = GtSysEx.parseActiveEffectSwitches(Uint8List.fromList(buffer));
      expect(switches, isNotNull);
      expect(switches![EffectCategory.comp], isTrue);
      expect(switches[EffectCategory.odDs], isFalse);
      expect(switches[EffectCategory.preamp], isTrue);
    });

    test('Current Patch Number RQ1 request and parser', () {
      final req = GtSysEx.buildCurrentPatchNumberRequest();
      expect(req, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x11,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x7D, 0xF7
      ]));

      final reply = Uint8List.fromList([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x7E, 0xF7
      ]);
      final patchIdx = GtSysEx.parseCurrentPatchNumber(reply);
      expect(patchIdx, equals(1));
    });

    test('Effect Toggle generates valid DT1 message for OD/DS', () {
      final odDsOn = GtSysEx.buildEffectToggle(EffectCategory.odDs, true);
      expect(odDsOn, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x60, 0x00, 0x00, 0x30, 0x01, 0x6F, 0xF7
      ]));

      final odDsOff = GtSysEx.buildEffectToggle(EffectCategory.odDs, false);
      expect(odDsOff, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x60, 0x00, 0x00, 0x30, 0x00, 0x70, 0xF7
      ]));
    });

    test('FX Chain RQ1 request generates valid packet for address 60 00 07 20', () {
      final req = GtSysEx.buildFxChainRequest();
      expect(req.first, equals(0xF0));
      expect(req.last, equals(0xF7));
      expect(req[7], equals(GtSysEx.commandRq1));
      expect(req.sublist(8, 12), equals(Gt1bAddresses.fxChainBase));
      expect(req.sublist(12, 16), equals([0x00, 0x00, 0x00, 0x14])); // 20 bytes
      expect(req[16], equals(0x65)); // Checksum verified mathematically
    });

    test('parseFxChainOrder correctly parses hardware chain DT1 reply', () {
      // Mock DT1 reply for 60 00 07 20
      final chainBytes = [
        0x01, // COMP (Chain ID 1)
        0x00, // WAH / Pedal FX (Chain ID 0)
        0x04, // OD/DS (Chain ID 4)
        0x08, // PREAMP (Chain ID 8)
        0x0A, // EQ (Chain ID 10)
        0x0E, // FX1 (Chain ID 14)
        0x11, // FX2 (Chain ID 17)
        0x0F, // Foot Volume (Chain ID 15)
        0x05, // DELAY (Chain ID 5)
        0x02, // CHORUS (Chain ID 2)
        0x06, // REVERB (Chain ID 6)
        0x0B, // NS (Chain ID 11)
        // Remainder padding
        0x03, 0x07, 0x09, 0x0C, 0x0D, 0x10, 0x12, 0x13,
      ];
      final packet = <int>[
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x60, 0x00, 0x07, 0x20,
        ...chainBytes,
        0x00, // dummy checksum
        0xF7,
      ];

      final ordered = GtSysEx.parseFxChainOrder(Uint8List.fromList(packet));
      expect(ordered, isNotNull);
      expect(ordered!.length, equals(20));
      expect(ordered[0], equals(0x01));
      expect(GtSysEx.chainIdToCategory[ordered[0]], equals(EffectCategory.comp));
      expect(GtSysEx.chainIdToCategory[ordered[1]], equals(EffectCategory.pedalFx));
      expect(GtSysEx.chainIdToCategory[ordered[2]], equals(EffectCategory.odDs));
      expect(GtSysEx.chainIdToCategory[ordered[3]], equals(EffectCategory.preamp));
      expect(GtSysEx.chainIdToCategory[ordered[4]], equals(EffectCategory.eq));
      expect(GtSysEx.chainIdToCategory[ordered[5]], equals(EffectCategory.fx1));
      expect(GtSysEx.chainIdToCategory[ordered[6]], equals(EffectCategory.fx2));
      expect(GtSysEx.chainIdToCategory[ordered[7]], equals(EffectCategory.footVolume));
      expect(GtSysEx.chainIdToCategory[ordered[8]], equals(EffectCategory.delay));
      expect(GtSysEx.chainIdToCategory[ordered[9]], equals(EffectCategory.chorus));
      expect(GtSysEx.chainIdToCategory[ordered[10]], equals(EffectCategory.reverb));
      expect(GtSysEx.chainIdToCategory[ordered[11]], equals(EffectCategory.noiseSuppressor));
    });

    test('Effect Toggle generates valid DT1 message for Noise Suppressor', () {
      final nsOn = GtSysEx.buildEffectToggle(EffectCategory.noiseSuppressor, true);
      expect(nsOn.sublist(8, 12), equals([0x60, 0x00, 0x06, 0x63]));
      expect(nsOn[12], equals(0x01)); // ON

      final nsOff = GtSysEx.buildEffectToggle(EffectCategory.noiseSuppressor, false);
      expect(nsOff.sublist(8, 12), equals([0x60, 0x00, 0x06, 0x63]));
      expect(nsOff[12], equals(0x00)); // OFF
    });

    test('Editor Communication Mode DT1 generates valid packet for address 7F 00 00 01', () {
      final modeOn = GtSysEx.buildEditorMode(enable: true);
      expect(modeOn.sublist(8, 12), equals([0x7F, 0x00, 0x00, 0x01]));
      expect(modeOn[12], equals(0x01));
      expect(modeOn[13], equals(0x7F)); // Checksum
      expect(modeOn.last, equals(0xF7));

      final modeOff = GtSysEx.buildEditorMode(enable: false);
      expect(modeOff.sublist(8, 12), equals([0x7F, 0x00, 0x00, 0x01]));
      expect(modeOff[12], equals(0x00));
      expect(modeOff[13], equals(0x00)); // Checksum
      expect(modeOff.last, equals(0xF7));
    });
  });
}
