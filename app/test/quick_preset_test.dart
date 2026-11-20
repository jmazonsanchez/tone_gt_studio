import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/models/quick_preset.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/services/storage/app_database.dart';
import 'package:tone_gt_studio/ui/theme/app_theme.dart';
import 'package:tone_gt_studio/ui/widgets/quick_preset_bar.dart';

void main() {
  group('QuickPreset Model & Serialization Tests', () {
    test('QuickPreset instantiation, copyWith and JSON roundtrip', () {
      const qp = QuickPreset(
        id: 'qp_test',
        patchIndex: 5,
        customLabel: 'FUNK SOLO',
        colorValue: 0xFFFF9800,
      );

      expect(qp.id, equals('qp_test'));
      expect(qp.patchIndex, equals(5));
      expect(qp.customLabel, equals('FUNK SOLO'));
      expect(qp.colorValue, equals(0xFFFF9800));

      final modified = qp.copyWith(customLabel: 'SLAP INTRO', patchIndex: 12);
      expect(modified.id, equals('qp_test'));
      expect(modified.patchIndex, equals(12));
      expect(modified.customLabel, equals('SLAP INTRO'));
      expect(modified.colorValue, equals(0xFFFF9800));

      final json = qp.toJson();
      final fromJson = QuickPreset.fromJson(json);
      expect(fromJson.id, equals(qp.id));
      expect(fromJson.patchIndex, equals(qp.patchIndex));
      expect(fromJson.customLabel, equals(qp.customLabel));
      expect(fromJson.colorValue, equals(qp.colorValue));
    });
  });

  group('PatchService Quick Preset Management Tests', () {
    late MidiService midi;
    late PatchService patchService;

    setUp(() async {
      await AppDatabase.instance.resetDeviceConfig('boss_gt1b');
      midi = MidiService();
      patchService = PatchService(midi);
    });

    tearDown(() {
      patchService.dispose();
      midi.dispose();
    });

    test('Initial state starts empty with zero live shortcuts by default', () {
      expect(patchService.quickPresets.isEmpty, isTrue);
    });

    test('addQuickPreset appends new shortcut and notifies listeners', () {
      var notified = false;
      patchService.addListener(() => notified = true);

      final initialCount = patchService.quickPresets.length;
      patchService.addQuickPreset(
        patchIndex: 10,
        customLabel: 'BALADA CLEAN',
        colorValue: 0xFF4CAF50,
      );

      expect(patchService.quickPresets.length, equals(initialCount + 1));
      final added = patchService.quickPresets.last;
      expect(added.patchIndex, equals(10));
      expect(added.customLabel, equals('BALADA CLEAN'));
      expect(added.colorValue, equals(0xFF4CAF50));
      expect(notified, isTrue);
    });

    test('updateQuickPreset modifies existing shortcut', () {
      patchService.addQuickPreset(
        patchIndex: 2,
        customLabel: 'ORIGINAL PRESET',
        colorValue: 0xFF00ADB5,
      );
      final target = patchService.quickPresets.first;
      patchService.updateQuickPreset(
        target.id,
        patchIndex: 25,
        customLabel: 'SOLO MODIFIED',
        colorValue: 0xFFE53935,
      );

      final updated = patchService.quickPresets.firstWhere((p) => p.id == target.id);
      expect(updated.patchIndex, equals(25));
      expect(updated.customLabel, equals('SOLO MODIFIED'));
      expect(updated.colorValue, equals(0xFFE53935));
    });

    test('removeQuickPreset deletes shortcut from list', () {
      patchService.addQuickPreset(
        patchIndex: 1,
        customLabel: 'DELETE ME',
        colorValue: 0xFFE53935,
      );
      final initialCount = patchService.quickPresets.length;
      final target = patchService.quickPresets.first;

      patchService.removeQuickPreset(target.id);
      expect(patchService.quickPresets.length, equals(initialCount - 1));
      expect(patchService.quickPresets.any((p) => p.id == target.id), isFalse);
    });

    test('reorderQuickPresets rearranges shortcuts order', () {
      patchService.addQuickPreset(patchIndex: 0, customLabel: 'ONE', colorValue: 0xFF00ADB5);
      patchService.addQuickPreset(patchIndex: 1, customLabel: 'TWO', colorValue: 0xFFFF9800);

      final first = patchService.quickPresets[0];
      final second = patchService.quickPresets[1];

      patchService.reorderQuickPresets(0, 2);
      expect(patchService.quickPresets[0].id, equals(second.id));
      expect(patchService.quickPresets[1].id, equals(first.id));
    });
  });

  group('QuickPresetBar & QuickPresetEditorModal Widget Tests', () {
    late MidiService midi;
    late PatchService patchService;

    setUp(() async {
      await AppDatabase.instance.resetDeviceConfig('boss_gt1b');
      midi = MidiService();
      patchService = PatchService(midi);
    });

    tearDown(() {
      patchService.dispose();
      midi.dispose();
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: patchService,
            builder: (context, _) => QuickPresetBar(patchService: patchService),
          ),
        ),
      );
    }

    testWidgets('Renders QuickPresetBar in empty state when no shortcuts exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text('AGREGAR'), findsOneWidget);
      expect(find.textContaining('Sin accesos directos'), findsOneWidget);
    });

    testWidgets('Renders QuickPresetBar with preset chips when shortcuts exist', (tester) async {
      patchService.addQuickPreset(patchIndex: 0, customLabel: 'SLAP INTRO', colorValue: 0xFF00ADB5);
      patchService.addQuickPreset(patchIndex: 1, customLabel: 'DRIVE VERSO', colorValue: 0xFFFF9800);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text('AGREGAR'), findsOneWidget);
      expect(find.text('SLAP INTRO'), findsOneWidget);
      expect(find.text('DRIVE VERSO'), findsOneWidget);
    });

    testWidgets('Tapping a quick preset chip switches current patch', (tester) async {
      patchService.addQuickPreset(patchIndex: 0, customLabel: 'SLAP INTRO', colorValue: 0xFF00ADB5);
      patchService.addQuickPreset(patchIndex: 1, customLabel: 'DRIVE VERSO', colorValue: 0xFFFF9800);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(patchService.currentPatchIndex, equals(0));

      // Tap second chip (DRIVE VERSO pointing to patch index 1)
      await tester.tap(find.text('DRIVE VERSO'));
      await tester.pumpAndSettle();

      expect(patchService.currentPatchIndex, equals(1));
    });

    testWidgets('Tapping AGREGAR button opens QuickPresetEditorModal and creates new shortcut', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(patchService.quickPresets.isEmpty, isTrue);

      // Tap AGREGAR button
      await tester.tap(find.byKey(const Key('add-quick-preset-btn')));
      await tester.pumpAndSettle();

      expect(find.text('NUEVO ACCESO DIRECTO'), findsOneWidget);
      expect(find.text('PRESET ASOCIADO:'), findsOneWidget);

      // Enter label
      await tester.enterText(find.byType(TextField), 'NUEVO SLAP SHOW');
      await tester.pumpAndSettle();

      // Tap AGREGAR (save button)
      await tester.tap(find.byKey(const Key('save-quick-preset-btn')));
      await tester.pumpAndSettle();

      expect(find.text('NUEVO ACCESO DIRECTO'), findsNothing);
      expect(patchService.quickPresets.length, equals(1));
      expect(find.text('NUEVO SLAP SHOW'), findsOneWidget);
    });

    testWidgets('Editing existing shortcut allows modifying label or deleting it', (tester) async {
      patchService.addQuickPreset(patchIndex: 0, customLabel: 'SLAP INTRO', colorValue: 0xFF00ADB5);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(patchService.quickPresets.length, equals(1));

      // Tap tune/edit icon on chip
      final tuneIcons = find.byIcon(Icons.tune_rounded);
      expect(tuneIcons, findsWidgets);
      await tester.tap(tuneIcons.first);
      await tester.pumpAndSettle();

      expect(find.text('EDITAR ACCESO DIRECTO'), findsOneWidget);
      expect(find.byKey(const Key('delete-quick-preset-btn')), findsOneWidget);

      // Tap QUITAR to delete it
      await tester.tap(find.byKey(const Key('delete-quick-preset-btn')));
      await tester.pumpAndSettle();

      expect(find.text('EDITAR ACCESO DIRECTO'), findsNothing);
      expect(patchService.quickPresets.isEmpty, isTrue);
      expect(find.text('SLAP INTRO'), findsNothing);
    });
  });
}
