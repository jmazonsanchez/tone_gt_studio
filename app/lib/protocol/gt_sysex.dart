import 'dart:typed_data';
import 'gt1b_addresses.dart';
import '../models/effect_block.dart';

/// Roland / Boss SysEx Protocol Engine for Boss GT-1B and GT-1.
class GtSysEx {
  static const int rolandManufacturerId = 0x41;
  static const int defaultDeviceId = 0x10;

  // Model IDs
  static const List<int> modelIdGt1b = [0x00, 0x00, 0x00, 0x3E]; // GT-1B (Bass)
  static const List<int> modelIdGt1 = [0x00, 0x00, 0x00, 0x3B];  // GT-1 (Guitar)

  // Commands
  static const int commandRq1 = 0x11; // Data Request 1
  static const int commandDt1 = 0x12; // Data Set 1

  /// Calculate Roland 7-bit checksum.
  /// Formula: Checksum = (128 - (sum % 128)) & 0x7F
  static int calculateChecksum(List<int> bytes) {
    int sum = 0;
    for (int b in bytes) {
      sum += b;
    }
    int remainder = sum % 128;
    return (128 - remainder) % 128;
  }

  /// Construct a Data Set 1 (DT1) SysEx message.
  static Uint8List buildDt1Message({
    required List<int> address,
    required List<int> data,
    List<int> modelId = modelIdGt1b,
    int deviceId = defaultDeviceId,
  }) {
    assert(address.length == 4, 'Address must be exactly 4 bytes');
    final payloadForChecksum = [...address, ...data];
    final checksum = calculateChecksum(payloadForChecksum);

    return Uint8List.fromList([
      0xF0, // Start of Exclusive
      rolandManufacturerId,
      deviceId,
      ...modelId,
      commandDt1,
      ...address,
      ...data,
      checksum,
      0xF7, // End of Exclusive
    ]);
  }

  /// Construct a Data Request 1 (RQ1) SysEx message.
  static Uint8List buildRq1Message({
    required List<int> address,
    required List<int> size,
    List<int> modelId = modelIdGt1b,
    int deviceId = defaultDeviceId,
  }) {
    assert(address.length == 4, 'Address must be exactly 4 bytes');
    assert(size.length == 4, 'Size must be exactly 4 bytes');
    final payloadForChecksum = [...address, ...size];
    final checksum = calculateChecksum(payloadForChecksum);

    return Uint8List.fromList([
      0xF0,
      rolandManufacturerId,
      deviceId,
      ...modelId,
      commandRq1,
      ...address,
      ...size,
      checksum,
      0xF7,
    ]);
  }

  /// Build Standard MIDI Program Change (PC) for User Patches (U01 - U99).
  /// [patchIndex] ranges from 0 (U01) to 98 (U99).
  static Uint8List buildProgramChange(int patchIndex, {int channel = 0}) {
    assert(patchIndex >= 0 && patchIndex <= 98, 'Patch index must be 0..98');
    final status = 0xC0 | (channel & 0x0F);
    return Uint8List.fromList([status, patchIndex]);
  }

  /// Toggle Tuner mode ON or OFF.
  static Uint8List buildTunerToggle({bool enable = true, List<int> modelId = modelIdGt1b}) {
    return buildDt1Message(
      address: Gt1bAddresses.tunerSingleModePitch,
      data: [enable ? 0x01 : 0x00],
      modelId: modelId,
    );
  }

  /// Toggle an effect category ON or OFF.
  static Uint8List buildEffectToggle(EffectCategory category, bool isEnabled, {List<int> modelId = modelIdGt1b}) {
    List<int> address;
    switch (category) {
      case EffectCategory.comp:
        address = Gt1bAddresses.compSwitch;
        break;
      case EffectCategory.odDs:
        address = Gt1bAddresses.odDsSwitch;
        break;
      case EffectCategory.preamp:
        address = Gt1bAddresses.preampSwitch;
        break;
      case EffectCategory.fx1:
        address = Gt1bAddresses.fx1Switch;
        break;
      case EffectCategory.fx2:
        address = Gt1bAddresses.fx2Switch;
        break;
      case EffectCategory.delay:
        address = Gt1bAddresses.delaySwitch;
        break;
      case EffectCategory.chorus:
        address = Gt1bAddresses.chorusSwitch;
        break;
      case EffectCategory.reverb:
        address = Gt1bAddresses.reverbSwitch;
        break;
    }

    return buildDt1Message(
      address: address,
      data: [isEnabled ? 0x01 : 0x00],
      modelId: modelId,
    );
  }
}
