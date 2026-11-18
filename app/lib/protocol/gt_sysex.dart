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

  /// Request patch name for user patch (address 10 [patchIndex] 00 00) or preset factory patch (address 20 [patchIndex] 00 00).
  /// [patchIndex] ranges from 0 to 98 (representing patch 01 to 99).
  static Uint8List buildPatchNameRequest(int patchIndex, {bool isFactoryPreset = false, List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(patchIndex >= 0 && patchIndex <= 98, 'Patch index must be 0..98');
    final baseAddr = isFactoryPreset ? 0x20 : 0x10;
    return buildRq1Message(
      address: [baseAddr, patchIndex, 0x00, 0x00],
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

  /// Request FX chain order (address 60 00 07 20, size 20 bytes).
  static Uint8List buildFxChainRequest({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: Gt1bAddresses.fxChainBase,
      size: [0x00, 0x00, 0x00, 0x14],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request second effects block (address 60 00 06 00, size 127 bytes: Chorus, Reverb, Wah, Foot Vol, NS).
  static Uint8List buildEffectsBlock6Request({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x60, 0x00, 0x06, 0x00],
      size: [0x00, 0x00, 0x00, 0x7F],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Mapping from GT-1B hardware FX Chain IDs (0..19) to EffectCategory
  static const Map<int, EffectCategory> chainIdToCategory = {
    0: EffectCategory.pedalFx,
    1: EffectCategory.comp,
    2: EffectCategory.chorus,
    4: EffectCategory.odDs,
    5: EffectCategory.delay,
    6: EffectCategory.reverb,
    8: EffectCategory.preamp,
    10: EffectCategory.eq,
    11: EffectCategory.noiseSuppressor,
    14: EffectCategory.fx1,
    15: EffectCategory.footVolume,
    17: EffectCategory.fx2,
  };

  static const Map<EffectCategory, int> categoryToChainId = {
    EffectCategory.pedalFx: 0,
    EffectCategory.comp: 1,
    EffectCategory.chorus: 2,
    EffectCategory.odDs: 4,
    EffectCategory.delay: 5,
    EffectCategory.reverb: 6,
    EffectCategory.preamp: 8,
    EffectCategory.eq: 10,
    EffectCategory.noiseSuppressor: 11,
    EffectCategory.fx1: 14,
    EffectCategory.footVolume: 15,
    EffectCategory.fx2: 17,
  };

  /// Parse FX Chain order from a 60 00 07 20 DT1 response
  static List<int>? parseFxChainOrder(Uint8List packet) {
    if (packet.length < 34) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1) return null;
    if (packet[8] != 0x60 || packet[9] != 0x00 || packet[10] != 0x07 || packet[11] != 0x20) {
      return null;
    }
    return packet.sublist(12, 32).toList();
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
    // Check if address starts with 0x10 (user patch list), 0x20 (preset patch list), or 0x60 (temporary patch)
    if (packet[8] != 0x10 && packet[8] != 0x20 && packet[8] != 0x60) return null;
    final nameBytes = packet.sublist(12, 28);
    final chars = nameBytes.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : ' ').join();
    return chars.trim();
  }

  /// Get the patch index (0..98) if packet is from user patch list (address 10 [idx] 00 00)
  static int? parsePatchIndex(Uint8List packet) {
    if (packet.length < 12 || packet[8] != 0x10) return null;
    return packet[9];
  }

  /// Parse active effect switches from a GT-1B DT1 response (60 00 00 00, 60 00 01 00, 60 00 06 00, etc.)
  static Map<EffectCategory, bool>? parseActiveEffectSwitches(Uint8List packet) {
    if (packet.length < 14) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1 || packet[8] != 0x60) {
      return null;
    }
    const base = 12;
    final addrHigh = packet[9];
    final addrMid = packet[10];
    final addrLow = packet[11];
    final result = <EffectCategory, bool>{};

    // Block 60 00 00 00 (COMP, OD/DS, PREAMP)
    if (addrHigh == 0x00 && addrMid == 0x00 && addrLow == 0x00) {
      if (packet.length >= base + 0x51) {
        result[EffectCategory.comp] = packet[base + 0x20] != 0x00;
        result[EffectCategory.odDs] = packet[base + 0x30] != 0x00;
        result[EffectCategory.preamp] = packet[base + 0x50] != 0x00;
      }
    }
    // Block 60 00 01 00 (EQ, FX1)
    else if (addrHigh == 0x00 && addrMid == 0x01) {
      if (packet.length >= base + 0x41) {
        result[EffectCategory.eq] = packet[base + 0x30] != 0x00;
        result[EffectCategory.fx1] = packet[base + 0x40] != 0x00;
      }
    }
    // Block 60 00 03 4C (FX2)
    else if (addrHigh == 0x00 && addrMid == 0x03 && addrLow == 0x4C) {
      result[EffectCategory.fx2] = packet[base] != 0x00;
    }
    // Block 60 00 05 60 (DELAY)
    else if (addrHigh == 0x00 && addrMid == 0x05 && addrLow == 0x60) {
      result[EffectCategory.delay] = packet[base] != 0x00;
    }
    // Block 60 00 06 00 (CHORUS, REVERB, WAH, FOOT VOLUME, NOISE SUPPRESSOR)
    else if (addrHigh == 0x00 && addrMid == 0x06 && addrLow == 0x00) {
      if (packet.length >= base + 0x64) {
        result[EffectCategory.chorus] = packet[base + 0x00] != 0x00;
        result[EffectCategory.reverb] = packet[base + 0x10] != 0x00;
        result[EffectCategory.pedalFx] = packet[base + 0x20] != 0x00;
        result[EffectCategory.footVolume] = packet[base + 0x33] > 0;
        result[EffectCategory.noiseSuppressor] = packet[base + 0x63] != 0x00;
      }
    }

    return result;
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

  /// Activate or deactivate Roland Editor Communication Mode (7F 00 00 01).
  /// When active, GT-1B transmits parameter changes live when physical buttons or knobs are manipulated.
  static Uint8List buildEditorMode({bool enable = true, List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: Gt1bAddresses.editorCommunicationMode,
      data: [enable ? 0x01 : 0x00],
      modelId: modelId,
      deviceId: deviceId,
    );
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
      case EffectCategory.pedalFx:
        address = Gt1bAddresses.pedalFxSwitch;
        break;
      case EffectCategory.noiseSuppressor:
        address = Gt1bAddresses.ns1Switch;
        break;
      case EffectCategory.footVolume:
        address = Gt1bAddresses.footVolume;
        break;
      case EffectCategory.eq:
        address = Gt1bAddresses.eqSwitch;
        break;
    }

    return buildDt1Message(
      address: address,
      data: [isEnabled ? 0x01 : 0x00],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Toggle WAH / Pedal FX Footswitch (Toe Switch)
  static Uint8List buildPedalFxToggle(bool isEnabled, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: Gt1bAddresses.pedalFxSwitch,
      data: [isEnabled ? 0x01 : 0x00],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Set WAH pedal sweep position (0..100)
  static Uint8List buildPedalFxWahPosition(int position, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(position >= 0 && position <= 100, 'Position must be 0..100');
    return buildDt1Message(
      address: Gt1bAddresses.pedalFxWahPosition,
      data: [position.clamp(0, 100)],
      modelId: modelId,
      deviceId: deviceId,
    );
  }
}
