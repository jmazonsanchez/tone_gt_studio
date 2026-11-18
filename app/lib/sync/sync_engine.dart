import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/transport/midi_transport.dart';
import '../domain/models/patch_model.dart';
import '../models/effect_block.dart';
import '../protocol/roland_sysex.dart';
import 'event_router.dart';

/// Resultado de lectura de bloques de efectos activos desde la memoria temporal.
class ActivePatchData {
  final String name;
  final Map<EffectCategory, bool> switches;
  final int footVolumeLevel;
  final int wahPosition;
  final List<int> fxChain;

  const ActivePatchData({
    required this.name,
    required this.switches,
    required this.footVolumeLevel,
    required this.wahPosition,
    required this.fxChain,
  });
}

/// Motor de sincronización y peticiones serializadas hacia la Boss GT-1B.
/// Resuelve D1 (matching de 4 bytes), H4 (tramos ≤ 128B), H7 (recarga en cambio de patch).
class SyncEngine {
  final MidiTransport transport;
  final EventRouter eventRouter;

  StreamSubscription<Uint8List>? _transportSub;
  Completer<Uint8List?>? _activeRequestCompleter;
  List<int>? _activeExpectedAddress;

  SyncEngine({
    required this.transport,
    required this.eventRouter,
  }) {
    _transportSub = transport.onDataReceived.listen(_handleIncomingData);
  }

  void _handleIncomingData(Uint8List packet) {
    if (packet.isEmpty) return;

    // Verificar si es respuesta al RQ1 que estamos esperando actualmente (Matching 4 bytes D1)
    if (_activeRequestCompleter != null && !_activeRequestCompleter!.isCompleted) {
      final dt1 = RolandSysEx.parseDt1(packet);
      if (dt1 != null && _activeExpectedAddress != null) {
        if (RolandSysEx.addressMatches(dt1.address, _activeExpectedAddress!)) {
          _activeRequestCompleter!.complete(packet);
          return;
        }
      }
    }

    // Si no es la respuesta esperada o no hay petición pendiente, pasa al EventRouter
    eventRouter.processIncomingPacket(packet);
  }

