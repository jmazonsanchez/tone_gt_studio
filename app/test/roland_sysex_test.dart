import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/protocol/roland_sysex.dart';

void main() {
  group('RolandSysEx Low-Level Engine Tests', () {
    test('Calculates 7-bit Roland checksum according to specification', () {
      // Sum = 129 -> (128 - 1) & 0x7F = 127 (0x7F)
      expect(RolandSysEx.calculateChecksum([0x7F, 0x00, 0x00, 0x01, 0x01]), equals(0x7F));

      // Sum = 128 -> (128 - 0) & 0x7F = 0 (0x00)
      expect(RolandSysEx.calculateChecksum([0x7F, 0x00, 0x00, 0x00, 0x01]), equals(0x00));

      // Tuner mode address 7F 00 00 02, data 01 -> Sum = 130 -> 126 (0x7E)
      expect(RolandSysEx.calculateChecksum([0x7F, 0x00, 0x00, 0x02, 0x01]), equals(0x7E));
    });

    test('buildDt1 produces verified GT-1B packet structure', () {
      final packet = RolandSysEx.buildDt1(
        address: [0x60, 0x00, 0x00, 0x30],
        data: [0x01],
      );

      expect(packet.first, equals(0xF0));
      expect(packet.last, equals(0xF7));
      expect(packet[1], equals(0x41)); // Roland
      expect(packet[2], equals(0x00)); // Device ID
      expect(packet.sublist(3, 7), equals([0x00, 0x00, 0x00, 0x3E])); // GT-1B model
      expect(packet[7], equals(0x12)); // DT1
      expect(packet.sublist(8, 12), equals([0x60, 0x00, 0x00, 0x30])); // Address
      expect(packet[12], equals(0x01)); // Data
      expect(packet[13], equals(0x6F)); // Checksum
    });

    test('buildRq1 produces valid 4-byte address and 4-byte size packet', () {
      final packet = RolandSysEx.buildRq1(
        address: [0x60, 0x00, 0x00, 0x00],
        size: 128,
      );

      expect(packet.first, equals(0xF0));
      expect(packet.last, equals(0xF7));
      expect(packet[7], equals(0x11)); // RQ1
      expect(packet.sublist(8, 12), equals([0x60, 0x00, 0x00, 0x00]));
      expect(packet.sublist(12, 16), equals([0x00, 0x00, 0x01, 0x00])); // 128 in 7-bit = 1 * 128 + 0
    });

    test('parseDt1 extracts 4-byte address and data bytes correctly', () {
      final raw = Uint8List.fromList([
        0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12,
        0x60, 0x00, 0x06, 0x33, // Foot volume
        0x50, // 80% level
        0x00, // dummy chk
        0xF7,
      ]);

      final parsed = RolandSysEx.parseDt1(raw);
      expect(parsed, isNotNull);
      expect(parsed!.address, equals([0x60, 0x00, 0x06, 0x33]));
      expect(parsed.data, equals([0x50]));
    });

    test('addressMatches strictly enforces exact 4-byte equality (Solves D1)', () {
      final addrA = [0x60, 0x00, 0x00, 0x20]; // COMP
      final addrB = [0x60, 0x00, 0x00, 0x30]; // OD/DS
      final addrSame = [0x60, 0x00, 0x00, 0x20];

      // Prefix-only comparison (the old bug D1) would consider addrA and addrB equal because 60 00 match
      expect(RolandSysEx.addressMatches(addrA, addrSame), isTrue);
      expect(RolandSysEx.addressMatches(addrA, addrB), isFalse);
    });
  });
}
