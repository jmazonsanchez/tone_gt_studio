import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/services/theme_service.dart';
import 'package:tone_gt_studio/ui/theme/app_theme.dart';
import 'package:tone_gt_studio/ui/widgets/system_appearance_tab.dart';
import 'package:tone_gt_studio/ui/widgets/system_settings_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService & AppTheme Tests', () {
    test('Default mode is dark and maps to ThemeMode.dark', () {
      final service = ThemeService();
      expect(service.mode, equals(AppThemeMode.dark));
      expect(service.themeMode, equals(ThemeMode.dark));
      expect(service.isDarkMode, isTrue);
      expect(service.isLightMode, isFalse);
    });

    test('setThemeMode updates mode and notifies listeners', () {
      final service = ThemeService();
      var notified = false;
      service.addListener(() => notified = true);

      service.setThemeMode(AppThemeMode.light);
      expect(service.mode, equals(AppThemeMode.light));
      expect(service.themeMode, equals(ThemeMode.light));
      expect(service.isLightMode, isTrue);
      expect(notified, isTrue);

      notified = false;
      service.setThemeMode(AppThemeMode.system);
      expect(service.mode, equals(AppThemeMode.system));
      expect(service.themeMode, equals(ThemeMode.system));
      expect(service.isSystemMode, isTrue);
      expect(notified, isTrue);
    });

    test('toggleTheme alternates between dark and light', () {
      final service = ThemeService();
      expect(service.isDarkMode, isTrue);

      service.toggleTheme();
      expect(service.isLightMode, isTrue);

      service.toggleTheme();
      expect(service.isDarkMode, isTrue);
    });

    testWidgets('AppTheme.of resolves dark and light palettes according to Theme.brightness', (tester) async {
      late AppColorScheme darkResolved;
      late AppColorScheme lightResolved;

      await tester.pumpWidget(
        Theme(
          data: AppTheme.darkTheme,
          child: Builder(
            builder: (ctx) {
              darkResolved = AppTheme.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(darkResolved.isDark, isTrue);
      expect(darkResolved.background, equals(const Color(0xFF0F0F14)));

      await tester.pumpWidget(
        Theme(
          data: AppTheme.lightTheme,
          child: Builder(
            builder: (ctx) {
              lightResolved = AppTheme.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(lightResolved.isDark, isFalse);
      expect(lightResolved.background, equals(const Color(0xFFF1F3F6)));
    });

    testWidgets('SystemAppearanceTab renders mode options and switches theme on tap', (tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SystemAppearanceTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TEMA VISUAL DE TONESTUDIO'), findsOneWidget);
      expect(find.text('MODO OSCURO (DARK STUDIO)'), findsOneWidget);
      expect(find.text('MODO CLARO (LIGHT STUDIO)'), findsOneWidget);
      expect(find.text('AUTOMÁTICO (SISTEMA)'), findsOneWidget);

      // Tap on Light Studio mode
      await tester.tap(find.text('MODO CLARO (LIGHT STUDIO)'));
      await tester.pump();

      expect(themeService.isLightMode, isTrue);
      expect(themeService.mode, equals(AppThemeMode.light));

      // Tap on Automatic (System) mode
      await tester.tap(find.text('AUTOMÁTICO (SISTEMA)'));
      await tester.pump();

      expect(themeService.isSystemMode, isTrue);
      expect(themeService.mode, equals(AppThemeMode.system));
    });

    testWidgets('SystemSettingsModal displays 4 tabs including APARIENCIA', (tester) async {
      final midi = MidiService();
      final patchService = PatchService(midi);
      final themeService = ThemeService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MidiService>.value(value: midi),
            ChangeNotifierProvider<PatchService>.value(value: patchService),
            ChangeNotifierProvider<ThemeService>.value(value: themeService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
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

      // Tap on APARIENCIA tab
      await tester.tap(find.text('APARIENCIA'));
      await tester.pumpAndSettle();

      expect(find.text('TEMA VISUAL DE TONESTUDIO'), findsOneWidget);
      expect(find.text('MODO OSCURO (DARK STUDIO)'), findsOneWidget);
      expect(find.text('MODO CLARO (LIGHT STUDIO)'), findsOneWidget);

      midi.dispose();
      patchService.dispose();
      themeService.dispose();
    });
  });
}
