import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/protocol/gt1b_addresses.dart';
import 'package:tone_gt_studio/models/effect_block.dart';

void main() {
  group('Roland / Boss GT-1B SysEx Protocol Tests', () {
    test('Roland Checksum calculation matches specification', () {
      // Test case 1: Address [7F, 00, 05, 00] + Data [01] (Tuner ON)
      // Sum = 127 + 0 + 5 + 0 + 1 = 133
      // Remainder = 133 % 128 = 5
      // Checksum = (128 - 5) % 128 = 123 (0x7B)
      final checksum1 = GtSysEx.calculateChecksum([0x7F, 0x00, 0x05, 0x00, 0x01]);
      expect(checksum1, equals(0x7B));

      // Test case 2: Tuner OFF [7F, 00, 05, 00, 00]
      // Sum = 132 -> Remainder = 4 -> Checksum = 124 (0x7C)
      final checksum2 = GtSysEx.calculateChecksum([0x7F, 0x00, 0x05, 0x00, 0x00]);
      expect(checksum2, equals(0x7C));
    });

    test('Tuner Toggle DT1 Message formatting', () {
      final msg = GtSysEx.buildTunerToggle(enable: true);

      expect(msg.first, equals(0xF0)); // SOX
      expect(msg[1], equals(0x41));   // Roland
      expect(msg[2], equals(0x00));   // Device ID (0x00)
      expect(msg.sublist(3, 7), equals([0x00, 0x00, 0x00, 0x3E])); // Model GT-1B
      expect(msg[7], equals(0x12));   // Command DT1
      expect(msg.sublist(8, 12), equals(Gt1bAddresses.tunerSingleModePitch)); // Address
      expect(msg[12], equals(0x01));  // Data
      expect(msg[13], equals(0x7B));  // Checksum
      expect(msg.last, equals(0xF7));  // EOX
      expect(msg.length, equals(15));
    });

    test('Program Change message ranges from 0 to 98 (U01 - U99)', () {
      final patch1 = GtSysEx.buildProgramChange(0); // U01
      expect(patch1, equals([0xC0, 0x00]));

      final patch99 = GtSysEx.buildProgramChange(98); // U99
      expect(patch99, equals([0xC0, 0x62]));
    });

    test('Effect Toggle generates valid DT1 message', () {
      final odDsOn = GtSysEx.buildEffectToggle(EffectCategory.odDs, true);
      expect(odDsOn.first, equals(0xF0));
      expect(odDsOn[7], equals(0x12));
      expect(odDsOn[12], equals(0x01));
      expect(odDsOn.last, equals(0xF7));
    });
  });
}
