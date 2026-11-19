import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/screens/disconnected_screen.dart';
import 'package:tone_gt_studio/ui/screens/stage_pedalboard_screen.dart';
import 'package:tone_gt_studio/ui/widgets/stage_header_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 8: Robustness & Auto-Reconnection Tests', () {
    late MidiService midi;
    late PatchService patchService;

    setUp(() async {
      midi = MidiService();
      patchService = PatchService(midi);
      patchService.autoSyncOnConnect = false;
      await midi.connect();
    });

    tearDown(() {
      midi.cancelAutoReconnect();
      midi.dispose();
      patchService.dispose();
    });

    test('MidiService handles unexpected disconnection with auto-reconnection state', () async {
      expect(midi.isConnected, isTrue);
      expect(midi.connectionState, equals(MidiConnectionState.connected));

      // Simulate cable unplug / hardware connection drop
      midi.handleUnexpectedDisconnection();

      expect(midi.isConnected, isFalse);
      expect(midi.isAutoReconnecting, isTrue);
      expect(midi.connectionState, equals(MidiConnectionState.reconnecting));

      // Cancel auto-reconnect stops the retry loop
      midi.cancelAutoReconnect();
      expect(midi.isAutoReconnecting, isFalse);
      expect(midi.connectionState, equals(MidiConnectionState.disconnected));
    });

    test('MidiService manual disconnect does not trigger auto-reconnect', () async {
      expect(midi.isConnected, isTrue);

      await midi.disconnect();

      expect(midi.isConnected, isFalse);
      expect(midi.isAutoReconnecting, isFalse);
      expect(midi.connectionState, equals(MidiConnectionState.disconnected));
    });

    test('MidiService reconnect re-activates Roland Editor Mode (7F 00 00 01 01)', () async {
      midi.handleUnexpectedDisconnection();
      expect(midi.isAutoReconnecting, isTrue);

      final packetsSent = <Uint8List>[];
      final sub = midi.onSysExReceived.listen((p) => packetsSent.add(p));

      final success = await midi.reconnect();
      expect(success, isTrue);
      expect(midi.isConnected, isTrue);
      expect(midi.connectionState, equals(MidiConnectionState.connected));

      await sub.cancel();
      midi.cancelAutoReconnect();
    });

    test('PatchService cancelSync stops bulk preset reading gracefully', () async {
      expect(patchService.isSyncing, isFalse);

      // Start bulk sync in background
      final syncFuture = patchService.syncAllPatchesFromPedal();
      expect(patchService.isSyncing, isTrue);

      // Request immediate cancellation
      patchService.cancelSync();
      await syncFuture;

      expect(patchService.isSyncing, isFalse);
      expect(patchService.syncStatusText, contains('cancelada'));
    });

    testWidgets('StagePedalboardScreen renders Reconnecting Bar when connection is lost', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      midi.handleUnexpectedDisconnection();

      await tester.pumpWidget(
        MaterialApp(
          home: StagePedalboardScreen(
            midi: midi,
            patchService: patchService,
            isDemoMode: false,
            onExitDemo: () {},
            onConnectRequest: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Conexión perdida con Boss GT-1B'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);

      // Tap cancel button in reconnection bar
      await tester.tap(find.text('CANCELAR'));
      await tester.pump();

      expect(midi.connectionState, equals(MidiConnectionState.disconnected));
      midi.cancelAutoReconnect();
    });

    testWidgets('StageHeaderBar displays RECONECTANDO status when reconnecting', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      midi.handleUnexpectedDisconnection();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: StageHeaderBar(
              midi: midi,
              patchService: patchService,
              isDemoMode: false,
              onExitDemo: () {},
              onConnectRequest: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('RECONECTANDO...'), findsOneWidget);
      midi.cancelAutoReconnect();
    });

    testWidgets('DisconnectedScreen renders warning badge and reconnection buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DisconnectedScreen(
            midi: midi,
            onEnterDemoMode: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DisconnectedScreen), findsOneWidget);
      expect(find.text('Pedalera Desconectada'), findsOneWidget);
      expect(find.textContaining('Se ha perdido la comunicación'), findsOneWidget);
      expect(find.text('VOLVER A CONECTAR (USB OTG)'), findsOneWidget);
      expect(find.text('VOLVER A CONECTAR (BLUETOOTH)'), findsOneWidget);
      expect(find.text('Continuar en Modo Demo (Sin pedalera)'), findsOneWidget);
    });
  });
}
