import 'dart:typed_data';
import '../domain/models/patch_model.dart';
import '../models/effect_block.dart';
import '../protocol/roland_sysex.dart';
import 'write_queue.dart';

/// Callbacks para eventos en tiempo real provenientes del hardware.
class EventRouterHandlers {
  final void Function(PatchRef patchRef)? onPatchChanged;
  final void Function(bool isTunerActive)? onTunerToggled;
  final void Function(EffectCategory category, bool isEnabled)? onEffectSwitchChanged;
  final void Function(int level)? onFootVolumeChanged;
  final void Function(int position)? onWahPositionChanged;
  final void Function(int slotIndex, int chainId)? onChainSlotChanged;
  final void Function(List<int> chainIds)? onFullChainOrderChanged;
  final void Function(List<int> address, int value)? onParameterChanged;

  const EventRouterHandlers({
    this.onPatchChanged,
    this.onTunerToggled,
    this.onEffectSwitchChanged,
    this.onFootVolumeChanged,
    this.onWahPositionChanged,
    this.onChainSlotChanged,
    this.onFullChainOrderChanged,
    this.onParameterChanged,
  });
}

/// Enrutador de eventos entrantes desde la Boss GT-1B hacia la arquitectura de dominio.
/// Resuelve D1, D3, D5, D6, H6, H7, H8, H9, H10.
class EventRouter {
  final WriteQueue? writeQueue;
  EventRouterHandlers handlers;

  EventRouter({
    this.writeQueue,
    this.handlers = const EventRouterHandlers(),
  });

  /// Procesa cualquier paquete entrante desde el transporte.
  void processIncomingPacket(Uint8List packet) {
    if (packet.isEmpty) return;

    // 1. Mensaje estándar MIDI Program Change (0xC0 [patchIndex])
    if (packet.length >= 2 && (packet[0] & 0xF0) == 0xC0) {
      final rawIndex = packet[1];
      if (rawIndex <= 197) {
        handlers.onPatchChanged?.call(PatchRef.fromRawIndex(rawIndex));
      }
      return;
    }

    // 2. Roland SysEx DT1
    final dt1 = RolandSysEx.parseDt1(packet);
    if (dt1 == null) return;

    final addr = dt1.address;
    final data = dt1.data;
    if (data.isEmpty) return;

    // Supresión de eco: si nosotros enviamos este cambio, descartarlo (H3)
    if (writeQueue?.consumeEchoIfMatches(addr, data) ?? false) {
      return;
    }

    final a0 = addr[0];
    final a1 = addr[1];
    final a2 = addr[2];
    final a3 = addr[3];
    final val = data[0];

    // A. Cambio de Preset (00 01 00 00) - 2 bytes de número (0 a 197) (H9, D4)
    if (a0 == 0x00 && a1 == 0x01 && a2 == 0x00 && a3 == 0x00) {
      if (data.length >= 2) {
        final rawIndex = (data[0] << 7) | data[1];
        if (rawIndex <= 197) {
          handlers.onPatchChanged?.call(PatchRef.fromRawIndex(rawIndex));
        }
      }
      return;
    }

    // B. Afinador / Modo de Reproducción (7F 00 00 02)
    if (a0 == 0x7F && a1 == 0x00 && a2 == 0x00 && a3 == 0x02) {
      handlers.onTunerToggled?.call(val == 0x01);
      return;
    }

    // C. Cadena de Efectos (Memory Edit)
    // Caso 1: Cadena completa de 20 bytes (60 00 07 20)
    if (a0 == 0x60 && a1 == 0x00 && a2 == 0x07 && a3 == 0x20 && data.length >= 20) {
      handlers.onFullChainOrderChanged?.call(data.sublist(0, 20).toList());
      return;
    }
    // Caso 2: Slot individual modificado en vivo (60 00 07 20 + n) (H8, D5)
    if (a0 == 0x60 && a1 == 0x00 && a2 == 0x07 && a3 >= 0x20 && a3 <= 0x33) {
      final slotIndex = a3 - 0x20;
      handlers.onChainSlotChanged?.call(slotIndex, val);
      return;
    }

    // D. Switches y Controles en Buffer Temporal (60 00 ...)
    if (a0 == 0x60 && a1 == 0x00) {
      // COMP SW (60 00 00 20)
      if (a2 == 0x00 && a3 == 0x20) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.comp, val != 0);
        return;
      }
      // OD/DS SW (60 00 00 30)
      if (a2 == 0x00 && a3 == 0x30) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.odDs, val != 0);
        return;
      }
      // PREAMP SW (60 00 00 50)
      if (a2 == 0x00 && a3 == 0x50) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.preamp, val != 0);
        return;
      }
      // EQ SW (60 00 01 30)
      if (a2 == 0x01 && a3 == 0x30) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.eq, val != 0);
        return;
      }
      // FX1 SW (60 00 01 40)
      if (a2 == 0x01 && a3 == 0x40) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.fx1, val != 0);
        return;
      }
      // FX2 SW (60 00 03 4C)
      if (a2 == 0x03 && a3 == 0x4C) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.fx2, val != 0);
        return;
      }
      // DELAY SW (60 00 05 60)
      if (a2 == 0x05 && a3 == 0x60) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.delay, val != 0);
        return;
      }
      // CHORUS SW (60 00 06 00)
      if (a2 == 0x06 && a3 == 0x00) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.chorus, val != 0);
        return;
      }
      // REVERB SW (60 00 06 10)
      if (a2 == 0x06 && a3 == 0x10) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.reverb, val != 0);
        return;
      }
      // WAH / PEDAL FX SW (60 00 06 20)
      if (a2 == 0x06 && a3 == 0x20) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.pedalFx, val != 0);
        return;
      }
      // WAH POSITION (60 00 06 27)
      if (a2 == 0x06 && a3 == 0x27) {
        handlers.onWahPositionChanged?.call(val);
        return;
      }
      // FOOT VOLUME LEVEL (60 00 06 33) - Nivel continuo 0..100 (H10, D6)
      if (a2 == 0x06 && a3 == 0x33) {
        handlers.onFootVolumeChanged?.call(val);
        return;
      }
      // NOISE SUPPRESSOR SW (60 00 06 63)
      if (a2 == 0x06 && a3 == 0x63) {
        handlers.onEffectSwitchChanged?.call(EffectCategory.noiseSuppressor, val != 0);
        return;
      }

      // E. Cualquier parámetro continuo de perillas (Gain, Tone, Level, Time...)
      handlers.onParameterChanged?.call(addr, val);
    }
  }
}
