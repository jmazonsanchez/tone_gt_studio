import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/models/device_config.dart';
import 'package:tone_gt_studio/models/quick_preset.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/services/storage/app_database.dart';
import 'package:tone_gt_studio/services/storage/storage_driver.dart';
import 'package:tone_gt_studio/services/theme_service.dart';
import 'package:tone_gt_studio/ui/widgets/system_database_tab.dart';
import 'package:tone_gt_studio/ui/widgets/system_settings_modal.dart';

void main() {
  group('DeviceConfig Model & Serialization Tests', () {
    test('DeviceConfig defaultGt1b contains authentic GT-1B settings and starts with empty live presets', () {
      final config = DeviceConfig.defaultGt1b();
      expect(config.deviceId, equals('boss_gt1b'));
      expect(config.deviceName, contains('Boss GT-1B'));
      expect(config.autoReconnect, isTrue);
      expect(config.lastConnectionType, equals('usbOtg'));
      expect(config.quickPresets.isEmpty, isTrue);
    });

    test('DeviceConfig JSON roundtrip preserves all device attributes', () {
      final original = DeviceConfig(
        deviceId: 'gt1b_custom',
        deviceName: 'Mi Boss GT-1B Pro',
        lastConnectionType: 'bluetoothBle',
        autoReconnect: false,
        lastPatchIndex: 12,
        quickPresets: const [
          QuickPreset(id: 'custom_1', patchIndex: 12, customLabel: 'SOLO DISTORTION', colorValue: 0xFFFF0000),
        ],
        metronomeBpm: 140,
        metronomeTimeSignature: 3,
        metronomeVisualOnly: true,
        phraseLoopTimerSeconds: 4,
        phraseLoopMode: 'mono',
        customNickname: 'Pedal Principal',
        updatedAt: DateTime(2026, 11, 20),
      );

      final json = original.toJson();
      final restored = DeviceConfig.fromJson(json);

      expect(restored.deviceId, equals(original.deviceId));
      expect(restored.deviceName, equals(original.deviceName));
      expect(restored.lastConnectionType, equals('bluetoothBle'));
      expect(restored.autoReconnect, isFalse);
      expect(restored.lastPatchIndex, equals(12));
      expect(restored.quickPresets.length, equals(1));
      expect(restored.quickPresets.first.customLabel, equals('SOLO DISTORTION'));
      expect(restored.metronomeBpm, equals(140));
      expect(restored.phraseLoopTimerSeconds, equals(4));
    });
  });

  group('AppDatabase Internal Database Tests', () {
    late MemoryStorageDriver memoryDriver;
    late AppDatabase db;

    setUp(() async {
      memoryDriver = MemoryStorageDriver();
      db = AppDatabase(driver: memoryDriver);
      await db.init();
    });

    test('Database init seeds default Boss GT-1B configuration automatically', () {
      expect(db.isInitialized, isTrue);
      final gt1bConfig = db.getDeviceConfig('boss_gt1b');
      expect(gt1bConfig.deviceId, equals('boss_gt1b'));
      expect(gt1bConfig.quickPresets, isEmpty);
      expect(db.getThemeMode(), equals('dark'));
      expect(db.getActiveDeviceId(), equals('boss_gt1b'));
    });

    test('Multi-device configurations remain segregated in database', () async {
      // Configure GT-1B
      final gt1b = db.getDeviceConfig('boss_gt1b').copyWith(
        lastPatchIndex: 5,
        lastConnectionType: 'usbOtg',
      );
      await db.saveDeviceConfig(gt1b);

      // Configure a second device profile
      final otherDevice = DeviceConfig(
        deviceId: 'boss_gt1000',
        deviceName: 'Boss GT-1000',
        lastConnectionType: 'bluetoothBle',
        lastPatchIndex: 42,
        updatedAt: DateTime.now(),
      );
      await db.saveDeviceConfig(otherDevice);

      final loadedGt1b = db.getDeviceConfig('boss_gt1b');
      final loadedOther = db.getDeviceConfig('boss_gt1000');

      expect(loadedGt1b.lastPatchIndex, equals(5));
      expect(loadedGt1b.lastConnectionType, equals('usbOtg'));
      expect(loadedOther.lastPatchIndex, equals(42));
      expect(loadedOther.lastConnectionType, equals('bluetoothBle'));

      final all = db.getAllDeviceConfigs();
      expect(all.length, equals(2));
    });

    test('Live Quick Presets persist, update, and recall cleanly per device', () async {
      final customPresets = [
        const QuickPreset(id: 'live_1', patchIndex: 0, customLabel: 'INTRO FUNK', colorValue: 0xFF00ADB5),
        const QuickPreset(id: 'live_2', patchIndex: 4, customLabel: 'SOLO WAH', colorValue: 0xFFFF5722),
      ];

      await db.saveQuickPresets(customPresets, 'boss_gt1b');

      final loaded = db.getQuickPresets('boss_gt1b');
      expect(loaded.length, equals(2));
      expect(loaded[0].customLabel, equals('INTRO FUNK'));
      expect(loaded[1].customLabel, equals('SOLO WAH'));
    });

    test('Theme Mode persists and recovers from database', () async {
      expect(db.getThemeMode(), equals('dark'));

      await db.saveThemeMode('light');
      expect(db.getThemeMode(), equals('light'));

      await db.saveThemeMode('system');
      expect(db.getThemeMode(), equals('system'));
    });

    test('Resetting device configuration restores authentic GT-1B factory defaults', () async {
      // Modify GT-1B
      final modified = db.getDeviceConfig('boss_gt1b').copyWith(
        lastPatchIndex: 88,
        quickPresets: [],
      );
      await db.saveDeviceConfig(modified);
      expect(db.getDeviceConfig('boss_gt1b').lastPatchIndex, equals(88));
      expect(db.getQuickPresets('boss_gt1b'), isEmpty);

      // Reset
      await db.resetDeviceConfig('boss_gt1b');
      final restored = db.getDeviceConfig('boss_gt1b');
      expect(restored.lastPatchIndex, equals(0));
      expect(restored.quickPresets, isEmpty);
    });
  });

  group('Service & Persistence Integration Tests', () {
    late MemoryStorageDriver memoryDriver;
    late AppDatabase db;
    late ThemeService themeService;
    late MidiService midiService;
    late PatchService patchService;

    setUp(() async {
      memoryDriver = MemoryStorageDriver();
      db = AppDatabase(driver: memoryDriver);
      await db.init();

      themeService = ThemeService(database: db);
      midiService = MidiService(database: db);
      patchService = PatchService(midiService, database: db);
      patchService.autoSyncOnConnect = false;
    });

    tearDown(() {
      patchService.dispose();
      midiService.dispose();
      themeService.dispose();
      db.dispose();
    });

    test('ThemeService automatically persists theme changes to AppDatabase', () {
      expect(themeService.mode, equals(AppThemeMode.dark));

      themeService.setThemeMode(AppThemeMode.light);
      expect(db.getThemeMode(), equals('light'));

      // New ThemeService instance loads persisted theme
      final freshThemeService = ThemeService(database: db);
      expect(freshThemeService.mode, equals(AppThemeMode.light));
      freshThemeService.dispose();
    });

    test('PatchService quick presets automatically sync with AppDatabase', () {
      // Initial presets loaded from DB starts empty
      expect(patchService.quickPresets.length, equals(0));

      // Add a live shortcut
      patchService.addQuickPreset(patchIndex: 7, customLabel: 'EN VIVO SLAP', colorValue: 0xFF4CAF50);
      expect(patchService.quickPresets.length, equals(1));
      expect(db.getQuickPresets('boss_gt1b').length, equals(1));

      // Remove a shortcut
      final firstId = patchService.quickPresets.first.id;
      patchService.removeQuickPreset(firstId);
      expect(patchService.quickPresets.length, equals(0));
      expect(db.getQuickPresets('boss_gt1b').length, equals(0));
    });
  });

  group('SystemDatabaseTab UI Widget Tests', () {
    late MemoryStorageDriver memoryDriver;
    late AppDatabase db;
    late ThemeService themeService;
    late MidiService midiService;
    late PatchService patchService;

    setUp(() async {
      memoryDriver = MemoryStorageDriver();
      db = AppDatabase(driver: memoryDriver);
      await db.init();

      themeService = ThemeService(database: db);
      midiService = MidiService(database: db);
      patchService = PatchService(midiService, database: db);
      patchService.autoSyncOnConnect = false;
    });

    tearDown(() {
      patchService.dispose();
      midiService.dispose();
      themeService.dispose();
      db.dispose();
    });

    testWidgets('SystemDatabaseTab renders internal database card, device profile and live shortcuts', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppDatabase>.value(value: db),
            ChangeNotifierProvider<ThemeService>.value(value: themeService),
            ChangeNotifierProvider<PatchService>.value(value: patchService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SystemDatabaseTab(patchService: patchService),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BASE DE DATOS INTERNA'), findsOneWidget);
      expect(find.text('ACTIVA Y PERSISTENTE'), findsOneWidget);
      expect(find.textContaining('PERFIL GUARDADO'), findsOneWidget);
      expect(find.textContaining('ACCESOS DIRECTOS EN VIVO'), findsOneWidget);
      expect(find.text('RESTABLECER DISPOSITIVO'), findsOneWidget);
    });

    testWidgets('SystemSettingsModal opens and includes BASE & PERFILES 5th tab', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppDatabase>.value(value: db),
            ChangeNotifierProvider<ThemeService>.value(value: themeService),
            ChangeNotifierProvider<PatchService>.value(value: patchService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SystemSettingsModal(patchService: patchService),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GLOBAL & SALIDA'), findsOneWidget);
      expect(find.text('METRÓNOMO'), findsOneWidget);
      expect(find.text('USB & HARDWARE'), findsOneWidget);
      expect(find.text('APARIENCIA'), findsOneWidget);
      expect(find.text('BASE & PERFILES'), findsOneWidget);

      // Tap on the 5th tab
      await tester.tap(find.text('BASE & PERFILES'));
      await tester.pumpAndSettle();

      expect(find.text('BASE DE DATOS INTERNA'), findsOneWidget);
      expect(find.text('ACTIVA Y PERSISTENTE'), findsOneWidget);
    });
  });
}
