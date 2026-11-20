import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/protocol/gt_sysex.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/screens/home_pedalboard_screen.dart';
import 'package:tone_gt_studio/ui/screens/stage_pedalboard_screen.dart';
import 'package:tone_gt_studio/ui/screens/sync_loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preset FX Chain SysEx & Address Tests', () {
    test('buildPatchFxChainRequest generates valid RQ1 for user and factory presets', () {
      // User patch U05 (index 4) -> address 10 04 07 20, size 00 00 00 14 (20 bytes)
      final uReq = GtSysEx.buildPatchFxChainRequest(4, isFactoryPreset: false);
      expect(uReq[0], equals(0xF0));
      expect(uReq[1], equals(0x41));
      expect(uReq[7], equals(GtSysEx.commandRq1)); // 0x11
      expect(uReq[8], equals(0x10)); // User bank
      expect(uReq[9], equals(0x04)); // Patch index 4 (U05)
      expect(uReq[10], equals(0x07));
      expect(uReq[11], equals(0x20)); // FX Chain offset
      expect(uReq[15], equals(0x14)); // Size 20 bytes
      expect(uReq.last, equals(0xF7));

      // Factory preset P10 (index 9) -> address 20 09 07 20
      final pReq = GtSysEx.buildPatchFxChainRequest(9, isFactoryPreset: true);
      expect(pReq[8], equals(0x20)); // Factory bank
      expect(pReq[9], equals(0x09));
      expect(pReq[10], equals(0x07));
      expect(pReq[11], equals(0x20));
    });

    test('parseFxChainOrder parses user patch, factory preset, and active buffer replies', () {
      final chainData = [0, 1, 4, 8, 10, 14, 17, 6, 5, 2, 13, 15, 12, 11, 7, 9, 18, 3, 19, 16];

      // Simulated user patch packet (10 02 07 20)
      final userPacket = GtSysEx.buildDt1Message(
        address: [0x10, 0x02, 0x07, 0x20],
        data: chainData,
      );
      final userChain = GtSysEx.parseFxChainOrder(userPacket);
      expect(userChain, equals(chainData));
      expect(GtSysEx.parseFxChainPatchIndex(userPacket), equals(2)); // U03

      // Simulated factory preset packet (20 05 07 20)
      final factoryPacket = GtSysEx.buildDt1Message(
        address: [0x20, 0x05, 0x07, 0x20],
        data: chainData,
      );
      final factoryChain = GtSysEx.parseFxChainOrder(factoryPacket);
      expect(factoryChain, equals(chainData));
      expect(GtSysEx.parseFxChainPatchIndex(factoryPacket), equals(99 + 5)); // P06

      // Simulated active temporary packet (60 00 07 20)
      final activePacket = GtSysEx.buildDt1Message(
        address: [0x60, 0x00, 0x07, 0x20],
        data: chainData,
      );
      final activeChain = GtSysEx.parseFxChainOrder(activePacket);
      expect(activeChain, equals(chainData));
      expect(GtSysEx.parseFxChainPatchIndex(activePacket), isNull);
    });

    test('Incoming preset FX chain SysEx correctly reorders target preset effects', () async {
      final midi = MidiService();
      final patchService = PatchService(midi);
      patchService.autoSyncOnConnect = false;

      // In patch index 3 (U04), let's send a chain where DELAY (7) comes before PEDAL FX (11)
      // Custom movable chain: [7, 11, 15, 2, 5, 13, 12, 6, 9] (Delay first, then Pedal FX, OD, etc.)
      final customChain = [0, 1, 4, 8, 10, 14, 17, 7, 11, 15, 2, 5, 13, 12, 6, 9, 18, 3, 19, 16];
      final dt1 = GtSysEx.buildDt1Message(
        address: [0x10, 0x03, 0x07, 0x20],
        data: customChain,
      );

      midi.handleIncomingDataForTesting(dt1);
      await Future.delayed(Duration.zero);

      final patch3 = patchService.patches[3];
      // First effect in patch 3 must now be DELAY, not PEDAL FX!
      expect(patch3.effects.first.category, equals(EffectCategory.delay));
      expect(patch3.effects[1].category, equals(EffectCategory.pedalFx));

      patchService.dispose();
      midi.dispose();
    });
  });

  group('SyncLoadingScreen Widget & Navigation Gate Tests', () {
    late MidiService midi;
    late PatchService patchService;

    setUp(() {
      midi = MidiService();
      patchService = PatchService(midi);
      patchService.autoSyncOnConnect = false;
    });

    tearDown(() {
      patchService.dispose();
      midi.dispose();
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: midi),
          ChangeNotifierProvider.value(value: patchService),
        ],
        child: const MaterialApp(
          home: HomePedalboardScreen(),
        ),
      );
    }

    testWidgets('SyncLoadingScreen renders progress bar, percentage, status, and buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool demoEntered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SyncLoadingScreen(
            midi: midi,
            patchService: patchService,
            onEnterDemoMode: () => demoEntered = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sincronizando Pedalera'), findsOneWidget);
      expect(find.text('PROGRESO DE SINCRONIZACIÓN'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Omitir y abrir interfaz'), findsOneWidget);
      expect(find.text('Modo Demo'), findsOneWidget);

      await tester.tap(find.text('Modo Demo'));
      expect(demoEntered, isTrue);
    });

    testWidgets('HomePedalboardScreen gates interface with SyncLoadingScreen until sync completes', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Initially disconnected -> shows GatewayScreen
      expect(find.text('Boss GT-1B Bass Studio'), findsOneWidget);
      expect(find.byType(StagePedalboardScreen), findsNothing);
      expect(find.byType(SyncLoadingScreen), findsNothing);

      // Connect pedal via USB OTG
      midi.setConnectedForTesting(true, type: ConnectionType.usbOtg);
      await tester.pump();

      // Now connected, but isInitialSyncComplete is false -> SyncLoadingScreen MUST be displayed!
      expect(find.byType(SyncLoadingScreen), findsOneWidget);
      expect(find.text('Sincronizando Pedalera'), findsOneWidget);
      expect(find.byType(StagePedalboardScreen), findsNothing);

      // Once sync completes -> StagePedalboardScreen is unlocked!
      patchService.setInitialSyncComplete(true);
      await tester.pump();

      expect(find.byType(SyncLoadingScreen), findsNothing);
      expect(find.byType(StagePedalboardScreen), findsOneWidget);
    });

    testWidgets('Tapping Omitir y abrir interfaz in SyncLoadingScreen unlocks StagePedalboardScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      midi.setConnectedForTesting(true, type: ConnectionType.usbOtg);
      await tester.pump();

      expect(find.byType(SyncLoadingScreen), findsOneWidget);

      // User taps "Omitir y abrir interfaz"
      await tester.tap(find.text('Omitir y abrir interfaz'));
      await tester.pump();

      // UI is immediately unlocked!
      expect(find.byType(SyncLoadingScreen), findsNothing);
      expect(find.byType(StagePedalboardScreen), findsOneWidget);
    });
  });
}
