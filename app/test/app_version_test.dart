import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/core/app_version.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/services/storage/app_database.dart';
import 'package:tone_gt_studio/services/storage/storage_driver.dart';
import 'package:tone_gt_studio/services/theme_service.dart';
import 'package:tone_gt_studio/ui/screens/home_pedalboard_screen.dart';

void main() {
  group('AppVersion & Corner Badge Verification Tests', () {
    late MemoryStorageDriver memoryDriver;
    late AppDatabase db;
    late MidiService midi;
    late PatchService patchService;
    late ThemeService themeService;

    setUp(() async {
      memoryDriver = MemoryStorageDriver();
      db = AppDatabase(driver: memoryDriver);
      await db.init();
      midi = MidiService(database: db);
      patchService = PatchService(midi, database: db);
      patchService.autoSyncOnConnect = false;
      themeService = ThemeService(database: db);
    });

    tearDown(() {
      patchService.dispose();
      midi.dispose();
      themeService.dispose();
      db.dispose();
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppDatabase>.value(value: db),
          ChangeNotifierProvider<MidiService>.value(value: midi),
          ChangeNotifierProvider<PatchService>.value(value: patchService),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ],
        child: const MaterialApp(
          home: HomePedalboardScreen(),
        ),
      );
    }

    test('AppVersion constants define valid semantic version', () {
      expect(AppVersion.version, equals('1.0.2'));
      expect(AppVersion.buildNumber, equals(3));
      expect(AppVersion.label, equals('v1.0.2'));
    });

    testWidgets('HomePedalboardScreen displays version badge in corner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const Key('app-version-badge'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text(AppVersion.label), findsOneWidget);
    });
  });
}
