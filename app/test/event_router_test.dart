import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/domain/models/patch_model.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/protocol/roland_sysex.dart';
import 'package:tone_gt_studio/sync/event_router.dart';

void main() {
  group('EventRouter Real-Time Hardware Tests', () {
    test('Routes physical effect switch events to correct handler', () {
      EffectCategory? changedCat;
      bool? changedState;

      final router = EventRouter(
        handlers: EventRouterHandlers(
          onEffectSwitchChanged: (cat, enabled) {
            changedCat = cat;
            changedState = enabled;
          },
        ),
      );

      // Simular botón físico OD/DS encendido en la pedalera (60 00 00 30 = 01)
      final odDsPacket = RolandSysEx.buildDt1(
        address: [0x60, 0x00, 0x00, 0x30],
        data: [0x01],
      );
      router.processIncomingPacket(odDsPacket);

      expect(changedCat, equals(EffectCategory.odDs));
      expect(changedState, isTrue);

      // Simular botón físico PREAMP apagado en la pedalera (60 00 00 50 = 00)
      final preampPacket = RolandSysEx.buildDt1(
        address: [0x60, 0x00, 0x00, 0x50],
        data: [0x00],
      );
      router.processIncomingPacket(preampPacket);

      expect(changedCat, equals(EffectCategory.preamp));
      expect(changedState, isFalse);
    });

    test('Routes User and Factory Preset patch changes up to 197 (H9, D4)', () {
      PatchRef? receivedRef;

      final router = EventRouter(
        handlers: EventRouterHandlers(
          onPatchChanged: (ref) => receivedRef = ref,
        ),
      );

      // Presionar pedal hacia U05 (rawIndex = 4 -> [00, 04])
      final u05Packet = RolandSysEx.buildDt1(
        address: [0x00, 0x01, 0x00, 0x00],
        data: [0x00, 0x04],
      );
      router.processIncomingPacket(u05Packet);

      expect(receivedRef, isNotNull);
      expect(receivedRef!.bank, equals(PatchBank.user));
      expect(receivedRef!.number, equals(5));
      expect(receivedRef!.displayNumber, equals('U05'));
      expect(receivedRef!.isReadOnly, isFalse);

      // Presionar pedal hacia P99 (rawIndex = 197 = 0x01, 0x45 capturado en hardware real H9)
      final p99Packet = RolandSysEx.buildDt1(
        address: [0x00, 0x01, 0x00, 0x00],
        data: [0x01, 0x45],
      );
      router.processIncomingPacket(p99Packet);

      expect(receivedRef, isNotNull);
      expect(receivedRef!.bank, equals(PatchBank.preset));
      expect(receivedRef!.number, equals(99));
      expect(receivedRef!.displayNumber, equals('P99'));
      expect(receivedRef!.isReadOnly, isTrue);
    });

    test('Routes continuous Foot Volume level (0..100) (H10, D6)', () {
      int? receivedLevel;

      final router = EventRouter(
        handlers: EventRouterHandlers(
          onFootVolumeChanged: (level) => receivedLevel = level,
        ),
      );

      // Barrido de pedal de volumen al 75%
      final fvPacket = RolandSysEx.buildDt1(
        address: [0x60, 0x00, 0x06, 0x33],
        data: [0x4B], // 75 dec
      );
      router.processIncomingPacket(fvPacket);

      expect(receivedLevel, equals(75));
    });

    test('Routes single-slot chain order modifications in Memory Edit (H8, D5)', () {
      int? changedSlot;
      int? changedId;

      final router = EventRouter(
        handlers: EventRouterHandlers(
          onChainSlotChanged: (slot, id) {
            changedSlot = slot;
            changedId = id;
          },
        ),
      );

      // Evento capturado en hardware real: 60 00 07 27 data=0B (slot 7 = ID 11 NS)
      final slotPacket = RolandSysEx.buildDt1(
        address: [0x60, 0x00, 0x07, 0x27],
        data: [0x0B],
      );
      router.processIncomingPacket(slotPacket);

      expect(changedSlot, equals(7)); // 0x27 - 0x20 = 7
      expect(changedId, equals(0x0B));
    });

    test('Routes Tuner running mode switch (7F 00 00 02)', () {
      bool? isTuner;

      final router = EventRouter(
        handlers: EventRouterHandlers(
          onTunerToggled: (active) => isTuner = active,
        ),
      );

      final tunerOn = RolandSysEx.buildDt1(
        address: [0x7F, 0x00, 0x00, 0x02],
        data: [0x01],
      );
      router.processIncomingPacket(tunerOn);

      expect(isTuner, isTrue);
    });
  });
}
