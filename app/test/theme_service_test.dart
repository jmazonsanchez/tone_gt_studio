import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/models/effect_block.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/services/theme_service.dart';
import 'package:tone_gt_studio/ui/theme/app_theme.dart';
import 'package:tone_gt_studio/ui/widgets/chain_block_chip.dart';
import 'package:tone_gt_studio/ui/widgets/effect_editor_panel.dart';
import 'package:tone_gt_studio/ui/widgets/memory_edit_chain_bar.dart';
import 'package:tone_gt_studio/ui/widgets/mini_pedal_card.dart';
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

    testWidgets('Light Mode renders light colors in MemoryEditChainBar and MiniPedalCard', (tester) async {
      tester.view.physicalSize = const Size(1400, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final midi = MidiService();
      final patchService = PatchService(midi);
      final effects = patchService.currentPatch.effects;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  MemoryEditChainBar(
                    effects: effects,
                    onMoveEffect: (_, __) {},
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: effects.length,
                      itemBuilder: (ctx, i) => SizedBox(
                        width: 140,
                        child: MiniPedalCard(
                          effect: effects[i],
                          onToggle: () {},
                          onOpenDetail: () {},
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('MEMORY EDIT'), findsOneWidget);
      expect(find.text('INPUT'), findsOneWidget);
      expect(find.text('OUTPUT'), findsOneWidget);
      expect(find.byType(ChainBlockChip), findsWidgets);
      expect(find.byType(MiniPedalCard), findsWidgets);

      midi.dispose();
      patchService.dispose();
    });

    testWidgets('Light Mode renders EffectEditorPanel with light theme styling', (tester) async {
      final midi = MidiService();
      final patchService = PatchService(midi);
      final od = patchService.currentPatch.effects.firstWhere((e) => e.category == EffectCategory.odDs);

      await tester.pumpWidget(
        ChangeNotifierProvider<PatchService>.value(
          value: patchService,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: EffectEditorPanel(effect: od),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('OD/DS'), findsOneWidget);
      expect(find.text('TYPE:'), findsOneWidget);
      expect(find.text('DRIVE'), findsOneWidget);

      midi.dispose();
      patchService.dispose();
    });
  });
}
