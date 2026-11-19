import 'dart:typed_data';
import 'gt1b_addresses.dart';
import '../models/effect_block.dart';
import '../models/system_settings.dart';

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

  /// Request FX chain order for user patch (address 10 [patchIndex] 07 20) or preset factory patch (address 20 [patchIndex] 07 20).
  /// [patchIndex] ranges from 0 to 98 (representing patch 01 to 99).
  static Uint8List buildPatchFxChainRequest(
    int patchIndex, {
    bool isFactoryPreset = false,
    List<int> modelId = modelIdGt1b,
    int deviceId = defaultDeviceId,
  }) {
    assert(patchIndex >= 0 && patchIndex <= 98, 'Patch index must be 0..98');
    final baseAddr = isFactoryPreset ? 0x20 : 0x10;
    return buildRq1Message(
      address: [baseAddr, patchIndex, 0x07, 0x20],
      size: [0x00, 0x00, 0x00, 0x14],
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

  /// Default 20-slot authentic hardware chain order of Boss GT-1B.
  /// Fixed slots 0..6: [0, 1, 4, 8, 10, 14, 17]
  /// Movable slots 7..15 (authentic 9 blocks): [5, 2, 13, 15, 12, 11, 7, 6, 9]
  /// Fixed slots 16..19: [18, 3, 19, 16]
  static const List<int> defaultHardwareChain = [
    0, 1, 4, 8, 10, 14, 17, 5, 2, 13, 15, 12, 11, 7, 6, 9, 18, 3, 19, 16
  ];

  /// Request Block 1 (EQ, FX1 switch, FX1 algorithm type & parameters) (address 60 00 01 00, size 127 bytes).
  static Uint8List buildEffectsBlock1Request({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x60, 0x00, 0x01, 0x00],
      size: [0x00, 0x00, 0x00, 0x7F],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request Block 3 (FX2 switch, FX2 algorithm type & parameters) (address 60 00 03 4C, size 52 bytes).
  static Uint8List buildEffectsBlock3Request({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x60, 0x00, 0x03, 0x4C],
      size: [0x00, 0x00, 0x00, 0x34],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request Block 5 (DELAY switch, DELAY type & parameters) (address 60 00 05 60, size 16 bytes).
  static Uint8List buildEffectsBlock5Request({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x60, 0x00, 0x05, 0x60],
      size: [0x00, 0x00, 0x00, 0x10],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request Block 7 (MASTER Level, Master EQ, BPM, Key) (address 60 00 07 10, size 16 bytes).
  static Uint8List buildEffectsBlock7Request({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x60, 0x00, 0x07, 0x10],
      size: [0x00, 0x00, 0x00, 0x10],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Request System Settings block (address 00 00 00 00, size 127 bytes).
  static Uint8List buildSystemRequest({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildRq1Message(
      address: [0x00, 0x00, 0x00, 0x00],
      size: [0x00, 0x00, 0x00, 0x7F],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Parse real-time live chromatic tuner pitch reading (address 7F 00 05 00).
  /// Returns (noteIndex 0..11, rawCentValue 0..100) or null.
  static (int, int)? parseLivePitch(Uint8List packet) {
    if (packet.length < 15) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1) return null;
    if (packet[8] != 0x7F || packet[9] != 0x00 || packet[10] != 0x05 || packet[11] != 0x00) {
      return null;
    }
    return (packet[12], packet[13]);
  }

  /// Parse System Settings packet from GT-1B (address 00 00 00 00).
  static void parseSystemSettings(Uint8List packet, SystemSettings settings) {
    if (packet.length < 30) return;
    if (packet[0] != 0xF0 || packet[7] != commandDt1) return;
    if (packet[8] != 0x00 || packet[9] != 0x00 || packet[10] != 0x00 || packet[11] != 0x00) {
      return;
    }
    final data = packet.sublist(12, packet.length - 2);
    if (data.length > 0x20) settings.tunerPitch = data[0x20];
    if (data.length > 0x21) settings.tunerOutput = data[0x21];
    if (data.length > 0x30) settings.metronomeOn = data[0x30] != 0;
    if (data.length > 0x32) settings.metronomeTempo = ((data[0x32] << 7) | data[0x31]).clamp(20, 250);
    if (data.length > 0x33) settings.metronomeBeat = data[0x33];
    if (data.length > 0x34) settings.metronomeLevel = data[0x34];
    if (data.length > 0x51) settings.usbSecondaryIn = data[0x51];
    if (data.length > 0x52) settings.usbPrimaryOut = data[0x52];
    if (data.length > 0x53) settings.usbPrimaryMix = data[0x53];
    if (data.length > 0x54) settings.usbDirectMonitor = data[0x54] != 0;
    if (data.length > 0x57) settings.usbSecondaryOut = data[0x57];
    if (data.length > 0x60) settings.autoOff = data[0x60];
    if (data.length > 0x70) settings.outputSelect = data[0x70];
    if (data.length > 0x71) settings.inputLevel = data[0x71];
    if (data.length > 0x72) settings.eqLowGain = data[0x72];
    if (data.length > 0x73) settings.eqMidGain = data[0x73];
    if (data.length > 0x74) settings.eqMidFreq = data[0x74];
    if (data.length > 0x75) settings.eqMidQ = data[0x75];
    if (data.length > 0x76) settings.eqHighGain = data[0x76];
    if (data.length > 0x78) settings.totalReverb = data[0x78];
  }

  /// Build full FX chain order update (address 60 00 07 20, 20 slot IDs).
  /// If given 9 movable block IDs, maps them into slots 7..15 of the authentic 20-slot chain.
  /// Replaces any missing positions with authentic valid GT-1B routing IDs (never 0xFF!).
  static Uint8List buildFxChainOrder(List<int> chainIds, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    List<int> fullChain;
    if (chainIds.length == 20) {
      fullChain = List<int>.from(chainIds);
    } else if (chainIds.length == 9) {
      fullChain = List<int>.from(defaultHardwareChain);
      for (int i = 0; i < 9; i++) {
        fullChain[7 + i] = chainIds[i];
      }
    } else {
      fullChain = List<int>.from(chainIds);
      for (final id in defaultHardwareChain) {
        if (fullChain.length >= 20) break;
        if (!fullChain.contains(id)) {
          fullChain.add(id);
        }
      }
    }
    return buildDt1Message(
      address: Gt1bAddresses.fxChainBase,
      data: fullChain.sublist(0, 20),
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Mapping from authentic GT-1B hardware FX Chain IDs (0..19) to EffectCategory.
  /// Exactly 9 movable stompboxes exist in GT-1B hardware:
  /// PDL=5, OD=2, PREAMP=13, FX1=15, NS=12, FV=11, FX2=7, DELAY=6, REVERB=9.
  static const Map<int, EffectCategory> chainIdToCategory = {
    5: EffectCategory.pedalFx,
    2: EffectCategory.odDs,
    13: EffectCategory.preamp,
    15: EffectCategory.fx1,
    12: EffectCategory.noiseSuppressor,
    11: EffectCategory.footVolume,
    7: EffectCategory.fx2,
    6: EffectCategory.delay,
    9: EffectCategory.reverb,
  };

  static const Map<EffectCategory, int> categoryToChainId = {
    EffectCategory.pedalFx: 5,
    EffectCategory.odDs: 2,
    EffectCategory.preamp: 13,
    EffectCategory.fx1: 15,
    EffectCategory.noiseSuppressor: 12,
    EffectCategory.footVolume: 11,
    EffectCategory.fx2: 7,
    EffectCategory.delay: 6,
    EffectCategory.reverb: 9,
  };

  /// Parse FX Chain order from a DT1 response (60 00 07 20, 10 [idx] 07 20, 20 [idx] 07 20)
  static List<int>? parseFxChainOrder(Uint8List packet) {
    if (packet.length < 14) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1) return null;
    if ((packet[8] != 0x60 && packet[8] != 0x10 && packet[8] != 0x20) ||
        packet[10] != 0x07 ||
        packet[11] != 0x20) {
      return null;
    }
    final end = (packet.length - 2).clamp(12, 32);
    if (end <= 12) return null;
    return packet.sublist(12, end).toList();
  }

  /// Parse the patch index from an FX Chain DT1 packet if it's from a user/preset patch
  static int? parseFxChainPatchIndex(Uint8List packet) {
    if (packet.length < 12) return null;
    if (packet[10] != 0x07 || packet[11] != 0x20) return null;
    if (packet[8] == 0x10) return packet[9];
    if (packet[8] == 0x20) return 99 + packet[9];
    return null;
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

  /// Parse algorithm type for FX1 and FX2 from Block 1 or Block 3 DT1 responses
  static Map<EffectCategory, int>? parseFxTypes(Uint8List packet) {
    if (packet.length < 14) return null;
    if (packet[0] != 0xF0 || packet[7] != commandDt1 || packet[8] != 0x60) {
      return null;
    }
    const base = 12;
    final addrHigh = packet[9];
    final addrMid = packet[10];
    final addrLow = packet[11];
    final result = <EffectCategory, int>{};

    // Block 60 00 01 00: FX1 type at 60 00 01 41
    if (addrHigh == 0x00 && addrMid == 0x01 && addrLow == 0x00) {
      if (packet.length >= base + 0x42) {
        result[EffectCategory.fx1] = packet[base + 0x41];
      }
    }
    // Block 60 00 03 4C: FX2 type at 60 00 03 4D
    else if (addrHigh == 0x00 && addrMid == 0x03 && addrLow == 0x4C) {
      if (packet.length >= base + 2) {
        result[EffectCategory.fx2] = packet[base + 0x01];
      }
    }

    return result.isEmpty ? null : result;
  }

  /// Parse parameter values from a DT1 response packet into matching EffectParameters.
  /// Matches parameters whose 4-byte address falls within the packet address range.
  static void parseActivePatchParameters(
    Uint8List packet,
    List<EffectBlock> effects, {
    Map<String, int>? masterValues,
  }) {
    if (packet.length < 14) return;
    if (packet[0] != 0xF0 || packet[7] != commandDt1) return;
    final a0 = packet[8];
    final a1 = packet[9];
    final a2 = packet[10];
    final a3 = packet[11];
    final data = packet.sublist(12, packet.length - 2);

    for (final effect in effects) {
      for (final param in effect.parameters) {
        if (param.address.length >= 4 &&
            param.address[0] == a0 &&
            param.address[1] == a1 &&
            param.address[2] == a2) {
          final offset = param.address[3] - a3;
          if (offset >= 0 && offset < data.length) {
            if (param.max > 127 && offset + 1 < data.length) {
              param.value = (data[offset] << 7) | data[offset + 1];
            } else {
              param.value = data[offset];
            }
          }
        }
      }
    }

    if (masterValues != null && a0 == 0x60 && a1 == 0x00 && a2 == 0x07 && a3 <= 0x18) {
      final base = 0x10 - a3;
      if (base >= 0 && base < data.length) masterValues['patch_level'] = data[base];
      if (base + 1 >= 0 && base + 1 < data.length) masterValues['master_eq_low'] = data[base + 1];
      if (base + 2 >= 0 && base + 2 < data.length) masterValues['master_eq_mid_freq'] = data[base + 2];
      if (base + 3 >= 0 && base + 3 < data.length) masterValues['master_eq_mid_q'] = data[base + 3];
      if (base + 4 >= 0 && base + 4 < data.length) masterValues['master_eq_mid_gain'] = data[base + 4];
      if (base + 5 >= 0 && base + 5 < data.length) masterValues['master_eq_high'] = data[base + 5];
      if (base + 7 >= 0 && base + 7 < data.length) {
        masterValues['master_bpm'] = (data[base + 6] << 7) | data[base + 7];
      }
      if (base + 8 >= 0 && base + 8 < data.length) masterValues['master_key'] = data[base + 8];
    }
  }

  /// Build Roland SysEx DT1 Patch Change for all 198 Presets (U01-U99 and P01-P99).
  /// [patchIndex] ranges from 0 (U01) to 197 (P99) (H9, D4).
  /// Format: Address 00 01 00 00, Data [(patchIndex >> 7) & 0x7F, patchIndex & 0x7F]
  static Uint8List buildPatchChange(int patchIndex, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(patchIndex >= 0 && patchIndex <= 197, 'Patch index must be 0..197');
    return buildDt1Message(
      address: Gt1bAddresses.currentPatchNo,
      data: [(patchIndex >> 7) & 0x7F, patchIndex & 0x7F],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Build Standard MIDI Program Change (PC) fallback.
  static Uint8List buildProgramChange(int patchIndex, {int channel = 0}) {
    assert(patchIndex >= 0 && patchIndex <= 127, 'MIDI Program Change index must be 0..127');
    final status = 0xC0 | (channel & 0x0F);
    return Uint8List.fromList([status, patchIndex & 0x7F]);
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

  /// Toggle Phrase Loop Mode ON or OFF (address 00 00 01 00).
  static Uint8List buildPhraseLoopToggle({bool enable = true, List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: Gt1bAddresses.phraseLoopMode,
      data: [enable ? 0x01 : 0x00],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Set Phrase Loop Playback Level (address 00 00 01 04, range 0..120).
  static Uint8List buildPhraseLoopLevel(int level, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: Gt1bAddresses.phraseLoopPlayLevel,
      data: [level.clamp(0, 120)],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Set Phrase Loop Rec Mode (address 00 00 01 02, 00 = REC->DUB, 01 = REC->PLAY).
  static Uint8List buildPhraseLoopRecMode(int mode, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: Gt1bAddresses.phraseLoopRecMode,
      data: [mode.clamp(0, 1)],
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

  /// Build SysEx DT1 command to write the active temporary patch into permanent user memory (U01..U99).
  /// Target user index must be 0..98 (never >= 99, factory presets are read-only).
  static Uint8List buildPatchWrite(int targetUserIndex, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(targetUserIndex >= 0 && targetUserIndex < 99, 'Can only write to User patches (0..98)');
    final high = (targetUserIndex >> 7) & 0x7F;
    final low = targetUserIndex & 0x7F;
    return buildDt1Message(
      address: [0x7F, 0x00, 0x01, 0x04],
      data: [high, low],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Build SysEx DT1 command to copy a patch from one slot to a user slot (0..98).
  static Uint8List buildPatchCopy(int fromIndex, int toUserIndex, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    assert(toUserIndex >= 0 && toUserIndex < 99, 'Target of copy must be a User patch (0..98)');
    final fromHigh = (fromIndex >> 7) & 0x7F;
    final fromLow = fromIndex & 0x7F;
    final toHigh = (toUserIndex >> 7) & 0x7F;
    final toLow = toUserIndex & 0x7F;
    return buildDt1Message(
      address: [0x7F, 0x00, 0x01, 0x00],
      data: [fromHigh, fromLow, toHigh, toLow],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Build SysEx DT1 command to initialize the current patch to default factory state.
  static Uint8List buildPatchInitialize({List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    return buildDt1Message(
      address: [0x7F, 0x01, 0x00, 0x04],
      data: [0x01],
      modelId: modelId,
      deviceId: deviceId,
    );
  }

  /// Build SysEx DT1 to rename the active patch in temporary buffer (16 ASCII chars).
  static Uint8List buildPatchNameEdit(String newName, {List<int> modelId = modelIdGt1b, int deviceId = defaultDeviceId}) {
    final padded = newName.padRight(16, ' ').substring(0, 16);
    final bytes = padded.codeUnits.map((c) => c & 0x7F).toList();
    return buildDt1Message(
      address: [0x60, 0x00, 0x00, 0x00],
      data: bytes,
      modelId: modelId,
      deviceId: deviceId,
    );
  }
}
