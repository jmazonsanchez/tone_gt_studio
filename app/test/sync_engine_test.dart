import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/domain/models/patch_model.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/sync/event_router.dart';
import 'package:tone_gt_studio/sync/sync_engine.dart';
import 'package:tone_gt_studio/sync/write_queue.dart';

void main() {
  group('SyncEngine & WriteQueue Tests with FakeTransport', () {
    late FakeTransport transport;
    late EventRouter eventRouter;
    late WriteQueue writeQueue;
    late SyncEngine syncEngine;

    setUp(() async {
      transport = FakeTransport();
      await transport.connect();
      writeQueue = WriteQueue(transport: transport);
      eventRouter = EventRouter(writeQueue: writeQueue);
      syncEngine = SyncEngine(transport: transport, eventRouter: eventRouter);
    });

    tearDown(() {
      syncEngine.dispose();
      writeQueue.dispose();
      transport.dispose();
    });

    test('Reads current patch number from setup buffer (00 01 00 00)', () async {
      final ref = await syncEngine.readCurrentPatchNumber();
      expect(ref, isNotNull);
      expect(ref!.bank, equals(PatchBank.user));
      expect(ref.number, equals(1)); // Default U01
    });

    test('Reads active patch data with exact 4-byte matching (Solves D1, H4)', () async {
      final active = await syncEngine.readActivePatch();
      expect(active, isNotNull);
      expect(active!.switches[EffectCategory.comp], isFalse);
      expect(active.switches[EffectCategory.odDs], isTrue);
      expect(active.switches[EffectCategory.preamp], isTrue);
      expect(active.footVolumeLevel, equals(100));
    });

    test('WriteQueue throttles and suppresses echo of own writes (H3)', () async {
      bool receivedEchoInRouter = false;
      eventRouter.handlers = EventRouterHandlers(
        onEffectSwitchChanged: (cat, enabled) {
          receivedEchoInRouter = true;
        },
      );

      // Escribir COMP ON a través de WriteQueue
      writeQueue.queueWrite([0x60, 0x00, 0x00, 0x20], [0x01]);

      // Esperar tiempo suficiente para que WriteQueue envíe y FakeTransport devuelva el eco
      await Future.delayed(const Duration(milliseconds: 80));

      // El router NO debe haber disparado callback de evento de usuario porque era nuestro propio eco
      expect(receivedEchoInRouter, isFalse);
    });
  });
}
