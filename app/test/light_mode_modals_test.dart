import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tone_gt_studio/core/transport/fake_transport.dart';
import 'package:tone_gt_studio/ui/layout/responsive_breakpoints.dart';
import 'package:tone_gt_studio/services/midi_service.dart';
import 'package:tone_gt_studio/services/patch_service.dart';
import 'package:tone_gt_studio/ui/theme/app_theme.dart';
import 'package:tone_gt_studio/ui/widgets/assign_editor_modal.dart';
import 'package:tone_gt_studio/ui/widgets/patch_list_modal.dart';
import 'package:tone_gt_studio/ui/widgets/patch_write_modal.dart';
import 'package:tone_gt_studio/ui/widgets/stage_right_panel.dart';
import 'package:tone_gt_studio/ui/widgets/system_settings_modal.dart';
import 'package:tone_gt_studio/ui/widgets/tuner_modal.dart';
import 'package:tone_gt_studio/ui/widgets/wah_expression_card.dart';

void main() {
  group('Light Mode Modals & Widgets Rendering Tests', () {
    late FakeTransport fakeTransport;
    late MidiService midiService;
    late PatchService patchService;

    setUp(() {
      fakeTransport = FakeTransport();
      midiService = MidiService();
      patchService = PatchService(midiService);
    });

    tearDown(() {
      patchService.dispose();
      midiService.dispose();
      fakeTransport.dispose();
    });

    Widget wrapWithTheme(Widget child, {bool lightMode = true}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MidiService>.value(value: midiService),
          ChangeNotifierProvider<PatchService>.value(value: patchService),
        ],
        child: MaterialApp(
          theme: lightMode ? AppTheme.lightTheme : AppTheme.darkTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('PatchWriteModal renders properly in light mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(PatchWriteModal(patchService: patchService)),
      );
      await tester.pump();

      expect(find.text('GUARDAR PRESET EN GT-1B'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
      expect(find.text('GUARDAR EN HARDWARE'), findsOneWidget);
    });

    testWidgets('AssignEditorModal renders all tabs in light mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(AssignEditorModal(patchService: patchService)),
      );
      await tester.pump();

      expect(find.text('CONFIGURACIÓN GT-1B (CTL / EXP / A1–A6 / I-O)'), findsOneWidget);
      expect(find.text('CTL & EXP'), findsOneWidget);
      expect(find.text('DOWN / UP & NIVELES'), findsOneWidget);
      expect(find.text('ASIGNACIONES (A1–A6)'), findsOneWidget);
    });

    testWidgets('SystemSettingsModal renders in light mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(SystemSettingsModal(patchService: patchService)),
      );
      await tester.pump();

      expect(find.text('SISTEMA Y UTILIDADES GT-1B'), findsOneWidget);
      expect(find.text('GLOBAL & SALIDA'), findsOneWidget);
      expect(find.text('METRÓNOMO'), findsOneWidget);
      expect(find.text('USB & HARDWARE'), findsOneWidget);
      expect(find.text('APARIENCIA'), findsOneWidget);
    });

    testWidgets('TunerModal renders with correct light theme styling', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(TunerModal(patchService: patchService, onClose: () {})),
      );
      await tester.pump();

      expect(find.text('AFINADOR CROMÁTICO EN VIVO'), findsOneWidget);
      expect(find.text('SALIR DEL AFINADOR (MODO PLAY)'), findsOneWidget);
    });

    testWidgets('PatchListModal renders in light mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(const PatchListModal()),
      );
      await tester.pump();

      expect(find.text('BIBLIOTECA DE PRESETS GT-1B (198 BANCOS)'), findsOneWidget);
      expect(find.text('USER (U01-U99)'), findsOneWidget);
      expect(find.text('FÁBRICA (P01-P99)'), findsOneWidget);
      expect(find.text('BACKUP & TSL'), findsOneWidget);
    });

    testWidgets('WahExpressionCard and StageRightPanel render in light mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: [
              WahExpressionCard(
                isWahActive: false,
                wahPosition: 50,
                onToggleWah: () {},
                onPositionChanged: (_) {},
              ),
              Expanded(
                child: StageRightPanel(
                  isWahActive: true,
                  wahPosition: 80,
                  footVolumeLevel: 75,
                  onToggleWah: () {},
                  onWahPositionChanged: (_) {},
                  breakpoint: StageBreakpoint.wide,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PEDAL EXP / FOOTSWITCH WAH'), findsOneWidget);
      expect(find.text('VOLUMEN (BYPASS)'), findsOneWidget);
      expect(find.text('EXP / VOLUMEN'), findsOneWidget);
      expect(find.text('FOOT VOL'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });
}
