import 'dart:typed_data';
import 'gt1b_addresses.dart';
import '../models/effect_block.dart';

/// Roland / Boss SysEx Protocol Engine for Boss GT-1B and GT-1.
class GtSysEx {
  static const int rolandManufacturerId = 0x41;
  static const int defaultDeviceId = 0x00; // GT-1B factory default Device ID is 0x00

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

  /// Request patch name for user patch [patchIndex] (0..98 -> U01..U99).
  /// Address: [0x10, patchIndex, 0x00, 0x00], Size: [0x00, 0x00, 0x00, 0x10] (16 bytes)
  static Uint8List buildPatchNameRequest(int patchIndex, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(patchIndex >= 0 && patchIndex <= 98, 'Patch index must be 0..98');
    return buildRq1Message(
      address: [0x10, patchIndex, 0x00, 0x00],
      size: [0x00, 0x00, 0x00, 0x10],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request active patch buffer data (address 60 00 00 00, size 127 bytes).
  static Uint8List buildActivePatchDataRequest({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x60, 0x00, 0x00, 0x00],
      size: [0x00, 0x00, 0x00, 0x7F],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request currently selected patch number from setup buffer (address 00 01 00 00, size 2 bytes).
  static Uint8List buildCurrentPatchNumberRequest({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: Gt1bAddresses.currentPatchNo,
      size: [0x00, 0x00, 0x00, 0x02],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Parse currently selected patch index (0..98) from 00 01 00 00 DT1 response.
  static int? parseCurrentPatchNumber(Uint8List packet) {
    if (packet.length < 15) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1) return null;
    if (packet[8] != 0x00 || packet[9] != 0x01 || packet[10] != 0x00 || packet[11] != 0x00) {
      return null;
    }
    final high = packet[12];
    final low = packet[13];
    return (high << 7) | low;
  }

  /// Parse patch name from an incoming Roland DT1 packet.
  static String? parsePatchName(Uint8List packet) {
    if (packet.length < 28) return null;
    if (packet[0] != 0xF0 || packet[1] != rolandManufacturerId || packet[7] != commandDt1) {
      return null;
    }
    // Check if address starts with 0x10 (user patch list) or 0x60 (temporary patch)
    if (packet[8] != 0x10 && packet[8] != 0x60) return null;
    final nameBytes = packet.sublist(12, 28);
    final chars = nameBytes.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : ' ').join();
    return chars.trim();
  }

  /// Get the patch index (0..98) if packet is from user patch list (address 10 [idx] 00 00)
  static int? parsePatchIndex(Uint8List packet) {
    if (packet.length < 12 || packet[8] != 0x10) return null;
    return packet[9];
  }

  /// Parse active effect switches from a 60 00 00 00 DT1 response
  static Map<EffectCategory, bool>? parseActiveEffectSwitches(Uint8List packet) {
    if (packet.length < 95) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1 || packet[8] != 0x60 || packet[9] != 0x00) {
      return null;
    }
    // Base payload starts at index 12 (Address 60 00 00 00)
    const base = 12;
    return {
      EffectCategory.comp: packet[base + 0x20] != 0x00,
      EffectCategory.odDs: packet[base + 0x30] != 0x00,
      EffectCategory.preamp: packet[base + 0x50] != 0x00,
    };
  }

  /// Build Roland SysEx DT1 Patch Change for User Patches (U01 - U99).
  /// [patchIndex] ranges from 0 (U01) to 98 (U99).
  /// Format: Address 00 01 00 00, Data [00, patchIndex]
  static Uint8List buildPatchChange(int patchIndex, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(patchIndex >= 0 && patchIndex <= 98, 'Patch index must be 0..98');
    return buildDt1Message(
      address: Gt1bAddresses.currentPatchNo,
      data: [(patchIndex >> 7) & 0x7F, patchIndex & 0x7F],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Build Standard MIDI Program Change (PC) fallback.
  static Uint8List buildProgramChange(int patchIndex, {int channel = 0}) {
    assert(patchIndex >= 0 && patchIndex <= 98, 'Patch index must be 0..98');
    final status = 0xC0 | (channel & 0x0F);
    return Uint8List.fromList([status, patchIndex]);
  }

  /// Toggle Tuner mode ON or OFF.
  /// Uses runningMode address [7F, 00, 00, 02] (01 = Tuner, 00 = Play).
  static Uint8List buildTunerToggle({bool enable = true, List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: Gt1bAddresses.runningMode,
      data: [enable ? 0x01 : 0x00],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Toggle an effect category ON or OFF.
  static Uint8List buildEffectToggle(EffectCategory category, bool isEnabled, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
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
      deviceId: deviceId,
    );
  }
}