  /// Envía un RQ1 y espera la respuesta DT1 emparejada por los 4 bytes de dirección.
  Future<Uint8List?> requestData(
    List<int> address,
    int size, {
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    assert(address.length == 4, 'La dirección debe tener 4 bytes');
    if (!transport.isConnected) return null;

    final completer = Completer<Uint8List?>();
    _activeRequestCompleter = completer;
    _activeExpectedAddress = address;

    final rq1 = RolandSysEx.buildRq1(address: address, size: size);
    await transport.send(rq1);

    try {
      final reply = await completer.future.timeout(timeout);
      return reply;
    } catch (_) {
      return null;
    } finally {
      if (_activeRequestCompleter == completer) {
        _activeRequestCompleter = null;
        _activeExpectedAddress = null;
      }
    }
  }

  /// Lee el preset activo actualmente (0 a 197).
  Future<PatchRef?> readCurrentPatchNumber() async {
    final reply = await requestData([0x00, 0x01, 0x00, 0x00], 2);
    if (reply != null) {
      final dt1 = RolandSysEx.parseDt1(reply);
      if (dt1 != null && dt1.data.length >= 2) {
        final rawIndex = (dt1.data[0] << 7) | dt1.data[1];
        if (rawIndex <= 197) {
          return PatchRef.fromRawIndex(rawIndex);
        }
      }
    }
    return null;
  }

  /// Lee la configuración completa del preset activo en tramos ≤ 128 bytes (H4, H7).
  Future<ActivePatchData?> readActivePatch() async {
    if (!transport.isConnected) return null;

    String name = 'DEFAULT';
    final switches = <EffectCategory, bool>{};
    int footVol = 100;
    int wahPos = 50;
    List<int> chain = [];

    // Tramo 1: Bloque 60 00 00 00 (Nombre + COMP + OD/DS + PREAMP) (128 bytes)
    final block0 = await requestData([0x60, 0x00, 0x00, 0x00], 128);
    if (block0 != null) {
      final dt1 = RolandSysEx.parseDt1(block0);
      if (dt1 != null && dt1.data.length >= 0x51) {
        // Nombre (16 bytes)
        final nameBytes = dt1.data.sublist(0, 16);
        name = nameBytes.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : ' ').join().trim();

        switches[EffectCategory.comp] = dt1.data[0x20] != 0;
        switches[EffectCategory.odDs] = dt1.data[0x30] != 0;
        switches[EffectCategory.preamp] = dt1.data[0x50] != 0;
      }
    }

    // Tramo 2: Bloque 60 00 01 00 (EQ + FX1) (128 bytes)
    final block1 = await requestData([0x60, 0x00, 0x01, 0x00], 128);
    if (block1 != null) {
      final dt1 = RolandSysEx.parseDt1(block1);
      if (dt1 != null && dt1.data.length >= 0x41) {
        switches[EffectCategory.eq] = dt1.data[0x30] != 0;
        switches[EffectCategory.fx1] = dt1.data[0x40] != 0;
      }
    }

    // Tramo 3: Bloque 60 00 03 4C (FX2) (1 byte)
    final blockFx2 = await requestData([0x60, 0x00, 0x03, 0x4C], 1);
    if (blockFx2 != null) {
      final dt1 = RolandSysEx.parseDt1(blockFx2);
      if (dt1 != null && dt1.data.isNotEmpty) {
        switches[EffectCategory.fx2] = dt1.data[0] != 0;
      }
    }

    // Tramo 4: Bloque 60 00 05 60 (DELAY) (1 byte)
    final blockDly = await requestData([0x60, 0x00, 0x05, 0x60], 1);
    if (blockDly != null) {
      final dt1 = RolandSysEx.parseDt1(blockDly);
      if (dt1 != null && dt1.data.isNotEmpty) {
        switches[EffectCategory.delay] = dt1.data[0] != 0;
      }
    }

    // Tramo 5: Bloque 60 00 06 00 (CHORUS, REVERB, WAH, FOOT VOL, NS) (128 bytes)
    final block6 = await requestData([0x60, 0x00, 0x06, 0x00], 128);
    if (block6 != null) {
      final dt1 = RolandSysEx.parseDt1(block6);
      if (dt1 != null && dt1.data.length >= 0x64) {
        switches[EffectCategory.chorus] = dt1.data[0x00] != 0;
        switches[EffectCategory.reverb] = dt1.data[0x10] != 0;
        switches[EffectCategory.pedalFx] = dt1.data[0x20] != 0;
        wahPos = dt1.data[0x27];
        footVol = dt1.data[0x33];
        switches[EffectCategory.footVolume] = footVol > 0;
        switches[EffectCategory.noiseSuppressor] = dt1.data[0x63] != 0;
      }
    }

    // Tramo 6: Cadena de efectos (60 00 07 20, 20 bytes)
    final blockChain = await requestData([0x60, 0x00, 0x07, 0x20], 20);
    if (blockChain != null) {
      final dt1 = RolandSysEx.parseDt1(blockChain);
      if (dt1 != null && dt1.data.length >= 20) {
        chain = dt1.data.sublist(0, 20).toList();
      }
    }

    return ActivePatchData(
      name: name,
      switches: switches,
      footVolumeLevel: footVol,
      wahPosition: wahPos,
      fxChain: chain,
    );
  }

  /// Lee el nombre de un preset específico (U01..U99 o P01..P99) (H9).
  Future<String?> readPatchName(PatchRef ref) async {
    final baseAddr = ref.bank == PatchBank.user ? 0x10 : 0x20;
    final patchIdx = ref.number - 1;

    final reply = await requestData([baseAddr, patchIdx, 0x00, 0x00], 16, timeout: const Duration(milliseconds: 350));
    if (reply != null) {
      final dt1 = RolandSysEx.parseDt1(reply);
      if (dt1 != null && dt1.data.length >= 16) {
        return dt1.data.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : ' ').join().trim();
      }
    }
    return null;
  }

  void dispose() {
    _transportSub?.cancel();
  }
}
