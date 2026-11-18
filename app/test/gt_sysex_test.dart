import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/protocol/gt1b_addresses.dart';
import 'package:tone_gt_studio/models/effect_block.dart';

void main() {
  group('Roland / Boss GT-1B SysEx Protocol Tests', () {
    test('Roland Checksum calculation matches specification', () {
      // Test case 1: Address [7F, 00, 00, 02] + Data [01] (Tuner ON)
      // Sum = 127 + 0 + 0 + 2 + 1 = 130
      // Remainder = 130 % 128 = 2
      // Checksum = (128 - 2) % 128 = 126 (0x7E)
      final checksum1 = GtSysEx.calculateChecksum([0x7F, 0x00, 0x00, 0x02, 0x01]);
      expect(checksum1, equals(0x7E));

      // Test case 2: Patch U05 [00, 01, 00, 00, 00, 04]
      // Sum = 0 + 1 + 0 + 0 + 0 + 4 = 5
      // Remainder = 5 -> Checksum = 123 (0x7B)
      final checksum2 = GtSysEx.calculateChecksum([0x00, 0x01, 0x00, 0x00, 0x00, 0x04]);
      expect(checksum2, equals(0x7B));
    });

    test('Tuner Toggle DT1 Message formatting (7F 00 00 02)', () {
      final msg = GtSysEx.buildTunerToggle(enable: true);

      expect(msg.first, equals(0xF0)); // SOX
      expect(msg[1], equals(0x41));   // Roland
      expect(msg[2], equals(0x00));   // Device ID (0x00)
      expect(msg.sublist(3, 7), equals([0x00, 0x00, 0x00, 0x3E])); // Model GT-1B
      expect(msg[7], equals(0x12));   // Command DT1
      expect(msg.sublist(8, 12), equals(Gt1bAddresses.runningMode)); // Address 7F 00 00 02
      expect(msg[12], equals(0x01));  // Data (01 = Tuner)
      expect(msg[13], equals(0x7E));  // Checksum
      expect(msg.last, equals(0xF7));  // EOX
      expect(msg.length, equals(15));
    });

    test('Patch Change via SysEx DT1 generates verified hardware packet', () {
      // U01 -> Patch index 0
      final patchU01 = GtSysEx.buildPatchChange(0);
      expect(patchU01, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x7F, 0xF7
      ]));

      // U02 -> Patch index 1
      final patchU02 = GtSysEx.buildPatchChange(1);
      expect(patchU02, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x7E, 0xF7
      ]));

      // U05 -> Patch index 4
      final patchU05 = GtSysEx.buildPatchChange(4);
      expect(patchU05, equals([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x04, 0x7B, 0xF7
      ]));
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
  });
}
